"""
Management command to reset the database:
- Delete all regular users (cascades to all their data)
- Keep counselor users but delete all their related data (chats, messages, sessions, calls)
"""
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.db import transaction
from api.models import (
    Chat,
    ChatMessage,
    UpcomingSession,
    Call,
    UserProfile,
    WellnessTask,
    WellnessJournalEntry,
    MoodLog,
    SupportGroupMembership,
    EmailOTP,
    CounsellorProfile,
    DoctorProfile,
)


class Command(BaseCommand):
    help = 'Reset database: Delete all regular users and all counselor-related data (keep counselor users)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Confirm that you want to delete all data',
        )

    def handle(self, *args, **options):
        if not options['confirm']:
            self.stdout.write(
                self.style.WARNING(
                    '\nWARNING: This will delete ALL regular users and ALL counselor-related data!\n'
                    'Counselor User records will be kept, but all their chats, messages, sessions, and calls will be deleted.\n'
                    'This action CANNOT be undone!\n'
                )
            )
            confirm = input('Type "YES" to confirm: ')
            if confirm != 'YES':
                self.stdout.write(self.style.ERROR('Operation cancelled.'))
                return

        with transaction.atomic():
            # Step 1: Identify counselor users BEFORE deleting profiles
            self.stdout.write('\nIdentifying counselor users...')
            counselor_user_ids = list(CounsellorProfile.objects.values_list('user_id', flat=True))
            counselor_count = len(counselor_user_ids)
            
            if counselor_count > 0:
                self.stdout.write(f'   Found {counselor_count} counselor(s) - will keep User records')
            else:
                self.stdout.write('   No counselors found')
            
            # Step 2: Delete all counselor-related data (but keep User records)
            self.stdout.write('\nDeleting counselor-related data (keeping User records)...')
            
            # Delete all chats and messages (counselor-related)
            chats_deleted = Chat.objects.all().delete()[0]
            self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {chats_deleted} chat(s)'))
            
            # Delete all messages (should be cascaded, but delete explicitly)
            messages_deleted = ChatMessage.objects.all().delete()[0]
            self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {messages_deleted} message(s)'))
            
            # Delete all sessions
            sessions_deleted = UpcomingSession.objects.all().delete()[0]
            self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {sessions_deleted} session(s)'))
            
            # Delete all calls
            calls_deleted = Call.objects.all().delete()[0]
            self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {calls_deleted} call(s)'))
            
            # Delete counselor profiles (but keep User records)
            counselor_profiles_deleted = CounsellorProfile.objects.all().delete()[0]
            self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {counselor_profiles_deleted} counselor profile(s)'))
            
            # Delete doctor profiles
            doctor_profiles_deleted = DoctorProfile.objects.all().delete()[0]
            self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {doctor_profiles_deleted} doctor profile(s)'))
            
            # Step 3: Delete all regular users (this will cascade delete all their data)
            self.stdout.write('\nDeleting all regular users (non-counselors)...')
            
            # Get regular users (exclude counselor user IDs)
            if counselor_user_ids:
                regular_users = User.objects.exclude(id__in=counselor_user_ids)
            else:
                regular_users = User.objects.all()
            
            regular_count = regular_users.count()
            
            if regular_count > 0:
                self.stdout.write(f'   Found {regular_count} regular user(s)')
                
                # Delete all user-related data first (cascades from User deletion, but explicit for clarity)
                user_profiles_deleted = UserProfile.objects.filter(user__in=regular_users).delete()[0]
                self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {user_profiles_deleted} user profile(s)'))
                
                wellness_tasks_deleted = WellnessTask.objects.filter(user__in=regular_users).delete()[0]
                self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {wellness_tasks_deleted} wellness task(s)'))
                
                journal_entries_deleted = WellnessJournalEntry.objects.filter(user__in=regular_users).delete()[0]
                self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {journal_entries_deleted} journal entr(ies)'))
                
                mood_logs_deleted = MoodLog.objects.filter(user__in=regular_users).delete()[0]
                self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {mood_logs_deleted} mood log(s)'))
                
                memberships_deleted = SupportGroupMembership.objects.filter(user__in=regular_users).delete()[0]
                self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {memberships_deleted} support group membership(s)'))
                
                otps_deleted = EmailOTP.objects.all().delete()[0]
                self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {otps_deleted} OTP(s)'))
                
                # Now delete all regular users (this will cascade delete any remaining related data)
                users_deleted = regular_users.delete()[0]
                self.stdout.write(self.style.SUCCESS(f'   [OK] Deleted {users_deleted} regular user(s)'))
            else:
                self.stdout.write('   No regular users found')
            
            # Final summary
            remaining_users = User.objects.count()
            self.stdout.write(
                self.style.SUCCESS(
                    f'\nDatabase reset complete!\n'
                    f'   - Deleted all regular users and their data\n'
                    f'   - Deleted all chats, messages, sessions, and calls\n'
                    f'   - Deleted all counselor profiles (kept {remaining_users} User record(s))\n'
                    f'   - Database is now clean and ready for fresh data\n'
                )
            )

