"""
Django management command to manually check database for saved messages
"""
from django.core.management.base import BaseCommand
from django.db import connection
from api.models import Chat, ChatMessage
from django.contrib.auth.models import User


class Command(BaseCommand):
    help = 'Manually check database to see what is actually saved'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("\n" + "=" * 80))
        self.stdout.write(self.style.SUCCESS("MANUAL DATABASE CHECK"))
        self.stdout.write(self.style.SUCCESS("=" * 80))
        
        # Direct SQL query to check table structure
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("1. CHECKING TABLE STRUCTURE"))
        self.stdout.write("=" * 80)
        
        with connection.cursor() as cursor:
            # Check if table exists
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='api_chatmessage';")
            table_exists = cursor.fetchone()
            
            if table_exists:
                self.stdout.write(self.style.SUCCESS("✅ Table 'api_chatmessage' EXISTS"))
                
                # Get table structure
                cursor.execute("PRAGMA table_info(api_chatmessage);")
                columns = cursor.fetchall()
                
                self.stdout.write("\nTable Structure:")
                self.stdout.write(f"{'Column':<20} {'Type':<20} {'Not Null':<10} {'Default':<15}")
                self.stdout.write("-" * 80)
                for col in columns:
                    cid, name, col_type, not_null, default, pk = col
                    not_null_str = "YES" if not_null else "NO"
                    default_str = str(default) if default else "NULL"
                    self.stdout.write(f"{name:<20} {col_type:<20} {not_null_str:<10} {default_str:<15}")
            else:
                self.stdout.write(self.style.ERROR("❌ Table 'api_chatmessage' DOES NOT EXIST!"))
                return
        
        # Count records using ORM
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("2. COUNTING RECORDS (ORM)"))
        self.stdout.write("=" * 80)
        
        total_chats = Chat.objects.count()
        total_messages = ChatMessage.objects.count()
        
        self.stdout.write(f"\nTotal Chats: {total_chats}")
        self.stdout.write(f"Total Messages: {total_messages}")
        
        if total_messages == 0:
            self.stdout.write(self.style.WARNING("\n⚠️  NO MESSAGES FOUND IN DATABASE!"))
        else:
            self.stdout.write(self.style.SUCCESS(f"\n✅ Found {total_messages} messages"))
        
        # Direct SQL count
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("3. COUNTING RECORDS (DIRECT SQL)"))
        self.stdout.write("=" * 80)
        
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM api_chatmessage;")
            sql_count = cursor.fetchone()[0]
            self.stdout.write(f"\nDirect SQL COUNT: {sql_count}")
            
            if sql_count != total_messages:
                self.stdout.write(self.style.ERROR(f"⚠️  MISMATCH! ORM count: {total_messages}, SQL count: {sql_count}"))
            else:
                self.stdout.write(self.style.SUCCESS("✅ Counts match!"))
        
        # Show all messages with direct SQL
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("4. ALL MESSAGES (DIRECT SQL QUERY)"))
        self.stdout.write("=" * 80)
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    id, 
                    chat_id, 
                    sender_id, 
                    text, 
                    created_at 
                FROM api_chatmessage 
                ORDER BY created_at DESC 
                LIMIT 20;
            """)
            
            rows = cursor.fetchall()
            
            if not rows:
                self.stdout.write(self.style.WARNING("\n⚠️  NO MESSAGES IN DATABASE!"))
            else:
                self.stdout.write(f"\nFound {len(rows)} messages (showing last 20):")
                self.stdout.write("-" * 80)
                self.stdout.write(f"{'ID':<6} {'Chat ID':<8} {'Sender ID':<10} {'Text (first 40)':<45} {'Created At'}")
                self.stdout.write("-" * 80)
                
                for row in rows:
                    msg_id, chat_id, sender_id, text, created_at = row
                    text_preview = (text[:40] + "...") if text and len(text) > 40 else (text or "")
                    self.stdout.write(f"{msg_id:<6} {chat_id:<8} {sender_id:<10} {text_preview:<45} {created_at}")
        
        # Show messages with user and chat info
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("5. MESSAGES WITH DETAILS (ORM)"))
        self.stdout.write("=" * 80)
        
        messages = ChatMessage.objects.select_related('chat', 'sender').all().order_by('-created_at')[:10]
        
        if not messages:
            self.stdout.write(self.style.WARNING("\n⚠️  NO MESSAGES FOUND!"))
        else:
            self.stdout.write(f"\nShowing last {len(messages)} messages:")
            self.stdout.write("-" * 80)
            
            for msg in messages:
                self.stdout.write(f"\nMessage ID: {msg.id}")
                self.stdout.write(f"  Chat ID: {msg.chat_id} | Status: {msg.chat.status}")
                self.stdout.write(f"  Sender: {msg.sender.username} (ID: {msg.sender_id})")
                self.stdout.write(f"  Text: {msg.text[:60]}..." if len(msg.text) > 60 else f"  Text: {msg.text}")
                self.stdout.write(f"  Created: {msg.created_at}")
                self.stdout.write("-" * 80)
        
        # Check for recent activity
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("6. RECENT ACTIVITY CHECK"))
        self.stdout.write("=" * 80)
        
        from django.utils import timezone
        from datetime import timedelta
        
        recent_cutoff = timezone.now() - timedelta(hours=24)
        recent_messages = ChatMessage.objects.filter(created_at__gte=recent_cutoff).count()
        
        self.stdout.write(f"\nMessages in last 24 hours: {recent_messages}")
        
        if recent_messages == 0 and total_messages > 0:
            self.stdout.write(self.style.WARNING("⚠️  No recent messages, but old messages exist"))
        elif recent_messages == 0:
            self.stdout.write(self.style.WARNING("⚠️  No messages at all in database"))
        else:
            self.stdout.write(self.style.SUCCESS(f"✅ {recent_messages} recent messages found"))
        
        # Check chats with messages
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("7. CHATS WITH MESSAGES"))
        self.stdout.write("=" * 80)
        
        from django.db.models import Count
        
        chats_with_messages = Chat.objects.annotate(
            msg_count=Count('messages')
        ).filter(msg_count__gt=0).order_by('-created_at')[:10]
        
        if not chats_with_messages:
            self.stdout.write(self.style.WARNING("\n⚠️  NO CHATS HAVE MESSAGES!"))
        else:
            self.stdout.write(f"\nChats with messages (showing {len(chats_with_messages)}):")
            self.stdout.write("-" * 80)
            
            for chat in chats_with_messages:
                msg_count = ChatMessage.objects.filter(chat=chat).count()
                self.stdout.write(f"Chat ID: {chat.id} | User: {chat.user.username} | Status: {chat.status} | Messages: {msg_count}")
        
        # Final summary
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("SUMMARY"))
        self.stdout.write("=" * 80)
        
        self.stdout.write(f"\n✅ Total Chats: {total_chats}")
        self.stdout.write(f"✅ Total Messages: {total_messages}")
        self.stdout.write(f"✅ Recent Messages (24h): {recent_messages}")
        self.stdout.write(f"✅ Chats with Messages: {chats_with_messages.count()}")
        
        if total_messages == 0:
            self.stdout.write(self.style.ERROR("\n❌ NO MESSAGES IN DATABASE!"))
            self.stdout.write("   This means messages are NOT being saved.")
            self.stdout.write("   Check:")
            self.stdout.write("   1. Backend logs for 'SAVING MESSAGE'")
            self.stdout.write("   2. Backend logs for 'MESSAGE SAVED SUCCESSFULLY'")
            self.stdout.write("   3. Backend logs for any errors")
        else:
            self.stdout.write(self.style.SUCCESS("\n✅ Messages ARE in database!"))
            self.stdout.write("   If messages aren't showing in app, check:")
            self.stdout.write("   1. API endpoint for loading messages")
            self.stdout.write("   2. Frontend code for displaying messages")
            self.stdout.write("   3. WebSocket connection for real-time updates")
        
        self.stdout.write("\n" + "=" * 80)

