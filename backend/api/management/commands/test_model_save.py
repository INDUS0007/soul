"""
Django management command to test if Chat and ChatMessage models save all fields correctly
"""
from django.core.management.base import BaseCommand
from django.db import transaction
from api.models import Chat, ChatMessage
from django.contrib.auth.models import User
from django.utils import timezone


class Command(BaseCommand):
    help = 'Test if Chat and ChatMessage models save all fields correctly'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("\n" + "=" * 80))
        self.stdout.write(self.style.SUCCESS("TESTING MODEL SAVE OPERATIONS"))
        self.stdout.write(self.style.SUCCESS("=" * 80))
        
        # Get or create test users
        try:
            test_user, _ = User.objects.get_or_create(
                username='test_user_save',
                defaults={'email': 'test_user_save@example.com'}
            )
            test_counsellor, _ = User.objects.get_or_create(
                username='test_counsellor_save',
                defaults={'email': 'test_counsellor_save@example.com'}
            )
            
            self.stdout.write(f"\n✅ Test users ready:")
            self.stdout.write(f"   User: {test_user.username} (ID: {test_user.id})")
            self.stdout.write(f"   Counsellor: {test_counsellor.username} (ID: {test_counsellor.id})")
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"\n❌ Error creating test users: {e}"))
            return
        
        # Test 1: Create Chat and verify all fields
        self.stdout.write("\n" + "=" * 80)
        self.stdout.write(self.style.SUCCESS("TEST 1: Creating Chat"))
        self.stdout.write("=" * 80)
        
        try:
            with transaction.atomic():
                test_chat = Chat.objects.create(
                    user=test_user,
                    counsellor=test_counsellor,
                    status='active',
                    initial_message='Test initial message',
                    started_at=timezone.now()
                )
                
                # Verify all fields were saved
                self.stdout.write(f"\n✅ Chat created with ID: {test_chat.id}")
                self.stdout.write(f"   user_id: {test_chat.user_id} (expected: {test_user.id})")
                self.stdout.write(f"   counsellor_id: {test_chat.counsellor_id} (expected: {test_counsellor.id})")
                self.stdout.write(f"   status: '{test_chat.status}' (expected: 'active')")
                self.stdout.write(f"   initial_message: '{test_chat.initial_message}'")
                self.stdout.write(f"   created_at: {test_chat.created_at}")
                self.stdout.write(f"   started_at: {test_chat.started_at}")
                self.stdout.write(f"   updated_at: {test_chat.updated_at}")
                
                # Verify all fields match
                all_correct = (
                    test_chat.user_id == test_user.id and
                    test_chat.counsellor_id == test_counsellor.id and
                    test_chat.status == 'active' and
                    test_chat.initial_message == 'Test initial message' and
                    test_chat.created_at is not None and
                    test_chat.started_at is not None and
                    test_chat.updated_at is not None
                )
                
                if all_correct:
                    self.stdout.write(self.style.SUCCESS("\n✅ ALL Chat fields saved correctly!"))
                else:
                    self.stdout.write(self.style.ERROR("\n❌ Some Chat fields NOT saved correctly!"))
                
                # Test 2: Create ChatMessage and verify all fields
                self.stdout.write("\n" + "=" * 80)
                self.stdout.write(self.style.SUCCESS("TEST 2: Creating ChatMessage"))
                self.stdout.write("=" * 80)
                
                test_message_text = "This is a test message to verify saving"
                test_message = ChatMessage.objects.create(
                    chat=test_chat,
                    sender=test_user,
                    text=test_message_text
                )
                
                # Verify all fields were saved
                self.stdout.write(f"\n✅ ChatMessage created with ID: {test_message.id}")
                self.stdout.write(f"   chat_id: {test_message.chat_id} (expected: {test_chat.id})")
                self.stdout.write(f"   sender_id: {test_message.sender_id} (expected: {test_user.id})")
                self.stdout.write(f"   text: '{test_message.text}' (expected: '{test_message_text}')")
                self.stdout.write(f"   created_at: {test_message.created_at}")
                
                # Verify all fields match
                all_correct_msg = (
                    test_message.chat_id == test_chat.id and
                    test_message.sender_id == test_user.id and
                    test_message.text == test_message_text and
                    test_message.created_at is not None
                )
                
                if all_correct_msg:
                    self.stdout.write(self.style.SUCCESS("\n✅ ALL ChatMessage fields saved correctly!"))
                else:
                    self.stdout.write(self.style.ERROR("\n❌ Some ChatMessage fields NOT saved correctly!"))
                
                # Test 3: Verify message can be retrieved
                self.stdout.write("\n" + "=" * 80)
                self.stdout.write(self.style.SUCCESS("TEST 3: Retrieving saved message"))
                self.stdout.write("=" * 80)
                
                retrieved_message = ChatMessage.objects.get(id=test_message.id)
                self.stdout.write(f"\n✅ Message retrieved from database:")
                self.stdout.write(f"   ID: {retrieved_message.id}")
                self.stdout.write(f"   Chat ID: {retrieved_message.chat_id}")
                self.stdout.write(f"   Sender: {retrieved_message.sender.username}")
                self.stdout.write(f"   Text: {retrieved_message.text}")
                self.stdout.write(f"   Created: {retrieved_message.created_at}")
                
                # Test 4: Count messages in chat
                message_count = ChatMessage.objects.filter(chat=test_chat).count()
                self.stdout.write(f"\n✅ Total messages in chat: {message_count} (expected: 1)")
                
                if message_count == 1:
                    self.stdout.write(self.style.SUCCESS("\n✅ Message count correct!"))
                else:
                    self.stdout.write(self.style.ERROR(f"\n❌ Message count incorrect! Expected 1, got {message_count}"))
                
                # Test 5: Test saving multiple messages
                self.stdout.write("\n" + "=" * 80)
                self.stdout.write(self.style.SUCCESS("TEST 4: Saving multiple messages"))
                self.stdout.write("=" * 80)
                
                messages_to_create = [
                    ("Message 1 from user", test_user),
                    ("Message 2 from counsellor", test_counsellor),
                    ("Message 3 from user", test_user),
                ]
                
                created_ids = []
                for msg_text, sender in messages_to_create:
                    msg = ChatMessage.objects.create(
                        chat=test_chat,
                        sender=sender,
                        text=msg_text
                    )
                    created_ids.append(msg.id)
                    self.stdout.write(f"   Created message ID {msg.id}: '{msg_text}' from {sender.username}")
                
                final_count = ChatMessage.objects.filter(chat=test_chat).count()
                self.stdout.write(f"\n✅ Total messages after adding 3 more: {final_count} (expected: 4)")
                
                if final_count == 4:
                    self.stdout.write(self.style.SUCCESS("\n✅ Multiple messages saved correctly!"))
                else:
                    self.stdout.write(self.style.ERROR(f"\n❌ Message count incorrect! Expected 4, got {final_count}"))
                
                # Cleanup
                self.stdout.write("\n" + "=" * 80)
                self.stdout.write(self.style.SUCCESS("CLEANUP"))
                self.stdout.write("=" * 80)
                
                # Delete test data
                ChatMessage.objects.filter(chat=test_chat).delete()
                test_chat.delete()
                
                self.stdout.write("\n✅ Test data cleaned up")
                
                self.stdout.write("\n" + "=" * 80)
                self.stdout.write(self.style.SUCCESS("✅ ALL TESTS COMPLETED!"))
                self.stdout.write("=" * 80)
                self.stdout.write("\nIf all tests passed, the models ARE saving correctly.")
                self.stdout.write("If messages aren't appearing in your app, check:")
                self.stdout.write("  1. Are messages being sent via WebSocket or API?")
                self.stdout.write("  2. Check backend logs for 'SAVING MESSAGE' and 'MESSAGE SAVED SUCCESSFULLY'")
                self.stdout.write("  3. Check if there are any errors in the save_message() method")
                self.stdout.write("  4. Verify the chat exists and is active when saving messages\n")
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"\n❌ ERROR during test: {e}"))
            import traceback
            self.stdout.write(traceback.format_exc())

