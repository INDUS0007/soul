"""
Billing utilities for chat sessions.
Implements time-based billing: 1 rupee per minute of active chat time.
"""
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from datetime import timedelta
from ..models import Chat, UserProfile
import logging

logger = logging.getLogger(__name__)

# Billing rate: 1 rupee per minute
CHAT_RATE_PER_MINUTE = Decimal('1.00')


def calculate_chat_duration_minutes(chat: Chat) -> int:
    """
    Calculate the active duration of a chat in minutes.
    
    Args:
        chat: Chat instance with started_at and ended_at
        
    Returns:
        int: Duration in minutes (rounded up to nearest minute, minimum 1 minute)
    """
    if not chat.started_at:
        return 0
    
    # Use ended_at if available, otherwise use current time (for active chats)
    end_time = chat.ended_at if chat.ended_at else timezone.now()
    
    if end_time <= chat.started_at:
        return 0
    
    # Calculate total seconds
    duration_seconds = (end_time - chat.started_at).total_seconds()
    
    # Convert to minutes (round up to nearest minute for billing)
    from math import ceil
    duration_minutes = int(ceil(duration_seconds / 60))
    
    # Ensure minimum 1 minute billing for any chat that started and ended
    # This guarantees ₹1 is charged even for very short chats (< 1 minute)
    if duration_minutes == 0 and chat.ended_at and chat.started_at:
        duration_minutes = 1
    
    return duration_minutes


def calculate_chat_billing(chat: Chat) -> Decimal:
    """
    Calculate billing amount for a chat session.
    
    Args:
        chat: Chat instance
        
    Returns:
        Decimal: Billing amount in rupees (1 rupee per minute)
    """
    duration_minutes = calculate_chat_duration_minutes(chat)
    
    # Calculate billing: 1 rupee per minute
    billing_amount = Decimal(duration_minutes) * CHAT_RATE_PER_MINUTE
    
    return billing_amount


def deduct_chat_billing(chat: Chat, billing_amount: Decimal) -> bool:
    """
    Deduct billing amount from user's wallet.
    
    Args:
        chat: Chat instance
        billing_amount: Amount to deduct (in rupees)
        
    Returns:
        bool: True if deduction successful, False otherwise
    """
    try:
        if not chat.user:
            logger.error(f"Chat {chat.id} has no user assigned")
            return False
        
        # Convert billing_amount to int for wallet_minutes (which is an integer field)
        billing_amount_int = int(billing_amount)
        
        if billing_amount_int <= 0:
            logger.info(f"Billing amount is {billing_amount_int}, no deduction needed for chat {chat.id}")
            return True
        
        with transaction.atomic():
            # Get user profile with select_for_update to prevent race conditions
            try:
                profile = UserProfile.objects.select_for_update().get(user=chat.user)
            except UserProfile.DoesNotExist:
                # Create profile if it doesn't exist
                logger.warning(f"UserProfile not found for user {chat.user.username}, creating one")
                profile = UserProfile.objects.create(user=chat.user, wallet_minutes=0)
            
            old_balance = profile.wallet_minutes
            
            logger.info(
                f"Attempting to deduct billing for chat {chat.id}: "
                f"amount=₹{billing_amount_int}, current_balance=₹{old_balance}, user={chat.user.username}"
            )
            
            # Check if user has sufficient balance
            if profile.wallet_minutes < billing_amount_int:
                logger.warning(
                    f"❌ Insufficient wallet balance for chat {chat.id}: "
                    f"user has ₹{profile.wallet_minutes}, needs ₹{billing_amount_int}. "
                    f"User: {chat.user.username}"
                )
                return False
            
            # Deduct from wallet
            profile.wallet_minutes -= billing_amount_int
            profile.save(update_fields=['wallet_minutes'])
            
            # Verify the deduction was successful
            profile.refresh_from_db()
            
            logger.info(
                f"✅ Billing deducted successfully for chat {chat.id}: "
                f"amount=₹{billing_amount_int}, balance: ₹{old_balance} -> ₹{profile.wallet_minutes}, "
                f"user={chat.user.username}"
            )
            
            return True
            
    except Exception as e:
        logger.error(f"❌ Error deducting billing for chat {chat.id}: {e}", exc_info=True)
        return False


def calculate_and_deduct_chat_billing(chat: Chat) -> bool:
    """
    Calculate and deduct billing for a chat session.
    This is called automatically when a chat ends.
    
    Args:
        chat: Chat instance that has ended (must be saved first to have ended_at)
        
    Returns:
        bool: True if billing processed successfully, False otherwise
    """
    # Refresh from database to get latest state
    try:
        chat.refresh_from_db()
    except Chat.DoesNotExist:
        logger.error(f"Chat {chat.id} does not exist in database")
        return False
    
    # Skip if already billed
    if chat.is_billed:
        logger.debug(f"Chat {chat.id} already billed, skipping")
        return True
    
    # Skip if chat never started
    if not chat.started_at:
        logger.debug(f"Chat {chat.id} never started, no billing required")
        # Mark as billed with 0 amount to prevent retries
        Chat.objects.filter(id=chat.id).update(
            is_billed=True,
            billing_processed_at=timezone.now(),
            duration_minutes=0,
            billed_amount=Decimal('0.00')
        )
        return True
    
    # Ensure ended_at is set
    if not chat.ended_at:
        logger.warning(f"Chat {chat.id} ended but ended_at not set, using current time")
        chat.ended_at = timezone.now()
        # Use update to avoid recursion
        Chat.objects.filter(id=chat.id).update(ended_at=chat.ended_at)
        chat.refresh_from_db()
    
    # Calculate billing
    duration_minutes = calculate_chat_duration_minutes(chat)
    billing_amount = calculate_chat_billing(chat)
    
    logger.info(
        f"Calculating billing for chat {chat.id}: "
        f"duration_minutes={duration_minutes}, billing_amount=₹{billing_amount}, "
        f"started_at={chat.started_at}, ended_at={chat.ended_at}, user={chat.user.username if chat.user else None}"
    )
    
    # Deduct from wallet
    deduction_success = False
    if billing_amount > 0:
        deduction_success = deduct_chat_billing(chat, billing_amount)
        if not deduction_success:
            logger.error(
                f"❌ FAILED to deduct ₹{billing_amount} from wallet for chat {chat.id}. "
                f"User: {chat.user.username if chat.user else None}, "
                f"Insufficient balance or error occurred."
            )
    else:
        # No charge for 0 minutes
        deduction_success = True
        logger.info(f"Chat {chat.id} has 0 minutes duration, no billing required")
    
    # Update chat with billing information
    # Use update() to avoid triggering save() again (which would cause recursion)
    update_fields = {
        'duration_minutes': duration_minutes,
        'billed_amount': billing_amount,
    }
    
    if deduction_success or billing_amount == 0:
        update_fields['is_billed'] = True
        update_fields['billing_processed_at'] = timezone.now()
        
        Chat.objects.filter(id=chat.id).update(**update_fields)
        # Refresh chat object
        chat.refresh_from_db()
        
        logger.info(
            f"✅ Billing processed for chat {chat.id}: "
            f"duration={duration_minutes} minutes, amount=₹{billing_amount}, "
            f"deduction_success={deduction_success}"
        )
        return True
    else:
        # Log error - don't mark as billed if deduction failed
        logger.error(
            f"❌ Failed to deduct billing for chat {chat.id}: "
            f"amount=₹{billing_amount}, user wallet may be insufficient. "
            f"Billing will be retried on next save."
        )
        # Still save duration and billing amount for record keeping
        # Don't mark as billed so it can be retried
        Chat.objects.filter(id=chat.id).update(**update_fields)
        chat.refresh_from_db()
        return False


def get_chat_estimated_cost(chat: Chat) -> dict:
    """
    Get estimated billing cost for an active chat (based on current duration).
    
    Args:
        chat: Chat instance (active or completed)
        
    Returns:
        dict: {
            "duration_minutes": int,
            "estimated_amount": Decimal,
            "is_active": bool
        }
    """
    duration_minutes = calculate_chat_duration_minutes(chat)
    estimated_amount = calculate_chat_billing(chat)
    is_active = chat.status == Chat.STATUS_ACTIVE
    
    return {
        "duration_minutes": duration_minutes,
        "estimated_amount": float(estimated_amount),
        "is_active": is_active,
        "is_billed": chat.is_billed if hasattr(chat, 'is_billed') else False,
    }


def check_chat_wallet_balance(user) -> tuple[bool, str, int]:
    """
    Check if user has sufficient wallet balance to start a chat.
    
    Args:
        user: Django User instance
        
    Returns:
        tuple: (has_sufficient_balance: bool, message: str, current_balance: int)
    """
    try:
        profile, _ = UserProfile.objects.get_or_create(user=user)
        min_balance = 1  # Minimum 1 rupee (1 minute) to start chat
        
        if profile.wallet_minutes < min_balance:
            return (
                False,
                f"Insufficient wallet balance. Minimum ₹{min_balance} required to start chat. "
                f"Current balance: ₹{profile.wallet_minutes}",
                profile.wallet_minutes
            )
        
        return (True, "", profile.wallet_minutes)
        
    except Exception as e:
        logger.error(f"Error checking wallet balance for user {user.username}: {e}", exc_info=True)
        return (False, f"Error checking wallet balance: {str(e)}", 0)

