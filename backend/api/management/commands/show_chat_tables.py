"""
Django management command to show Chat and ChatMessage table structure and data
"""
from django.core.management.base import BaseCommand
from django.db import connection
from api.models import Chat, ChatMessage
from django.contrib.auth.models import User


class Command(BaseCommand):
    help = 'Show Chat and ChatMessage table structure and data'

    def handle(self, *args, **options):
        self.show_table_structure()
        self.show_chat_data()
        self.show_message_data()
        self.show_messages_by_chat()

    def show_table_structure(self):
        """Show the SQL table structure"""
        self.stdout.write(self.style.SUCCESS("\n" + "=" * 80))
        self.stdout.write(self.style.SUCCESS("DATABASE TABLE STRUCTURES"))
        self.stdout.write(self.style.SUCCESS("=" * 80))
        
        with connection.cursor() as cursor:
            # Show Chat table structure
            self.stdout.write("\n📋 CHAT TABLE STRUCTURE:")
            self.stdout.write("-" * 80)
            cursor.execute("PRAGMA table_info(api_chat);")
            columns = cursor.fetchall()
            self.stdout.write(f"{'Column Name':<20} {'Type':<20} {'Not Null':<10} {'Default':<15}")
            self.stdout.write("-" * 80)
            for col in columns:
                cid, name, col_type, not_null, default, pk = col
                not_null_str = "YES" if not_null else "NO"
                default_str = str(default) if default else "NULL"
                self.stdout.write(f"{name:<20} {col_type:<20} {not_null_str:<10} {default_str:<15}")
            
            # Show ChatMessage table structure
            self.stdout.write("\n💬 CHATMESSAGE TABLE STRUCTURE:")
            self.stdout.write("-" * 80)
            cursor.execute("PRAGMA table_info(api_chatmessage);")
            columns = cursor.fetchall()
            self.stdout.write(f"{'Column Name':<20} {'Type':<20} {'Not Null':<10} {'Default':<15}")
            self.stdout.write("-" * 80)
            for col in columns:
                cid, name, col_type, not_null, default, pk = col
                not_null_str = "YES" if not_null else "NO"
                default_str = str(default) if default else "NULL"
                self.stdout.write(f"{name:<20} {col_type:<20} {not_null_str:<10} {default_str:<15}")

    def show_chat_data(self):
        """Show actual chat data"""
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("CHAT DATA"))
        self.stdout.write("=" * 80)
        
        chats = Chat.objects.select_related('user', 'counsellor').all().order_by('-created_at')[:10]
        
        if not chats:
            self.stdout.write("\nNo chats found in database.")
            return
        
        self.stdout.write(f"\n📊 Total Chats: {Chat.objects.count()}")
        self.stdout.write(f"Showing first {len(chats)} chats:\n")
        
        for chat in chats:
            self.stdout.write(f"Chat ID: {chat.id}")
            self.stdout.write(f"  User: {chat.user.username} (ID: {chat.user.id})")
            self.stdout.write(f"  Counsellor: {chat.counsellor.username if chat.counsellor else 'None'} (ID: {chat.counsellor_id if chat.counsellor else 'None'})")
            self.stdout.write(f"  Status: {chat.status}")
            self.stdout.write(f"  Initial Message: {chat.initial_message[:50] if chat.initial_message else 'None'}...")
            self.stdout.write(f"  Created: {chat.created_at}")
            self.stdout.write(f"  Started: {chat.started_at if chat.started_at else 'Not started'}")
            self.stdout.write(f"  Messages Count: {chat.messages.count()}")
            self.stdout.write("-" * 80)

    def show_message_data(self):
        """Show actual message data"""
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("CHAT MESSAGE DATA"))
        self.stdout.write("=" * 80)
        
        messages = ChatMessage.objects.select_related('chat', 'sender').all().order_by('-created_at')[:20]
        
        if not messages:
            self.stdout.write("\nNo messages found in database.")
            return
        
        self.stdout.write(f"\n💬 Total Messages: {ChatMessage.objects.count()}")
        self.stdout.write(f"Showing last {len(messages)} messages:\n")
        
        for msg in messages:
            self.stdout.write(f"Message ID: {msg.id}")
            self.stdout.write(f"  Chat ID: {msg.chat_id}")
            self.stdout.write(f"  Sender: {msg.sender.username} (ID: {msg.sender.id})")
            self.stdout.write(f"  Text: {msg.text[:60]}..." if len(msg.text) > 60 else f"  Text: {msg.text}")
            self.stdout.write(f"  Created: {msg.created_at}")
            self.stdout.write("-" * 80)

    def show_messages_by_chat(self):
        """Show messages grouped by chat"""
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("MESSAGES GROUPED BY CHAT"))
        self.stdout.write("=" * 80)
        
        chats = Chat.objects.prefetch_related('messages__sender').all().order_by('-created_at')[:5]
        
        if not chats:
            self.stdout.write("\nNo chats found.")
            return
        
        for chat in chats:
            messages = chat.messages.all().order_by('created_at')
            self.stdout.write(f"\n📋 Chat ID: {chat.id} | Status: {chat.status} | User: {chat.user.username}")
            self.stdout.write(f"   Messages: {messages.count()}")
            self.stdout.write("-" * 80)
            
            if messages:
                for msg in messages:
                    sender_type = "USER" if msg.sender == chat.user else "COUNSELOR"
                    msg_text = msg.text[:50] + "..." if len(msg.text) > 50 else msg.text
                    self.stdout.write(f"  [{msg.created_at.strftime('%Y-%m-%d %H:%M:%S')}] {sender_type}: {msg_text}")
            else:
                self.stdout.write("  (No messages yet)")
            self.stdout.write("")
        
        self.stdout.write(self.style.SUCCESS("\n✅ Database tables and data displayed successfully!"))

