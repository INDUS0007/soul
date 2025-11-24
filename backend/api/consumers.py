"""
WebSocket consumers for real-time chat functionality.
"""
import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import User
from .models import Chat, ChatMessage

logger = logging.getLogger(__name__)


class ChatConsumer(AsyncWebsocketConsumer):
    """WebSocket consumer for real-time chat messaging."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.chat = None  # Cache chat object to avoid repeated queries

    async def connect(self):
        """Handle WebSocket connection."""
        self.chat_id = self.scope["url_route"]["kwargs"]["chat_id"]
        self.room_group_name = f"chat_{self.chat_id}"
        self.user = self.scope["user"]
        
        # Extract token from query string for debugging
        query_string = self.scope.get("query_string", b"").decode()
        token_present = "token=" in query_string
        client_info = self.scope.get("client", ["unknown"])[0] if self.scope.get("client") else "unknown"

        logger.info("WS CONNECT attempt: chat_id=%s, user=%s, token_present=%s, remote=%s, channel=%s",
                    self.chat_id, self.user.username if self.user.is_authenticated else "anonymous",
                    token_present, client_info, self.channel_name)

        # Check if user is authenticated
        if not self.user.is_authenticated:
            logger.warning("WS CONNECT rejected: user not authenticated (chat_id=%s)", self.chat_id)
            await self.close()
            return

        # Verify user has access to this chat and cache chat object
        chat_data = await self.get_chat_and_check_access(self.user, self.chat_id)
        if not chat_data:
            logger.warning("WS CONNECT rejected: no access to chat %s for user %s", self.chat_id, self.user.username)
            await self.close()
            return

        self.chat, self._cached_is_user_sender = chat_data

        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        # If user is a counselor, also join the counselor_queue group for real-time updates
        is_counselor = await self.is_counselor(self.user)
        if is_counselor:
            await self.channel_layer.group_add(
                "counselor_queue",
                self.channel_name
            )
            logger.info("WS CONNECT: Counselor %s joined counselor_queue group", self.user.username)

        await self.accept()
        
        logger.info("WS CONNECT success: Joined group %s as channel %s (user=%s, is_user_sender=%s)",
                    self.room_group_name, self.channel_name, self.user.username, self._cached_is_user_sender)

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        
        # Also leave counselor_queue if counselor
        if hasattr(self, 'user') and self.user.is_authenticated:
            is_counselor = await self.is_counselor(self.user)
            if is_counselor:
                await self.channel_layer.group_discard(
                    "counselor_queue",
                    self.channel_name
                )
        
        logger.info("WS DISCONNECT: Left group %s channel %s (close_code=%s, user=%s)",
                    self.room_group_name, self.channel_name, close_code,
                    self.user.username if hasattr(self, 'user') and self.user.is_authenticated else "unknown")
        self.chat = None  # Clear cache

    async def receive(self, text_data):
        """Handle message received from WebSocket."""
        logger.info("WS RECEIVE: chat_id=%s, channel=%s, user=%s, raw_text=%s",
                    self.chat_id, self.channel_name, self.user.username, text_data[:100])
        try:
            data = json.loads(text_data)
            message_text = data.get("message", "").strip()
            client_message_id = data.get("client_message_id")  # Extract client_message_id

            if not message_text:
                logger.debug("WS RECEIVE: Empty message, ignoring")
                return

            # Validate message length
            if len(message_text) > 5000:
                await self.send(text_data=json.dumps({
                    "error": "Message too long. Maximum 5000 characters."
                }))
                return

            # Validate chat exists and user has access
            if not self.chat:
                logger.warning(f"Chat cache lost for chat {self.chat_id}, reloading...")
                chat_data = await self.get_chat_and_check_access(self.user, self.chat_id)
                if not chat_data:
                    await self.send(text_data=json.dumps({
                        "error": "Chat not found or access denied"
                    }))
                    return
                self.chat, self._cached_is_user_sender = chat_data

            # Save message to database (with deduplication) and check if chat was activated
            try:
                result = await self.save_message(message_text, client_message_id=client_message_id)
                
                # Handle duplicate message
                if result is None:
                    logger.info("WS RECEIVE: Duplicate message detected, ignoring (client_msg_id=%s)", client_message_id)
                    # Send ACK for duplicate (client already has it optimistically)
                    await self.send(text_data=json.dumps({
                        "type": "ack",
                        "status": "duplicate",
                        "client_message_id": client_message_id,
                        "message_id": None  # No new message created
                    }))
                    return
                
                message_obj, chat_was_activated = result
                logger.info(
                    "WS RECEIVE: Message saved to DB (id=%s, chat_id=%s, client_msg_id=%s, chat_activated=%s)",
                    message_obj.id, self.chat_id, client_message_id, chat_was_activated
                )
            except ValueError as e:
                # Handle chat expiration error specifically
                error_msg = str(e)
                logger.warning(f"Chat {self.chat_id} expired: {error_msg}")
                await self.send(text_data=json.dumps({
                    "error": error_msg,
                    "chat_expired": True
                }))
                return
            except Exception as e:
                logger.error(f"Failed to save message for chat {self.chat_id}: {e}", exc_info=True)
                await self.send(text_data=json.dumps({
                    "error": "Failed to save message. Please try again."
                }))
                return

            # Determine if sender is the user (not counsellor) - recalculate to ensure accuracy
            # Use the method directly (it's properly defined with @database_sync_to_async)
            # The cached value is stored in _cached_is_user_sender to avoid conflicts
            try:
                # Get the method using getattr to avoid any attribute resolution issues
                method = getattr(self, 'is_user_sender', None)
                if method and callable(method):
                    is_user_sender = await method(self.chat_id, self.user.id)
                else:
                    # Method not available or not callable, use cached value
                    logger.warning(f"is_user_sender method not callable for chat {self.chat_id}, using cached value")
                    is_user_sender = self._cached_is_user_sender if hasattr(self, '_cached_is_user_sender') else False
            except TypeError as e:
                # This happens if is_user_sender is a boolean instead of a method (old code issue)
                logger.warning(f"TypeError calling is_user_sender for chat {self.chat_id}: {e}. Using cached value.")
                is_user_sender = self._cached_is_user_sender if hasattr(self, '_cached_is_user_sender') else False
            except Exception as e:
                logger.error(f"Failed to determine sender type for chat {self.chat_id}: {e}", exc_info=True)
                # Fallback to cached value
                is_user_sender = self._cached_is_user_sender if hasattr(self, '_cached_is_user_sender') else False

            # Log message broadcast for debugging
            logger.info("WS BROADCAST: chat_id=%s, group=%s, sender=%s, is_user=%s, text=%s",
                        self.chat_id, self.room_group_name, self.user.username, is_user_sender, message_text[:50])

            # Send ACK to sender first (before broadcasting)
            if client_message_id:
                try:
                    await self.send(text_data=json.dumps({
                        "type": "ack",
                        "status": "sent",
                        "client_message_id": client_message_id,
                        "message_id": message_obj.id,
                    }))
                    logger.info("WS ACK: Sent ACK for client_message_id=%s, message_id=%s", 
                                client_message_id, message_obj.id)
                except Exception as e:
                    logger.error(f"Failed to send ACK for chat {self.chat_id}: {e}", exc_info=True)
            
            # Send message to room group (broadcast to all connected clients)
            try:
                payload = {
                    "type": "chat_message",
                    "message": message_text,
                    "sender_id": self.user.id,
                    "sender_username": self.user.username,
                    "is_user": is_user_sender,
                    "timestamp": message_obj.created_at.isoformat(),
                    "message_id": message_obj.id,
                }
                if client_message_id:
                    payload["client_message_id"] = client_message_id
                
                await self.channel_layer.group_send(self.room_group_name, payload)
                logger.info("WS BROADCAST: Successfully sent to group %s (payload keys: %s)",
                            self.room_group_name, list(payload.keys()))
            except Exception as e:
                logger.error(f"Failed to broadcast message in chat {self.chat_id}: {e}", exc_info=True)
                await self.send(text_data=json.dumps({
                    "error": "Failed to send message to other participants"
                }))
                return
            
            # If chat was just activated (queued -> active), notify counselors via counselor_queue
            if chat_was_activated:
                try:
                    # Reload chat to get latest data including assigned counselor
                    chat_data = await self.get_chat_and_check_access(self.user, self.chat_id)
                    if chat_data:
                        chat_obj, _ = chat_data
                        await self.channel_layer.group_send(
                            "counselor_queue",
                            {
                                "type": "chat.status_change",
                                "chat_id": int(self.chat_id),
                                "new_status": "active",
                                "user_id": chat_obj.user.id,
                                "user_username": chat_obj.user.username,
                                "counsellor_id": chat_obj.counsellor.id if chat_obj.counsellor else None,
                            }
                        )
                        logger.info(
                            "WS BROADCAST: Chat status update sent to counselor_queue: chat_id=%s, status=active",
                            self.chat_id
                        )
                except Exception as e:
                    logger.error(f"Failed to broadcast chat status update for chat {self.chat_id}: {e}", exc_info=True)
                
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in WebSocket message: {e}")
            await self.send(text_data=json.dumps({
                "error": "Invalid message format"
            }))
        except Exception as e:
            logger.error(f"Error processing message in chat {self.chat_id}: {e}", exc_info=True)
            await self.send(text_data=json.dumps({
                "error": f"Failed to process message: {str(e)}"
            }))

    async def chat_message(self, event):
        """Send message to WebSocket."""
        # Log message delivery for debugging
        # Note: If same user has multiple connections (multiple tabs/windows), 
        # they will receive the message on each connection - this is expected behavior
        logger.info("WS DELIVER: chat_id=%s, channel=%s, user=%s, is_user=%s, message=%s",
                    self.chat_id, self.channel_name, self.user.username,
                    event.get('is_user'), event.get('message', '')[:50])
        payload = {
            "type": "message",
            "message": event["message"],
            "sender_id": event["sender_id"],
            "sender_username": event["sender_username"],
            "is_user": event["is_user"],
            "timestamp": event["timestamp"],
            "message_id": event.get("message_id"),
        }
        if "client_message_id" in event:
            payload["client_message_id"] = event["client_message_id"]
        await self.send(text_data=json.dumps(payload))
        logger.debug("WS DELIVER: Sent payload to channel %s (user may have multiple connections)", self.channel_name)
    
    async def chat_status_change(self, event):
        """Handler to deliver chat status updates to counselors."""
        # This will be received by counselor clients listening on counselor_queue
        payload = {
            "type": "chat_status_update",
            "chat_id": event["chat_id"],
            "new_status": event["new_status"],
            "user_id": event.get("user_id"),
            "user_username": event.get("user_username"),
            "counsellor_id": event.get("counsellor_id"),
        }
        await self.send(text_data=json.dumps(payload))
        logger.info(
            "WS DELIVER: Chat status update sent to counselor channel %s: chat_id=%s, status=%s",
            self.channel_name, event["chat_id"], event["new_status"]
        )

    @database_sync_to_async
    def get_chat_and_check_access(self, user, chat_id):
        """
        Get chat object and check access in a single query.
        Returns (chat, is_user_sender) tuple or None if no access.
        """
        try:
            chat = Chat.objects.select_related('user', 'counsellor').get(id=chat_id)
            
            # Log access check
            logger.info(
                f"get_chat_and_check_access: chat_id={chat_id}, "
                f"user={user.username} (id={user.id}), "
                f"chat_user={chat.user.username} (id={chat.user.id}), "
                f"chat_counsellor={chat.counsellor.username if chat.counsellor else None} "
                f"(id={chat.counsellor_id if chat.counsellor else None}), "
                f"chat_status={chat.status}"
            )
            
            # User can access if they are the chat user or the assigned counsellor
            is_chat_user = chat.user == user
            is_chat_counsellor = chat.counsellor is not None and chat.counsellor == user
            has_access = is_chat_user or is_chat_counsellor
            
            if not has_access:
                logger.warning(
                    f"Access denied: user {user.username} (id={user.id}) not authorized for chat {chat_id}. "
                    f"Chat user: {chat.user.username} (id={chat.user.id}), "
                    f"Chat counsellor: {chat.counsellor.username if chat.counsellor else None} "
                    f"(id={chat.counsellor_id if chat.counsellor else None})"
                )
                return None
            
            # Determine if sender is the user (not counsellor)
            is_user_sender = is_chat_user
            
            logger.info(
                f"Access granted: user {user.username} (id={user.id}) has access to chat {chat_id}. "
                f"is_user_sender={is_user_sender}"
            )
            return (chat, is_user_sender)
        except Chat.DoesNotExist:
            logger.error(f"get_chat_and_check_access: Chat {chat_id} not found in database")
            return None
        except Exception as e:
            logger.error(f"get_chat_and_check_access: Error checking access for chat {chat_id}: {e}", exc_info=True)
            return None

    @database_sync_to_async
    def save_message(self, text, client_message_id=None):
        """Save message to database using atomic transaction with select_for_update.
        Automatically activates queued chats when user sends message.
        Returns (message_obj, chat_was_activated) tuple or None if duplicate."""
        from django.db import transaction
        from django.utils import timezone
        from datetime import timedelta
        
        try:
            with transaction.atomic():
                # Use select_for_update to lock the chat row and prevent race conditions
                chat = Chat.objects.select_for_update().get(id=self.chat_id)
                
                # Check for duplicate using client_message_id
                if client_message_id:
                    existing = ChatMessage.objects.filter(
                        chat=chat,
                        sender=self.user,
                        client_message_id=client_message_id
                    ).first()
                    
                    if existing:
                        logger.info(
                            f"DUPLICATE MESSAGE DETECTED: client_message_id={client_message_id}, "
                            f"existing_message_id={existing.id}, chat_id={self.chat_id}, sender={self.user.username}"
                        )
                        return None  # Return None to indicate duplicate
                
                # Fallback deduplication: same sender + text within 2 seconds
                if not client_message_id:
                    recent_duplicate = ChatMessage.objects.filter(
                        chat=chat,
                        sender=self.user,
                        text=text,
                        created_at__gte=timezone.now() - timedelta(seconds=2)
                    ).first()
                    
                    if recent_duplicate:
                        logger.info(
                            f"DUPLICATE MESSAGE DETECTED (fallback): same text within 2s, "
                            f"existing_message_id={recent_duplicate.id}, chat_id={self.chat_id}, sender={self.user.username}"
                        )
                        return None
                
                # Determine if sender is the user (not counselor)
                is_user_sender = chat.user == self.user
                chat_was_activated = False
                now = timezone.now()
                
                # IMPORTANT: Only user interaction should activate/reactivate chats
                # Counselor interaction should NOT activate chats
                if is_user_sender:
                    previous_activity = chat.last_user_activity
                    # Update last_user_activity whenever user sends a message
                    chat.last_user_activity = now
                    
                    # Check if user was inactive for > 5 minutes before sending this message
                    # This handles the case where user was inactive and is now sending a message
                    if previous_activity and chat.status in ['active', 'inactive']:
                        five_minutes_ago = now - timedelta(minutes=5)
                        if previous_activity < five_minutes_ago:
                            # User was inactive for > 5 minutes, log it
                            minutes_inactive = (now - previous_activity).total_seconds() / 60
                            logger.info(
                                f"USER RETURNED AFTER INACTIVITY: chat_id={self.chat_id}, "
                                f"was_inactive_for={minutes_inactive:.1f} minutes, "
                                f"previous_status={chat.status}"
                            )
                            # If chat was inactive, reactivate it now that user sent a message
                            if chat.status == 'inactive':
                                chat.status = 'active'
                                chat.ended_at = None  # Clear ended_at since chat is active again
                                logger.info(f"Chat {self.chat_id} reactivated from inactive status (user sent message)")
                    
                    # Check if chat is active but user has been inactive for > 1 hour
                    # Auto-disconnect inactive chats (long-term cleanup)
                    if chat.status == 'active' and chat.last_user_activity:
                        one_hour_ago = now - timedelta(hours=1)
                        if chat.last_user_activity < one_hour_ago:
                            # User was inactive for > 1 hour, auto-disconnect
                            logger.info(
                                f"AUTO-DISCONNECTING INACTIVE CHAT (1 hour): chat_id={self.chat_id}, "
                                f"last_user_activity={chat.last_user_activity}, "
                                f"hours_inactive={(now - chat.last_user_activity).total_seconds() / 3600:.2f}"
                            )
                            chat.status = 'completed'
                            if not chat.ended_at:
                                chat.ended_at = now
                            # Ensure started_at is set if not already set (for billing)
                            if not chat.started_at:
                                chat.started_at = chat.created_at or now
                            chat.save(update_fields=['status', 'ended_at', 'started_at', 'last_user_activity', 'updated_at'])
                            logger.info(f"Chat {self.chat_id} auto-disconnected due to 1 hour inactivity")
                    
                    # Auto-activate chat if it's queued, completed, inactive, or cancelled (ONLY for user)
                    if chat.status in ['queued', 'completed', 'inactive', 'cancelled']:
                        old_status = chat.status
                        
                        # Check wallet balance before activating chat (for user) - log warning if low
                        if old_status == 'queued':
                            from .utils.billing import check_chat_wallet_balance
                            has_balance, balance_message, current_balance = check_chat_wallet_balance(chat.user)
                            if not has_balance:
                                logger.warning(
                                    f"LOW WALLET BALANCE when activating chat: chat_id={self.chat_id}, "
                                    f"user={chat.user.username}, balance=₹{current_balance}. "
                                    f"Chat will be billed when it ends."
                                )
                                # Still allow activation - billing will be handled when chat ends
                                # If insufficient balance at that time, it will be logged
                        
                        logger.info(
                            f"ACTIVATING CHAT: chat_id={self.chat_id}, current_status={old_status}, "
                            f"activated_by={self.user.username} (USER)"
                        )
                        
                        # If chat is queued and user is sending, assign to first available counselor if not assigned
                        if old_status == 'queued':
                            # Check if chat needs a counselor assigned
                            if not chat.counsellor:
                                # Try to auto-assign to first available counselor
                                from django.contrib.auth import get_user_model
                                User = get_user_model()
                                available_counselor = User.objects.filter(
                                    counsellorprofile__isnull=False
                                ).first()
                                
                                if available_counselor:
                                    chat.counsellor = available_counselor
                                    logger.info(
                                        f"AUTO-ASSIGNED COUNSELOR: chat_id={self.chat_id}, "
                                        f"counselor={available_counselor.username} (id={available_counselor.id})"
                                    )
                            
                            chat_was_activated = True
                            # Set started_at if not already set
                            if not chat.started_at:
                                chat.started_at = now
                        
                        # For completed/inactive/cancelled chats, check if they can be reopened
                        # Allow reopening if user is sending a message (user wants to continue)
                        if old_status in ['completed', 'inactive', 'cancelled']:
                            # Always allow reopening if user is sending a message
                            # This means user wants to continue the conversation
                            chat_was_activated = True
                            logger.info(
                                f"REOPENING CHAT: chat_id={self.chat_id}, "
                                f"old_status={old_status}, ended_at={chat.ended_at}"
                            )
                            
                            # Notify counselor that user wants to continue chat
                            # This will be handled via counselor_queue group broadcast
                        
                        chat.status = 'active'
                        chat.ended_at = None  # Clear ended_at since chat is active again
                        
                        # Update fields list
                        update_fields = ['status', 'ended_at', 'last_user_activity', 'updated_at']
                        if old_status == 'queued' and chat.counsellor:
                            update_fields.append('counsellor')
                        if old_status == 'queued' and chat.started_at:
                            update_fields.append('started_at')
                        
                        chat.save(update_fields=update_fields)
                        
                        # Auto-start associated UpcomingSession if chat becomes active
                        if chat_was_activated and chat.counsellor:
                            try:
                                from .models import UpcomingSession
                                # Find associated session (scheduled session for this user-counselor pair)
                                session = UpcomingSession.objects.filter(
                                    user=chat.user,
                                    counsellor=chat.counsellor,
                                    session_status='scheduled'
                                ).order_by('-start_time').first()
                                
                                if session and not session.actual_start_time:
                                    # Auto-start the session
                                    session.actual_start_time = now
                                    session.session_status = 'in_progress'
                                    session.is_confirmed = True
                                    session.save()
                                    
                                    logger.info(
                                        f"AUTO-STARTED SESSION: session_id={session.id}, "
                                        f"chat_id={self.chat_id}, started_at={now}"
                                    )
                            except Exception as e:
                                logger.error(f"Error auto-starting session for chat {self.chat_id}: {e}", exc_info=True)
                        
                        logger.info(
                            f"Chat {self.chat_id} activated from {old_status} to active status. "
                            f"Counsellor: {chat.counsellor.username if chat.counsellor else 'None'}"
                        )
                else:
                    # Counselor is sending message - do NOT activate chat
                    # But check if user has been inactive for 5+ minutes and mark chat as inactive
                    logger.info(
                        f"COUNSELOR MESSAGE: chat_id={self.chat_id}, "
                        f"counselor={self.user.username}, status={chat.status}"
                    )
                    
                    # Check if user has been inactive for 5+ minutes
                    if chat.status == 'active' and chat.last_user_activity:
                        five_minutes_ago = now - timedelta(minutes=5)
                        if chat.last_user_activity < five_minutes_ago:
                            # User has been inactive for > 5 minutes, mark chat as inactive
                            minutes_inactive = (now - chat.last_user_activity).total_seconds() / 60
                            logger.info(
                                f"AUTO-INACTIVATING CHAT (from counselor message): chat_id={self.chat_id}, "
                                f"last_user_activity={chat.last_user_activity}, "
                                f"minutes_inactive={minutes_inactive:.1f}"
                            )
                            chat.status = 'inactive'
                            if not chat.ended_at:
                                chat.ended_at = chat.last_user_activity + timedelta(minutes=5)
                            # Ensure started_at is set if not already set (for billing)
                            if not chat.started_at:
                                chat.started_at = chat.created_at or timezone.now()
                            chat.save(update_fields=['status', 'ended_at', 'started_at', 'updated_at'])
                            logger.info(f"Chat {self.chat_id} auto-inactivated due to 5 minutes user inactivity")
                    
                    # Don't change chat status or activate it for counselor messages
                
                # Create and save the message
                logger.info(
                    f"SAVING MESSAGE: chat_id={self.chat_id}, sender={self.user.username} (id={self.user.id}), "
                    f"text_length={len(text)}, client_message_id={client_message_id}"
                )
                
                message = ChatMessage.objects.create(
                    chat=chat,
                    sender=self.user,
                    text=text,
                    client_message_id=client_message_id
                )
                
                # Update cached chat object
                self.chat = chat
                
                # Verify it was saved
                saved_message = ChatMessage.objects.get(id=message.id)
                logger.info(
                    f"MESSAGE SAVED SUCCESSFULLY: message_id={saved_message.id}, chat_id={saved_message.chat_id}, "
                    f"created_at={saved_message.created_at}, client_message_id={saved_message.client_message_id}"
                )
                
                # Count total messages for this chat
                total_messages = ChatMessage.objects.filter(chat=chat).count()
                logger.info(f"Total messages in chat {self.chat_id}: {total_messages}")
                
                # Return message and whether chat was activated
                return (saved_message, chat_was_activated)
        except Exception as e:
            logger.error(f"ERROR SAVING MESSAGE: chat_id={self.chat_id}, error={e}", exc_info=True)
            raise
    
    @database_sync_to_async
    def is_counselor(self, user):
        """Check if user is a counselor."""
        return hasattr(user, 'counsellorprofile')

    @database_sync_to_async
    def is_user_sender(self, chat_id, sender_id):
        """Check if sender is the chat user (not counsellor)."""
        try:
            chat = Chat.objects.get(id=chat_id)
            sender = User.objects.get(id=sender_id)
            return chat.user == sender
        except (Chat.DoesNotExist, User.DoesNotExist):
            return False

