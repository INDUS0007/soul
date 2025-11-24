"""
Django management command to fix chats that should be assigned to counselors
"""
from django.core.management.base import BaseCommand
from api.models import Chat, ChatMessage
from django.contrib.auth.models import User
from django.db.models import Q


class Command(BaseCommand):
    help = 'Fix chats to ensure counselors can see them - assign counselor to active chats'

    def add_arguments(self, parser):
        parser.add_argument(
            '--counselor-username',
            type=str,
            help='Username of counselor to assign chats to',
        )
        parser.add_argument(
            '--auto-assign',
            action='store_true',
            help='Automatically assign active chats without counselor to first available counselor',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("\n" + "=" * 80))
        self.stdout.write(self.style.SUCCESS("FIXING COUNSELOR CHAT ASSIGNMENTS"))
        self.stdout.write(self.style.SUCCESS("=" * 80))
        
        # Get all chats
        all_chats = Chat.objects.select_related('user', 'counsellor').all()
        total_chats = all_chats.count()
        
        self.stdout.write(f"\n📊 Database Status:")
        self.stdout.write(f"   Total Chats: {total_chats}")
        
        # Count chats by status
        queued = Chat.objects.filter(status='queued').count()
        active = Chat.objects.filter(status='active').count()
        completed = Chat.objects.filter(status='completed').count()
        cancelled = Chat.objects.filter(status='cancelled').count()
        
        self.stdout.write(f"   Queued: {queued}")
        self.stdout.write(f"   Active: {active}")
        self.stdout.write(f"   Completed: {completed}")
        self.stdout.write(f"   Cancelled: {cancelled}")
        
        # Count chats with/without counselor
        with_counselor = Chat.objects.exclude(counsellor__isnull=True).count()
        without_counselor = Chat.objects.filter(counsellor__isnull=True).count()
        
        self.stdout.write(f"\n👤 Counselor Assignment:")
        self.stdout.write(f"   Chats with counselor: {with_counselor}")
        self.stdout.write(f"   Chats without counselor: {without_counselor}")
        
        # Show all chats
        self.stdout.write(f"\n📋 All Chats in Database:")
        self.stdout.write("-" * 80)
        for chat in all_chats[:20]:
            counselor_info = f"{chat.counsellor.username} (ID: {chat.counsellor_id})" if chat.counsellor else "None"
            msg_count = ChatMessage.objects.filter(chat=chat).count()
            self.stdout.write(
                f"   Chat ID: {chat.id} | User: {chat.user.username} | "
                f"Status: {chat.status} | Counselor: {counselor_info} | "
                f"Messages: {msg_count}"
            )
        
        # If auto-assign is requested
        if options['auto_assign']:
            self.stdout.write(f"\n🔄 Auto-assigning active chats without counselor...")
            
            # Get first available counselor
            counselors = User.objects.filter(counsellorprofile__isnull=False)
            if not counselors.exists():
                self.stdout.write(self.style.ERROR("   ❌ No counselors found in database!"))
                return
            
            counselor = counselors.first()
            self.stdout.write(f"   Using counselor: {counselor.username} (ID: {counselor.id})")
            
            # Find active chats without counselor
            active_without_counselor = Chat.objects.filter(
                status='active',
                counsellor__isnull=True
            )
            
            count = active_without_counselor.count()
            if count > 0:
                self.stdout.write(f"   Found {count} active chats without counselor")
                for chat in active_without_counselor:
                    chat.counsellor = counselor
                    chat.save(update_fields=['counsellor', 'updated_at'])
                    self.stdout.write(f"   ✅ Assigned chat {chat.id} to {counselor.username}")
                self.stdout.write(self.style.SUCCESS(f"\n✅ Assigned {count} chats to counselor"))
            else:
                self.stdout.write("   No active chats without counselor found")
        
        # If specific counselor username provided
        if options['counselor_username']:
            try:
                counselor = User.objects.get(username=options['counselor_username'])
                if not hasattr(counselor, 'counsellorprofile'):
                    self.stdout.write(self.style.ERROR(f"   ❌ User {counselor.username} is not a counselor!"))
                    return
                
                self.stdout.write(f"\n👤 Assigning chats to counselor: {counselor.username} (ID: {counselor.id})")
                
                # Show chats assigned to this counselor
                assigned_chats = Chat.objects.filter(counsellor=counselor)
                self.stdout.write(f"   Currently assigned: {assigned_chats.count()} chats")
                
                for chat in assigned_chats[:10]:
                    msg_count = ChatMessage.objects.filter(chat=chat).count()
                    self.stdout.write(
                        f"   - Chat ID: {chat.id}, User: {chat.user.username}, "
                        f"Status: {chat.status}, Messages: {msg_count}"
                    )
            except User.DoesNotExist:
                self.stdout.write(self.style.ERROR(f"   ❌ Counselor {options['counselor_username']} not found!"))
        
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("✅ Analysis complete!"))
        self.stdout.write("=" * 80)
        self.stdout.write("\nTo auto-assign active chats to first counselor:")
        self.stdout.write("  python manage.py fix_counselor_chats --auto-assign")
        self.stdout.write("\nTo see chats for specific counselor:")
        self.stdout.write("  python manage.py fix_counselor_chats --counselor-username <username>\n")

