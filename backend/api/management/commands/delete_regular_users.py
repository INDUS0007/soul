"""
Django management command to delete all regular users (non-counselors, non-doctors).
Usage: python manage.py delete_regular_users [--confirm]
"""

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
from api.models import (
    Chat, ChatMessage, UserProfile, CounsellorProfile, DoctorProfile,
    WellnessTask, WellnessJournalEntry, SupportGroupMembership,
    UpcomingSession, MoodLog, EmailOTP
)


class Command(BaseCommand):
    help = 'Delete all regular users (non-counselors, non-doctors) and their data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Confirm deletion (required to actually delete)'
        )

    def handle(self, *args, **options):
        if not options['confirm']:
            raise CommandError(
                'This will delete ALL regular users. Use --confirm to proceed.\n'
                'Example: python manage.py delete_regular_users --confirm'
            )
        
        # Get counselor and doctor user IDs
        counselor_ids = list(CounsellorProfile.objects.values_list('user_id', flat=True))
        doctor_ids = list(DoctorProfile.objects.values_list('user_id', flat=True))
        protected_ids = set(counselor_ids + doctor_ids)
        
        # Get all regular users (not counselors or doctors)
        regular_users = User.objects.exclude(id__in=protected_ids)
        user_count = regular_users.count()
        
        if user_count == 0:
            self.stdout.write(self.style.WARNING("No regular users found to delete."))
            return
        
        self.stdout.write(self.style.WARNING(f"\n{'='*80}"))
        self.stdout.write(self.style.WARNING(f"WARNING: This will delete {user_count} regular users!"))
        self.stdout.write(self.style.WARNING(f"{'='*80}\n"))
        
        deleted_count = 0
        for user in regular_users:
            try:
                username = user.username
                email = user.email
                user_id = user.id
                
                # Delete related data
                # Chats and messages
                chats = Chat.objects.filter(user=user)
                for chat in chats:
                    ChatMessage.objects.filter(chat=chat).delete()
                chats.delete()
                
                # Assigned chats (if user was a counselor - shouldn't happen for regular users)
                assigned_chats = Chat.objects.filter(counsellor=user)
                for chat in assigned_chats:
                    ChatMessage.objects.filter(chat=chat).delete()
                assigned_chats.delete()
                
                # User profile
                if hasattr(user, 'profile'):
                    user.profile.delete()
                
                # Wellness tasks
                WellnessTask.objects.filter(user=user).delete()
                
                # Wellness journal entries
                WellnessJournalEntry.objects.filter(user=user).delete()
                
                # Support group memberships
                SupportGroupMembership.objects.filter(user=user).delete()
                
                # Upcoming sessions
                UpcomingSession.objects.filter(user=user).delete()
                
                # Mood logs
                MoodLog.objects.filter(user=user).delete()
                
                # Email OTPs
                EmailOTP.objects.filter(email=email).delete()
                
                # Delete user
                user.delete()
                deleted_count += 1
                
                self.stdout.write(
                    self.style.SUCCESS(f"  [OK] Deleted user: {username} ({email})")
                )
            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f"  [ERROR] Failed to delete user {user.username}: {e}")
                )
        
        self.stdout.write(self.style.SUCCESS(f"\n{'='*80}"))
        self.stdout.write(self.style.SUCCESS(f"Successfully deleted {deleted_count} regular users"))
        self.stdout.write(self.style.SUCCESS(f"{'='*80}\n"))

