"""
Django models for the mental health counseling platform.

All models are designed to ensure data persistence, proper relationships,
and automatic timestamp management. Chat and message data is saved to
the database for history and counselor access.
"""
from django.contrib.auth.models import User
from django.db import models
from django.db.models import Q
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)


# ============================================================================
# USER PROFILE MODELS
# ============================================================================

class UserProfile(models.Model):
    """
    Extended user profile with preferences, wallet, and mood tracking.
    All data is saved to database for persistence.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="profile",
        help_text="Associated Django User"
    )
    full_name = models.CharField(max_length=120, blank=True, help_text="User's full name")
    nickname = models.CharField(max_length=80, blank=True, help_text="User's preferred nickname")
    phone = models.CharField(max_length=30, blank=True, help_text="Contact phone number")
    age = models.PositiveIntegerField(null=True, blank=True, help_text="User's age")
    gender = models.CharField(max_length=50, blank=True, help_text="User's gender")
    
    # Wallet system
    wallet_minutes = models.PositiveIntegerField(
        default=100,
        help_text="Available minutes in wallet for services"
    )
    
    # Mood tracking
    last_mood = models.PositiveSmallIntegerField(
        default=3,
        help_text="Last recorded mood value (1-5 scale)"
    )
    last_mood_updated = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When mood was last updated"
    )
    mood_updates_count = models.PositiveSmallIntegerField(
        default=0,
        help_text="Total number of mood updates"
    )
    mood_updates_date = models.DateField(
        null=True,
        blank=True,
        help_text="Date of last mood update"
    )
    
    # Preferences
    timezone = models.CharField(
        max_length=64,
        blank=True,
        help_text="User's timezone (e.g., 'Asia/Kolkata')"
    )
    notifications_enabled = models.BooleanField(
        default=True,
        help_text="Whether notifications are enabled"
    )
    prefers_dark_mode = models.BooleanField(
        default=False,
        help_text="Whether user prefers dark mode"
    )
    language = models.CharField(
        max_length=32,
        default="English",
        help_text="Preferred language"
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When profile was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When profile was last updated"
    )

    class Meta:
        indexes = [
            models.Index(fields=["user"]),
            models.Index(fields=["wallet_minutes"]),
        ]
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"

    def __str__(self) -> str:
        return f"{self.user.username} - Profile"
    
    def save(self, *args, **kwargs):
        """Ensure profile is always saved with timestamps."""
        super().save(*args, **kwargs)
        logger.debug(f"UserProfile saved: user={self.user_id}, wallet={self.wallet_minutes}")


class CounsellorProfile(models.Model):
    """
    Profile for counselors with specialization and availability.
    Used to identify counselors in Chat and UpcomingSession models.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="counsellorprofile",
        help_text="Associated Django User (must be a counselor)"
    )
    specialization = models.CharField(
        max_length=200,
        blank=True,
        help_text="Counselor's area of specialization"
    )
    experience_years = models.PositiveIntegerField(
        default=0,
        help_text="Years of experience"
    )
    languages = models.JSONField(
        default=list,
        blank=True,
        help_text="List of languages spoken"
    )
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=0.0,
        help_text="Average rating (0.00 to 5.00)"
    )
    is_available = models.BooleanField(
        default=True,
        help_text="Whether counselor is currently available"
    )
    bio = models.TextField(
        blank=True,
        help_text="Counselor's biography"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When profile was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When profile was last updated"
    )

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Counselor Profile"
        verbose_name_plural = "Counselor Profiles"

    def __str__(self) -> str:
        return f"{self.user.username} - Counselor"


class DoctorProfile(models.Model):
    """
    Profile for doctors with specialization and license information.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="doctorprofile",
        help_text="Associated Django User (must be a doctor)"
    )
    specialization = models.CharField(
        max_length=200,
        blank=True,
        help_text="Doctor's area of specialization"
    )
    experience_years = models.PositiveIntegerField(
        default=0,
        help_text="Years of experience"
    )
    license_number = models.CharField(
        max_length=100,
        blank=True,
        help_text="Medical license number"
    )
    languages = models.JSONField(
        default=list,
        blank=True,
        help_text="List of languages spoken"
    )
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=0.0,
        help_text="Average rating (0.00 to 5.00)"
    )
    is_available = models.BooleanField(
        default=True,
        help_text="Whether doctor is currently available"
    )
    bio = models.TextField(
        blank=True,
        help_text="Doctor's biography"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When profile was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When profile was last updated"
    )

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Doctor Profile"
        verbose_name_plural = "Doctor Profiles"

    def __str__(self) -> str:
        return f"{self.user.username} - Doctor"


# ============================================================================
# CHAT MODELS (PRIMARY FUNCTIONALITY)
# ============================================================================

class Chat(models.Model):
    """
    Chat model for conversations between users and counselors.
    
    All chat data is saved to database for persistence and history.
    Counselors can see all their assigned chats through the counsellor ForeignKey.
    
    Status Flow:
    - queued: User created chat, waiting for counselor
    - active: Counselor accepted or user sent message
    - inactive: User hasn't sent message in 5+ minutes (auto-set)
    - completed: Chat ended normally
    - cancelled: Chat was cancelled
    
    Timestamps:
    - created_at: When chat was created
    - started_at: When chat became active (auto-set)
    - ended_at: When chat ended (auto-set)
    - updated_at: Last update (auto-managed)
    """
    STATUS_QUEUED = "queued"
    STATUS_ACTIVE = "active"
    STATUS_INACTIVE = "inactive"  # User inactive for 5+ minutes
    STATUS_COMPLETED = "completed"
    STATUS_CANCELLED = "cancelled"
    
    STATUS_CHOICES = [
        (STATUS_QUEUED, "Queued"),
        (STATUS_ACTIVE, "Active"),
        (STATUS_INACTIVE, "Inactive"),  # User hasn't sent message in 5 minutes
        (STATUS_COMPLETED, "Completed"),
        (STATUS_CANCELLED, "Cancelled"),
    ]

    # Relationships
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="chats",
        help_text="User who initiated this chat"
    )
    
    counsellor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_chats",
        limit_choices_to={"counsellorprofile__isnull": False},
        help_text="Counselor assigned to this chat (null for queued chats)"
    )
    
    # Chat data
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default=STATUS_QUEUED,
        db_index=True,
        help_text="Current status of the chat"
    )
    
    initial_message = models.TextField(
        blank=True,
        help_text="Initial message from user when creating the chat"
    )
    
    # Timestamps (all auto-managed)
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text="When the chat was created"
    )
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        db_index=True,
        help_text="When the chat became active (counselor accepted or user sent message)"
    )
    ended_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the chat ended (completed or cancelled)"
    )
    last_user_activity = models.DateTimeField(
        null=True,
        blank=True,
        db_index=True,
        help_text="When the user last interacted with this chat (sending message or opening chat)"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        db_index=True,
        help_text="Last update timestamp"
    )
    
    # Billing fields (time-based: 1 rupee per minute)
    billed_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0.00,
        help_text="Total amount billed for this chat (in rupees)"
    )
    duration_minutes = models.PositiveIntegerField(
        default=0,
        help_text="Total active chat duration in minutes (for billing calculation)"
    )
    is_billed = models.BooleanField(
        default=False,
        db_index=True,
        help_text="Whether billing has been processed and wallet deducted"
    )
    billing_processed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When billing was processed"
    )

    class Meta:
        ordering = ("-created_at", "-id")
        indexes = [
            # User's chats (ordered by creation date)
            models.Index(fields=["user", "-created_at"]),
            # Counselor's chats (ordered by creation date)
            models.Index(fields=["counsellor", "-created_at"]),
            # Status queries
            models.Index(fields=["status", "-created_at"]),
            # Counselor status queries (for dashboard)
            models.Index(fields=["counsellor", "status"]),
            # Queued chats (counsellor is null, status is queued)
            models.Index(fields=["status", "counsellor"], name="chat_queued_idx"),
        ]
        verbose_name = "Chat"
        verbose_name_plural = "Chats"

    def __str__(self) -> str:
        """String representation of the chat."""
        counsellor_name = self.counsellor.username if self.counsellor else "Unassigned"
        return f"Chat {self.id}: {self.user.username} -> {counsellor_name} ({self.status})"
    
    def save(self, *args, **kwargs):
        """
        Ensure chat is always saved with proper timestamps and status tracking.
        This method ensures data persistence and proper state management.
        """
        # Store previous status to detect status changes
        if self.pk:
            try:
                old_instance = Chat.objects.get(pk=self.pk)
                old_status = old_instance.status
            except Chat.DoesNotExist:
                old_status = None
        else:
            old_status = None
        
        # Track which fields we modify so we can include them in update_fields if needed
        fields_to_update = set()
        
        # Auto-set started_at when chat becomes active
        if self.status == self.STATUS_ACTIVE and not self.started_at:
            self.started_at = timezone.now()
            fields_to_update.add('started_at')
            logger.info(f"Chat {self.id} started at {self.started_at}")

        # Auto-set ended_at when chat is inactive, completed, or cancelled
        ending_chat = False
        status_changed_to_ending = False
        
        # Detect if status changed to an ending status
        if self.status in [self.STATUS_INACTIVE, self.STATUS_COMPLETED, self.STATUS_CANCELLED]:
            if old_status != self.status:
                status_changed_to_ending = True
                logger.info(f"Chat {self.id} status changed to {self.status} (was {old_status})")
            
            if not self.ended_at:
                ending_chat = True
                # For inactive chats, set ended_at to 5 minutes after last_user_activity if available
                if self.status == self.STATUS_INACTIVE and self.last_user_activity:
                    from datetime import timedelta
                    self.ended_at = self.last_user_activity + timedelta(minutes=5)
                else:
                    # For completed/cancelled or no last_user_activity, set ended_at to now
                    self.ended_at = timezone.now()
                fields_to_update.add('ended_at')
                logger.info(f"Chat {self.id} ended at {self.ended_at} with status {self.status}")
            elif status_changed_to_ending:
                # Status changed but ended_at already set - still need to process billing
                ending_chat = True
                logger.info(f"Chat {self.id} status changed to {self.status}, ended_at already set: {self.ended_at}")

        # updated_at is auto-managed by Django (auto_now=True) so no need to set it here,
        # but keep the safe fallback if needed:
        if not getattr(self, "updated_at", None):
            self.updated_at = timezone.now()

        # If update_fields is specified, ensure we include any fields we modified
        if 'update_fields' in kwargs and kwargs['update_fields'] is not None:
            # Convert to list if it's a tuple
            update_fields_list = list(kwargs['update_fields']) if isinstance(kwargs['update_fields'], (list, tuple)) else [kwargs['update_fields']]
            # Add any fields we modified that aren't already in the list
            for field in fields_to_update:
                if field not in update_fields_list:
                    update_fields_list.append(field)
            kwargs['update_fields'] = update_fields_list

        # Persist
        super().save(*args, **kwargs)
        
        # Calculate and process billing when chat ends (after save to ensure we have ended_at)
        # Trigger billing if:
        # 1. Chat is ending AND not already billed AND has started_at AND has ended_at
        # 2. OR status changed to ending status (even if ended_at was already set)
        should_process_billing = False
        if ending_chat or status_changed_to_ending:
            should_process_billing = (
                not getattr(self, '_billing_processing', False) and
                not self.is_billed and
                self.started_at is not None and
                self.ended_at is not None
            )
        
        if should_process_billing:
            logger.info(
                f"Chat {self.id} ended - triggering billing: "
                f"status={self.status}, started_at={self.started_at}, ended_at={self.ended_at}, "
                f"user={self.user.username if self.user else None}, is_billed={self.is_billed}, "
                f"ending_chat={ending_chat}, status_changed={status_changed_to_ending}"
            )
            # Mark to prevent recursion
            self._billing_processing = True
            # Import here to avoid circular imports
            from .utils.billing import calculate_and_deduct_chat_billing
            try:
                # Refresh from DB to get latest state (including any fields that were just saved)
                self.refresh_from_db()
                
                # Double-check that started_at is set (it should have been saved above)
                if not self.started_at:
                    logger.warning(
                        f"Ã¢Å¡ Ã¯Â¸Â Chat {self.id} ended but started_at is None after refresh. "
                        f"This may prevent billing. Old status was {old_status}, new status is {self.status}."
                    )
                
                # Calculate billing and deduct from wallet
                success = calculate_and_deduct_chat_billing(self)
                if success:
                    logger.info(f"Ã¢Å“â€¦ Billing processed successfully for chat {self.id}")
                else:
                    logger.error(
                        f"Ã¢ÂÅ’ Billing processing failed for chat {self.id}. "
                        f"This may be due to insufficient wallet balance or an error during deduction."
                    )
            except Exception as e:
                logger.error(f"Ã¢ÂÅ’ Error processing billing for chat {self.id}: {e}", exc_info=True)
            finally:
                # Clear flag
                self._billing_processing = False
        elif (ending_chat or status_changed_to_ending) and self.is_billed:
            logger.debug(f"Chat {self.id} already billed, skipping billing calculation")
        elif ending_chat or status_changed_to_ending:
            logger.debug(
                f"Chat {self.id} ended but billing skipped: "
                f"is_billed={self.is_billed}, started_at={self.started_at}, ended_at={self.ended_at}"
            )

        logger.debug(
            f"Chat {self.id} saved: user={self.user_id}, counsellor={self.counsellor_id}, "
            f"status={self.status}, created_at={self.created_at}, updated_at={self.updated_at}"
        )
    
    @property
    def message_count(self) -> int:
        """Get the number of messages in this chat."""
        return self.messages.count()
    
    @property
    def current_duration_minutes(self) -> int:
        """Calculate current duration in minutes (for active chats)."""
        if not self.started_at:
            return 0
        
        # Use ended_at if available, otherwise current time
        end_time = self.ended_at if self.ended_at else timezone.now()
        
        if end_time <= self.started_at:
            return 0
        
        from math import ceil
        duration_seconds = (end_time - self.started_at).total_seconds()
        return int(ceil(duration_seconds / 60))
    
    @property
    def current_estimated_cost(self) -> float:
        """Calculate estimated cost for active chat or final cost for completed chat."""
        duration = self.duration_minutes if self.is_billed else self.current_duration_minutes
        return float(duration * 1.00)  # 1 rupee per minute
    
    @property
    def is_active(self) -> bool:
        """Check if chat is currently active."""
        return self.status == self.STATUS_ACTIVE
    
    @property
    def is_queued(self) -> bool:
        """Check if chat is queued (waiting for counselor)."""
        return self.status == self.STATUS_QUEUED and self.counsellor is None
    
    @property
    def is_inactive(self) -> bool:
        """Check if chat is inactive (user hasn't sent message in 5+ minutes)."""
        return self.status == self.STATUS_INACTIVE
    
    @property
    def is_completed(self) -> bool:
        """Check if chat is completed."""
        return self.status == self.STATUS_COMPLETED
    
    @property
    def is_cancelled(self) -> bool:
        """Check if chat is cancelled."""
        return self.status == self.STATUS_CANCELLED
    
    def assign_counsellor(self, counsellor: User) -> None:
        """
        Assign a counselor to this chat and activate it.
        This ensures the chat is properly saved to database.
        
        Args:
            counsellor: User instance with CounsellorProfile
            
        Raises:
            ValueError: If user is not a counselor
        """
        if not hasattr(counsellor, 'counsellorprofile'):
            raise ValueError(f"User {counsellor.username} is not a counselor")
        
        self.counsellor = counsellor
        self.status = self.STATUS_ACTIVE
        if not self.started_at:
            self.started_at = timezone.now()
        
        # Save to database
        self.save(update_fields=['counsellor', 'status', 'started_at', 'updated_at'])
        
        logger.info(
            f"Chat {self.id} assigned to counselor {counsellor.username} (ID: {counsellor.id})"
        )
    
    def complete(self) -> None:
        """Mark chat as completed and set ended_at timestamp."""
        self.status = self.STATUS_COMPLETED
        if not self.ended_at:
            self.ended_at = timezone.now()
        # Ensure started_at is set if not already set (for billing)
        if not self.started_at:
            self.started_at = self.created_at or timezone.now()
        
        self.save(update_fields=['status', 'ended_at', 'started_at', 'updated_at'])
        
        logger.info(f"Chat {self.id} completed at {self.ended_at}")
    
    def cancel(self) -> None:
        """Cancel the chat and set ended_at timestamp."""
        self.status = self.STATUS_CANCELLED
        if not self.ended_at:
            self.ended_at = timezone.now()
        # Ensure started_at is set if not already set (for billing)
        if not self.started_at:
            self.started_at = self.created_at or timezone.now()
        
        self.save(update_fields=['status', 'ended_at', 'started_at', 'updated_at'])
        
        logger.info(f"Chat {self.id} cancelled at {self.ended_at}")
    
    def reopen(self) -> None:
        """
        Reopen a completed, inactive, or cancelled chat to allow follow-up conversations.
        Clears ended_at timestamp and sets status to active.
        Updates last_user_activity to current time.
        """
        if self.status not in [self.STATUS_COMPLETED, self.STATUS_INACTIVE, self.STATUS_CANCELLED]:
            logger.warning(f"Chat {self.id} is already active (status: {self.status}), no need to reopen")
            return
        
        old_status = self.status
        self.status = self.STATUS_ACTIVE
        self.ended_at = None  # Clear ended_at since chat is active again
        self.last_user_activity = timezone.now()  # Update user activity
        # Ensure started_at is set when reopening (for billing)
        if not self.started_at:
            self.started_at = timezone.now()
        
        self.save(update_fields=['status', 'ended_at', 'started_at', 'last_user_activity', 'updated_at'])
        
        logger.info(f"Chat {self.id} reopened from {old_status} to active status")
    
    def mark_inactive(self) -> None:
        """
        Mark chat as inactive when user hasn't sent a message in 5+ minutes.
        Sets ended_at timestamp to when inactivity occurred.
        """
        if self.status != self.STATUS_ACTIVE:
            logger.warning(f"Chat {self.id} cannot be marked inactive (current status: {self.status})")
            return
        
        old_status = self.status
        self.status = self.STATUS_INACTIVE
        if not self.ended_at and self.last_user_activity:
            # Set ended_at to 5 minutes after last user activity
            from datetime import timedelta
            self.ended_at = self.last_user_activity + timedelta(minutes=5)
        
        self.save(update_fields=['status', 'ended_at', 'updated_at'])
        logger.info(f"Chat {self.id} marked as inactive (user inactive for 5+ minutes)")


class ChatMessage(models.Model):
    """
    Individual message within a chat conversation.
    
    All messages are saved to database for persistence and history.
    Messages support deduplication via client_message_id.
    
    Fields:
    - chat: ForeignKey to Chat (CASCADE delete)
    - sender: ForeignKey to User (CASCADE delete)
    - text: Message content
    - client_message_id: UUID from client for deduplication
    - created_at: When message was created (auto-set)
    - updated_at: Last update (auto-managed)
    """
    chat = models.ForeignKey(
        Chat,
        on_delete=models.CASCADE,
        related_name="messages",
        help_text="Chat this message belongs to"
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="sent_messages",
        help_text="User who sent this message"
    )
    text = models.TextField(
        help_text="Message content"
    )
    client_message_id = models.CharField(
        max_length=64,
        null=True,
        blank=True,
        db_index=True,
        help_text="Client-generated UUID for deduplication"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text="When message was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When message was last updated"
    )

    class Meta:
        ordering = ("created_at", "id")
        indexes = [
            # Messages ordered by time
            models.Index(fields=["chat", "created_at"]),
            # Sender's messages
            models.Index(fields=["sender", "-created_at"]),
            # Chat messages reverse order
            models.Index(fields=["chat", "-created_at"]),
            # Deduplication lookups
            models.Index(fields=["chat", "client_message_id"], name="chat_client_msg_idx"),
            models.Index(fields=["sender", "client_message_id"], name="sender_client_msg_idx"),
        ]
        constraints = [
            # Prevent duplicate messages from same sender with same client_message_id
            models.UniqueConstraint(
                fields=['sender', 'client_message_id'],
                condition=Q(client_message_id__isnull=False),
                name='unique_client_message_per_sender'
            ),
        ]
        verbose_name = "Chat Message"
        verbose_name_plural = "Chat Messages"

    def __str__(self) -> str:
        return f"{self.sender.username}: {self.text[:50]}"
    
    def save(self, *args, **kwargs):
        """
        Ensure message is always saved with timestamp.
        This method ensures data persistence.
        """
        if not self.created_at:
            self.created_at = timezone.now()
        
        super().save(*args, **kwargs)
        
        logger.debug(
            f"ChatMessage {self.id} saved: chat={self.chat_id}, sender={self.sender_id}, "
            f"text_length={len(self.text)}, created_at={self.created_at}"
        )


# ============================================================================
# SESSION MODELS
# ============================================================================

class UpcomingSession(models.Model):
    """
    Scheduled sessions between users and counselors.
    
    All session data is saved to database for persistence and history.
    Supports start/end tracking via notes field.
    """
    SESSION_TYPE_ONE_ON_ONE = "one_on_one"
    SESSION_TYPE_GROUP = "group"
    SESSION_TYPE_WORKSHOP = "workshop"
    SESSION_TYPE_WEBINAR = "webinar"
    
    SESSION_TYPE_CHOICES = [
        (SESSION_TYPE_ONE_ON_ONE, "One-on-One"),
        (SESSION_TYPE_GROUP, "Group"),
        (SESSION_TYPE_WORKSHOP, "Workshop"),
        (SESSION_TYPE_WEBINAR, "Webinar"),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="upcoming_sessions",
        help_text="User who scheduled this session"
    )
    counsellor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="counsellor_sessions",
        limit_choices_to={"counsellorprofile__isnull": False},
        help_text="Counselor assigned to this session"
    )
    title = models.CharField(
        max_length=180,
        help_text="Session title"
    )
    session_type = models.CharField(
        max_length=40,
        choices=SESSION_TYPE_CHOICES,
        help_text="Type of session"
    )
    start_time = models.DateTimeField(
        help_text="Scheduled start time"
    )
    counsellor_name = models.CharField(
        max_length=160,
        help_text="Name of the counselor"
    )
    notes = models.TextField(
        blank=True,
        help_text="Session notes (confidential notes for counselor)"
    )
    is_confirmed = models.BooleanField(
        default=True,
        help_text="Whether session is confirmed"
    )
    
    # Session execution tracking (actual start/end times)
    actual_start_time = models.DateTimeField(
        null=True,
        blank=True,
        db_index=True,
        help_text="When session actually started (not scheduled time)"
    )
    actual_end_time = models.DateTimeField(
        null=True,
        blank=True,
        db_index=True,
        help_text="When session actually ended"
    )
    session_status = models.CharField(
        max_length=20,
        choices=[
            ('scheduled', 'Scheduled'),
            ('in_progress', 'In Progress'),
            ('completed', 'Completed'),
            ('cancelled', 'Cancelled'),
            ('no_show', 'No Show'),
        ],
        default='scheduled',
        db_index=True,
        help_text="Current status of the session"
    )
    
    # Risk assessment and flags
    risk_level = models.CharField(
        max_length=20,
        choices=[
            ('none', 'None'),
            ('low', 'Low'),
            ('medium', 'Medium'),
            ('high', 'High'),
            ('critical', 'Critical'),
        ],
        default='none',
        help_text="Risk level assessment"
    )
    manual_flag = models.CharField(
        max_length=10,
        choices=[
            ('green', 'Green'),
            ('yellow', 'Yellow'),
            ('red', 'Red'),
        ],
        default='green',
        help_text="Manual flag set by counselor"
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When session was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When session was last updated"
    )
    
    @property
    def duration_seconds(self):
        """Calculate session duration in seconds."""
        if not self.actual_start_time:
            return 0
        end_time = self.actual_end_time or timezone.now()
        return int((end_time - self.actual_start_time).total_seconds())
    
    @property
    def duration_minutes(self):
        """Calculate session duration in minutes."""
        return self.duration_seconds // 60

    class Meta:
        ordering = ("start_time", "id")
        indexes = [
            models.Index(fields=["user", "start_time"]),
            models.Index(fields=["counsellor", "start_time"]),
            models.Index(fields=["start_time", "is_confirmed"]),
            models.Index(fields=["counsellor", "session_status"]),
            models.Index(fields=["session_status", "actual_start_time"]),
        ]
        verbose_name = "Upcoming Session"
        verbose_name_plural = "Upcoming Sessions"

    def __str__(self) -> str:
        return f"{self.user.username} -> {self.title} @ {self.start_time}"


class Call(models.Model):
    """
    Model for video/voice calls between users and counselors.
    
    All call data is saved to database for persistence and history.
    Supports duration tracking and status management.
    """
    CALL_TYPE_VIDEO = "video"
    CALL_TYPE_VOICE = "voice"
    
    CALL_TYPE_CHOICES = [
        (CALL_TYPE_VIDEO, "Video Call"),
        (CALL_TYPE_VOICE, "Voice Call"),
    ]
    
    STATUS_SCHEDULED = "scheduled"
    STATUS_RINGING = "ringing"
    STATUS_ACTIVE = "active"
    STATUS_ENDED = "ended"
    STATUS_MISSED = "missed"
    STATUS_CANCELLED = "cancelled"
    
    STATUS_CHOICES = [
        (STATUS_SCHEDULED, "Scheduled"),
        (STATUS_RINGING, "Ringing"),
        (STATUS_ACTIVE, "Active"),
        (STATUS_ENDED, "Ended"),
        (STATUS_MISSED, "Missed"),
        (STATUS_CANCELLED, "Cancelled"),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="user_calls",
        help_text="User who initiated the call"
    )
    counsellor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="counsellor_calls",
        limit_choices_to={"counsellorprofile__isnull": False},
        help_text="Counselor for this call"
    )
    call_type = models.CharField(
        max_length=20,
        choices=CALL_TYPE_CHOICES,
        default=CALL_TYPE_VIDEO,
        help_text="Type of call (video or voice)"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default=STATUS_SCHEDULED,
        help_text="Current status of the call"
    )
    scheduled_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When call is scheduled"
    )
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When call started"
    )
    ended_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When call ended"
    )
    duration_seconds = models.PositiveIntegerField(
        default=0,
        help_text="Call duration in seconds"
    )
    notes = models.TextField(
        blank=True,
        help_text="Post-call notes or summary"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When call was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When call was last updated"
    )

    class Meta:
        ordering = ("-created_at", "-id")
        indexes = [
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["counsellor", "-created_at"]),
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["counsellor", "status"]),
            models.Index(fields=["scheduled_at", "status"]),
        ]
        verbose_name = "Call"
        verbose_name_plural = "Calls"

    def __str__(self) -> str:
        return f"{self.user.username} -> {self.get_call_type_display()} ({self.status})"
    
    def save(self, *args, **kwargs):
        """
        Ensure call is always saved with proper timestamps and duration.
        Auto-calculates duration when call ends.
        """
        # Auto-set started_at when call becomes active
        if self.status == self.STATUS_ACTIVE and not self.started_at:
            self.started_at = timezone.now()
        
        # Auto-set ended_at and calculate duration when call ends
        if self.status == self.STATUS_ENDED and self.started_at and not self.ended_at:
            self.ended_at = timezone.now()
            # Calculate duration
            if self.started_at:
                delta = self.ended_at - self.started_at
                self.duration_seconds = int(delta.total_seconds())
        
        super().save(*args, **kwargs)
    
    @property
    def duration_formatted(self) -> str:
        """Return formatted duration string (e.g., '5m 30s')."""
        if self.duration_seconds == 0:
            return "0s"
        minutes = self.duration_seconds // 60
        seconds = self.duration_seconds % 60
        if minutes > 0:
            return f"{minutes}m {seconds}s"
        return f"{seconds}s"


# ============================================================================
# WELLNESS MODELS
# ============================================================================

class WellnessTask(models.Model):
    """Daily or evening wellness tasks for users."""
    CATEGORY_DAILY = "daily"
    CATEGORY_EVENING = "evening"
    
    CATEGORY_CHOICES = [
        (CATEGORY_DAILY, "Daily"),
        (CATEGORY_EVENING, "Evening"),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="wellness_tasks",
        help_text="User who owns this task"
    )
    title = models.CharField(
        max_length=150,
        help_text="Task title"
    )
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        help_text="Task category"
    )
    is_completed = models.BooleanField(
        default=False,
        help_text="Whether task is completed"
    )
    order = models.PositiveIntegerField(
        default=0,
        help_text="Display order"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When task was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When task was last updated"
    )

    class Meta:
        unique_together = ("user", "title", "category")
        ordering = ("category", "order", "id")
        indexes = [
            models.Index(fields=["user", "category", "is_completed"]),
            models.Index(fields=["user", "-created_at"]),
        ]
        verbose_name = "Wellness Task"
        verbose_name_plural = "Wellness Tasks"

    def __str__(self) -> str:
        return f"{self.user.username} Ã¢â‚¬Â¢ {self.title}"
    
    def save(self, *args, **kwargs):
        """Ensure task is always saved with timestamps."""
        super().save(*args, **kwargs)


class WellnessJournalEntry(models.Model):
    """Journal entries for user wellness tracking."""
    ENTRY_TYPE_3_DAY = "3-Day Journal"
    ENTRY_TYPE_WEEKLY = "Weekly Journal"
    ENTRY_TYPE_CUSTOM = "Custom"
    
    ENTRY_TYPE_CHOICES = [
        (ENTRY_TYPE_3_DAY, "3-Day Journal"),
        (ENTRY_TYPE_WEEKLY, "Weekly Journal"),
        (ENTRY_TYPE_CUSTOM, "Custom"),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="wellness_journal_entries",
        help_text="User who owns this journal entry"
    )
    title = models.CharField(
        max_length=160,
        help_text="Entry title"
    )
    note = models.TextField(
        help_text="Journal entry content"
    )
    mood = models.CharField(
        max_length=16,
        help_text="Mood at time of entry"
    )
    entry_type = models.CharField(
        max_length=40,
        choices=ENTRY_TYPE_CHOICES,
        help_text="Type of journal entry"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When entry was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When entry was last updated"
    )

    class Meta:
        ordering = ("-created_at", "-id")
        indexes = [
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["user", "entry_type", "-created_at"]),
        ]
        verbose_name = "Wellness Journal Entry"
        verbose_name_plural = "Wellness Journal Entries"

    def __str__(self) -> str:
        return f"{self.user.username} Ã¢â‚¬Â¢ {self.title}"
    
    def save(self, *args, **kwargs):
        """Ensure journal entry is always saved with timestamps."""
        super().save(*args, **kwargs)


class MoodLog(models.Model):
    """Log of user mood updates."""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="mood_logs",
        help_text="User who recorded this mood"
    )
    value = models.PositiveSmallIntegerField(
        help_text="Mood value (1-5 scale)"
    )
    recorded_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When mood was recorded"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When log was created"
    )

    class Meta:
        ordering = ("-recorded_at", "-id")
        indexes = [
            models.Index(fields=["user", "-recorded_at"]),
            models.Index(fields=["user", "value", "-recorded_at"]),
        ]
        verbose_name = "Mood Log"
        verbose_name_plural = "Mood Logs"

    def __str__(self) -> str:
        return f"{self.user.username} -> {self.value} @ {self.recorded_at}"

    def save(self, *args, **kwargs):
        """Ensure mood log is always saved with timestamp."""
        if not self.recorded_at:
            self.recorded_at = timezone.now()
        super().save(*args, **kwargs)


# ============================================================================
# SUPPORT GROUP MODELS
# ============================================================================

class SupportGroup(models.Model):
    """Support groups for users."""
    slug = models.SlugField(
        max_length=80,
        unique=True,
        help_text="Unique URL-friendly identifier"
    )
    name = models.CharField(
        max_length=160,
        help_text="Group name"
    )
    description = models.TextField(
        blank=True,
        help_text="Group description"
    )
    icon = models.CharField(
        max_length=64,
        blank=True,
        help_text="Icon identifier"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When group was created"
    )

    class Meta:
        ordering = ("name",)
        verbose_name = "Support Group"
        verbose_name_plural = "Support Groups"

    def __str__(self) -> str:
        return self.name


class SupportGroupMembership(models.Model):
    """Membership relationship between users and support groups."""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="support_group_memberships",
        help_text="User who is a member"
    )
    group = models.ForeignKey(
        SupportGroup,
        on_delete=models.CASCADE,
        related_name="memberships",
        help_text="Support group"
    )
    joined_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When user joined the group"
    )

    class Meta:
        unique_together = ("user", "group")
        ordering = ("-joined_at",)
        verbose_name = "Support Group Membership"
        verbose_name_plural = "Support Group Memberships"

    def __str__(self) -> str:
        return f"{self.user.username} -> {self.group.slug}"


# ============================================================================
# CONTENT MODELS
# ============================================================================

class GuidanceResource(models.Model):
    """Guidance resources (articles, talks, podcasts)."""
    TYPE_ARTICLE = "article"
    TYPE_TALK = "talk"
    TYPE_PODCAST = "podcast"
    
    TYPE_CHOICES = [
        (TYPE_ARTICLE, "Article"),
        (TYPE_TALK, "Expert Talk"),
        (TYPE_PODCAST, "Podcast"),
    ]

    resource_type = models.CharField(
        max_length=16,
        choices=TYPE_CHOICES,
        help_text="Type of resource"
    )
    title = models.CharField(
        max_length=200,
        help_text="Resource title"
    )
    subtitle = models.CharField(
        max_length=160,
        blank=True,
        help_text="Resource subtitle"
    )
    summary = models.TextField(
        blank=True,
        help_text="Resource summary"
    )
    category = models.CharField(
        max_length=120,
        blank=True,
        help_text="Resource category"
    )
    duration = models.CharField(
        max_length=40,
        blank=True,
        help_text="Resource duration"
    )
    media_url = models.URLField(
        blank=True,
        help_text="Media URL"
    )
    thumbnail = models.URLField(
        blank=True,
        help_text="Thumbnail URL"
    )
    is_featured = models.BooleanField(
        default=False,
        help_text="Whether resource is featured"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When resource was created"
    )

    class Meta:
        ordering = ("resource_type", "title")
        verbose_name = "Guidance Resource"
        verbose_name_plural = "Guidance Resources"

    def __str__(self) -> str:
        return f"{self.get_resource_type_display()} Ã¢â‚¬Â¢ {self.title}"


class MusicTrack(models.Model):
    """Music tracks for mood-based listening."""
    MOOD_CALM = "calm"
    MOOD_FOCUS = "focus"
    MOOD_SLEEP = "sleep"
    MOOD_UPLIFT = "uplift"
    
    MOOD_CHOICES = [
        (MOOD_CALM, "Calm"),
        (MOOD_FOCUS, "Focus"),
        (MOOD_SLEEP, "Sleep"),
        (MOOD_UPLIFT, "Uplift"),
    ]

    title = models.CharField(
        max_length=160,
        unique=True,
        help_text="Track title"
    )
    description = models.TextField(
        blank=True,
        help_text="Track description"
    )
    duration_seconds = models.PositiveIntegerField(
        default=180,
        help_text="Track duration in seconds"
    )
    audio_url = models.URLField(
        blank=True,
        help_text="Audio file URL"
    )
    mood = models.CharField(
        max_length=20,
        choices=MOOD_CHOICES,
        default=MOOD_CALM,
        help_text="Mood category"
    )
    thumbnail = models.URLField(
        blank=True,
        help_text="Thumbnail URL"
    )
    order = models.PositiveIntegerField(
        default=0,
        help_text="Display order"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When track was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When track was last updated"
    )

    class Meta:
        ordering = ["order", "title"]
        verbose_name = "Music Track"
        verbose_name_plural = "Music Tracks"

    def __str__(self) -> str:
        return self.title


class MindCareBooster(models.Model):
    """Mind care boosters (breathing, audio, movement, reflection)."""
    CATEGORY_BREATHING = "breathing"
    CATEGORY_AUDIO = "audio"
    CATEGORY_MOVEMENT = "movement"
    CATEGORY_REFLECTION = "reflection"
    
    CATEGORY_CHOICES = [
        (CATEGORY_BREATHING, "Breathing"),
        (CATEGORY_AUDIO, "Audio"),
        (CATEGORY_MOVEMENT, "Movement"),
        (CATEGORY_REFLECTION, "Reflection"),
    ]

    title = models.CharField(
        max_length=160,
        unique=True,
        help_text="Booster title"
    )
    subtitle = models.CharField(
        max_length=160,
        blank=True,
        help_text="Booster subtitle"
    )
    description = models.TextField(
        blank=True,
        help_text="Booster description"
    )
    category = models.CharField(
        max_length=32,
        choices=CATEGORY_CHOICES,
        default=CATEGORY_BREATHING,
        help_text="Booster category"
    )
    icon = models.CharField(
        max_length=40,
        blank=True,
        help_text="Icon identifier"
    )
    action_label = models.CharField(
        max_length=60,
        default="Start",
        help_text="Action button label"
    )
    prompt = models.TextField(
        blank=True,
        help_text="Booster prompt text"
    )
    order = models.PositiveIntegerField(
        default=0,
        help_text="Display order"
    )
    estimated_seconds = models.PositiveIntegerField(
        default=120,
        help_text="Estimated duration in seconds"
    )
    resource_url = models.URLField(
        blank=True,
        help_text="Resource URL"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When booster was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When booster was last updated"
    )

    class Meta:
        ordering = ["order", "title"]
        verbose_name = "Mind Care Booster"
        verbose_name_plural = "Mind Care Boosters"

    def __str__(self) -> str:
        return self.title


class MeditationSession(models.Model):
    """Meditation sessions with different difficulty levels."""
    DIFFICULTY_BEGINNER = "beginner"
    DIFFICULTY_INTERMEDIATE = "intermediate"
    DIFFICULTY_ADVANCED = "advanced"
    
    DIFFICULTY_CHOICES = [
        (DIFFICULTY_BEGINNER, "Beginner"),
        (DIFFICULTY_INTERMEDIATE, "Intermediate"),
        (DIFFICULTY_ADVANCED, "Advanced"),
    ]

    title = models.CharField(
        max_length=160,
        unique=True,
        help_text="Session title"
    )
    subtitle = models.CharField(
        max_length=160,
        blank=True,
        help_text="Session subtitle"
    )
    description = models.TextField(
        blank=True,
        help_text="Session description"
    )
    category = models.CharField(
        max_length=60,
        help_text="Session category"
    )
    duration_minutes = models.PositiveIntegerField(
        default=5,
        help_text="Session duration in minutes"
    )
    difficulty = models.CharField(
        max_length=20,
        choices=DIFFICULTY_CHOICES,
        default=DIFFICULTY_BEGINNER,
        help_text="Difficulty level"
    )
    audio_url = models.URLField(
        blank=True,
        help_text="Audio file URL"
    )
    video_url = models.URLField(
        blank=True,
        help_text="Video file URL"
    )
    is_featured = models.BooleanField(
        default=False,
        help_text="Whether session is featured"
    )
    thumbnail = models.URLField(
        blank=True,
        help_text="Thumbnail URL"
    )
    order = models.PositiveIntegerField(
        default=0,
        help_text="Display order"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When session was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When session was last updated"
    )

    class Meta:
        ordering = ["order", "title"]
        verbose_name = "Meditation Session"
        verbose_name_plural = "Meditation Sessions"

    def __str__(self) -> str:
        return self.title


# ============================================================================
# AUTHENTICATION MODELS
# ============================================================================

class EmailOTP(models.Model):
    """Email OTP for registration and password reset."""
    PURPOSE_REGISTRATION = "registration"
    PURPOSE_PASSWORD_RESET = "password_reset"
    
    PURPOSE_CHOICES = [
        (PURPOSE_REGISTRATION, "Registration"),
        (PURPOSE_PASSWORD_RESET, "Password reset"),
    ]

    email = models.EmailField(
        help_text="Email address"
    )
    code = models.CharField(
        max_length=6,
        help_text="OTP code"
    )
    purpose = models.CharField(
        max_length=32,
        choices=PURPOSE_CHOICES,
        help_text="OTP purpose"
    )
    token = models.CharField(
        max_length=64,
        unique=True,
        help_text="Unique verification token"
    )
    is_verified = models.BooleanField(
        default=False,
        help_text="Whether OTP is verified"
    )
    attempts = models.PositiveSmallIntegerField(
        default=0,
        help_text="Number of verification attempts"
    )
    expires_at = models.DateTimeField(
        help_text="When OTP expires"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When OTP was created"
    )
    verified_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When OTP was verified"
    )
    is_used = models.BooleanField(
        default=False,
        help_text="Whether OTP was used for registration"
    )
    used_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When OTP was used"
    )

    class Meta:
        indexes = [
            models.Index(fields=["email", "purpose", "is_verified"]),
            models.Index(fields=["token"]),
        ]
        ordering = ("-created_at",)
        verbose_name = "Email OTP"
        verbose_name_plural = "Email OTPs"

    def __str__(self) -> str:
        return f"{self.email} -> {self.purpose}"

    @property
    def is_expired(self) -> bool:
        """Check if OTP is expired."""
        return timezone.now() >= self.expires_at

    def mark_verified(self):
        """Mark OTP as verified and set verified_at timestamp."""
        self.is_verified = True
        self.verified_at = timezone.now()
        self.save(update_fields=["is_verified", "verified_at"])

    def mark_used(self):
        """Mark OTP as used (after successful registration)."""
        self.is_used = True
        self.used_at = timezone.now()
        self.save(update_fields=["is_used", "used_at"])


# ============================================================================
# ASSESSMENT MODELS
# ============================================================================

class Assessment(models.Model):
    """
    Model to store user assessment/mental health check results.
    
    Stores each assessment attempt with all question responses (actual answer text),
    calculated scores, and generated feedback with notes.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="assessments",
        help_text="User who took this assessment"
    )
    username = models.CharField(
        max_length=150,
        default="",
        help_text="Username of the user who took this assessment"
    )
    
    # Individual question responses - stores the actual answer text
    feeling_response = models.CharField(
        max_length=50,
        default="",
        help_text="Answer to: How have you been feeling lately? (e.g., 'Very positive', 'Low')"
    )
    sleep_quality_response = models.CharField(
        max_length=50,
        default="",
        help_text="Answer to: How is your sleep quality? (e.g., 'Excellent', 'Poor')"
    )
    anxiety_frequency_response = models.CharField(
        max_length=50,
        default="",
        help_text="Answer to: How often do you feel anxious? (e.g., 'Rarely', 'Always')"
    )
    energy_level_response = models.CharField(
        max_length=50,
        default="",
        help_text="Answer to: How energized do you feel? (e.g., 'Very energized', 'Exhausted')"
    )
    support_feeling_response = models.CharField(
        max_length=50,
        default="",
        help_text="Answer to: How supported do you feel? (e.g., 'Always', 'Not at all')"
    )
    stress_management_response = models.CharField(
        max_length=50,
        default="",
        help_text="Answer to: How well are you managing stress? (e.g., 'Thriving', 'Overwhelmed')"
    )
    
    # Calculated scores
    average_score = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        help_text="Average score across all questions (0.00 to 4.00)"
    )
    mood_score = models.PositiveSmallIntegerField(
        help_text="Calculated mood score (0-100)"
    )
    
    # Feedback stored
    feedback_message = models.TextField(
        help_text="AI-generated feedback message based on score"
    )
    feedback_tip = models.TextField(
        help_text="AI-generated tip based on score"
    )
    
    # Notes based on score
    notes = models.TextField(
        blank=True,
        default="",
        help_text="Additional notes based on assessment score"
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text="When assessment was taken"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When assessment was last updated"
    )

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["user", "mood_score"]),
        ]
        verbose_name = "Assessment"
        verbose_name_plural = "Assessments"

    def __str__(self) -> str:
        return f"{self.user.username} - Assessment {self.mood_score}/100 @ {self.created_at}"
    
    def save(self, *args, **kwargs):
        """Ensure assessment is always saved with timestamps."""
        super().save(*args, **kwargs)
        logger.debug(
            f"Assessment saved: user={self.user_id}, mood_score={self.mood_score}, "
            f"created_at={self.created_at}"
        )