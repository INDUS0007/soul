"""
Django management command to delete a user and all related data.
Usage: python manage.py delete_user <email>
"""

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
from api.models import (
    Chat, ChatMessage, UserProfile, CounsellorProfile, DoctorProfile,
    WellnessTask, WellnessJournalEntry, SupportGroupMembership,
    UpcomingSession, MoodLog, EmailOTP
)


class Command(BaseCommand):
    help = 'Delete a user and all related data from the database'

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help='Email address of the user to delete')

    def handle(self, *args, **options):
        email = options['email']
        
        try:
            user = User.objects.get(email=email)
            username = user.username
            user_id = user.id
            
            self.stdout.write(self.style.WARNING(f"\n{'='*60}"))
            self.stdout.write(self.style.WARNING(f"Deleting user: {username} ({email})"))
            self.stdout.write(self.style.WARNING(f"User ID: {user_id}"))
            self.stdout.write(self.style.WARNING(f"{'='*60}\n"))
            
            # Delete related data
            self.stdout.write("Deleting related data...")
            
            # Delete chats and chat messages
            chats = Chat.objects.filter(user=user)
            chat_count = chats.count()
            for chat in chats:
                ChatMessage.objects.filter(chat=chat).delete()
            chats.delete()
            self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {chat_count} chat(s) and their messages"))
            
            # Delete assigned chats (if user is a counselor)
            assigned_chats = Chat.objects.filter(counsellor=user)
            assigned_count = assigned_chats.count()
            for chat in assigned_chats:
                ChatMessage.objects.filter(chat=chat).delete()
            assigned_chats.delete()
            if assigned_count > 0:
                self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {assigned_count} assigned chat(s) as counselor"))
            
            # Delete user profile
            if hasattr(user, 'profile'):
                user.profile.delete()
                self.stdout.write(self.style.SUCCESS("  [OK] Deleted UserProfile"))
            
            # Delete counselor profile
            if hasattr(user, 'counsellorprofile'):
                user.counsellorprofile.delete()
                self.stdout.write(self.style.SUCCESS("  [OK] Deleted CounsellorProfile"))
            
            # Delete doctor profile
            if hasattr(user, 'doctorprofile'):
                user.doctorprofile.delete()
                self.stdout.write(self.style.SUCCESS("  [OK] Deleted DoctorProfile"))
            
            # Delete wellness tasks
            tasks = WellnessTask.objects.filter(user=user)
            task_count = tasks.count()
            tasks.delete()
            if task_count > 0:
                self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {task_count} wellness task(s)"))
            
            # Delete wellness journal entries
            journals = WellnessJournalEntry.objects.filter(user=user)
            journal_count = journals.count()
            journals.delete()
            if journal_count > 0:
                self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {journal_count} wellness journal entry/entries"))
            
            # Delete support group memberships
            memberships = SupportGroupMembership.objects.filter(user=user)
            membership_count = memberships.count()
            memberships.delete()
            if membership_count > 0:
                self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {membership_count} support group membership(s)"))
            
            # Delete upcoming sessions
            sessions = UpcomingSession.objects.filter(user=user)
            session_count = sessions.count()
            sessions.delete()
            if session_count > 0:
                self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {session_count} upcoming session(s)"))
            
            # Delete mood logs
            moods = MoodLog.objects.filter(user=user)
            mood_count = moods.count()
            moods.delete()
            if mood_count > 0:
                self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {mood_count} mood log(s)"))
            
            # Delete email OTPs
            otps = EmailOTP.objects.filter(email=email)
            otp_count = otps.count()
            otps.delete()
            if otp_count > 0:
                self.stdout.write(self.style.SUCCESS(f"  [OK] Deleted {otp_count} email OTP(s)"))
            
            # Finally, delete the user
            user.delete()
            self.stdout.write(self.style.SUCCESS(f"\n[SUCCESS] Successfully deleted user: {username} ({email})"))
            self.stdout.write(self.style.SUCCESS(f"{'='*60}\n"))
            
        except User.DoesNotExist:
            raise CommandError(f"User with email '{email}' not found in database.")
        except Exception as e:
            raise CommandError(f"Error deleting user: {e}")

