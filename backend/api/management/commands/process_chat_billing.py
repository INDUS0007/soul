"""
Management command to process billing for active chats.
Runs periodically to calculate and deduct billing for chats that are still active.
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from api.models import Chat, UserProfile
from api.utils.billing import calculate_and_deduct_chat_billing, calculate_chat_billing, deduct_chat_billing
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Process billing for active chats and deduct from wallet periodically'

    def add_arguments(self, parser):
        parser.add_argument(
            '--check-only',
            action='store_true',
            help='Only check and log billing amounts without deducting',
        )
        parser.add_argument(
            '--min-duration',
            type=int,
            default=1,
            help='Minimum chat duration in minutes before billing (default: 1)',
        )

    def handle(self, *args, **options):
        check_only = options['check_only']
        min_duration = options['min_duration']
        
        self.stdout.write("=" * 80)
        self.stdout.write("Processing billing for active chats...")
        self.stdout.write("=" * 80)
        
        # Get all active chats that have started
        active_chats = Chat.objects.filter(
            status=Chat.STATUS_ACTIVE,
            started_at__isnull=False
        ).select_related('user', 'counsellor')
        
        total_chats = active_chats.count()
        self.stdout.write(f"Found {total_chats} active chats to process")
        
        processed_count = 0
        total_billing = Decimal('0.00')
        
        for chat in active_chats:
            try:
                # Calculate current duration and billing
                from api.utils.billing import calculate_chat_duration_minutes, calculate_chat_billing
                
                duration_minutes = calculate_chat_duration_minutes(chat)
                
                # Skip if duration is less than minimum
                if duration_minutes < min_duration:
                    continue
                
                # Calculate billing amount (this is what should be charged so far)
                current_billing = calculate_chat_billing(chat)
                
                # Calculate what's already been billed
                already_billed = chat.billed_amount or Decimal('0.00')
                
                # Calculate how much should be deducted now (incremental)
                amount_to_deduct = current_billing - already_billed
                
                if amount_to_deduct > 0:
                    self.stdout.write(
                        f"\nChat {chat.id} (User: {chat.user.username}): "
                        f"Duration: {duration_minutes} min, "
                        f"Current billing: ₹{current_billing}, "
                        f"Already billed: ₹{already_billed}, "
                        f"Amount to deduct: ₹{amount_to_deduct}"
                    )
                    
                    if not check_only:
                        # Check wallet balance
                        try:
                            profile = UserProfile.objects.get(user=chat.user)
                            old_balance = profile.wallet_minutes
                            
                            if profile.wallet_minutes >= int(amount_to_deduct):
                                # Deduct the incremental amount
                                profile.wallet_minutes -= int(amount_to_deduct)
                                profile.save(update_fields=['wallet_minutes'])
                                
                                # Update chat billing fields (but don't mark as billed yet)
                                chat.billed_amount = current_billing
                                chat.duration_minutes = duration_minutes
                                chat.save(update_fields=['billed_amount', 'duration_minutes'])
                                
                                self.stdout.write(
                                    self.style.SUCCESS(
                                        f"  ✅ Deducted ₹{amount_to_deduct}: "
                                        f"Balance {old_balance} → {profile.wallet_minutes}"
                                    )
                                )
                                processed_count += 1
                                total_billing += amount_to_deduct
                            else:
                                self.stdout.write(
                                    self.style.WARNING(
                                        f"  ⚠️ Insufficient balance: "
                                        f"Needs ₹{amount_to_deduct}, has ₹{old_balance}"
                                    )
                                )
                        except UserProfile.DoesNotExist:
                            self.stdout.write(
                                self.style.ERROR(
                                    f"  ❌ UserProfile not found for user {chat.user.username}"
                                )
                            )
                    else:
                        self.stdout.write(f"  [CHECK ONLY] Would deduct ₹{amount_to_deduct}")
                
            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(
                        f"Error processing chat {chat.id}: {e}"
                    )
                )
                logger.error(f"Error processing billing for chat {chat.id}: {e}", exc_info=True)
        
        self.stdout.write("\n" + "=" * 80)
        if check_only:
            self.stdout.write(f"Check complete: Found {processed_count} chats with pending billing")
        else:
            self.stdout.write(
                f"Processed {processed_count} chats, "
                f"Total billing: ₹{total_billing}"
            )
        self.stdout.write("=" * 80)

