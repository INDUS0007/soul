"""
Django management command to check and deactivate chats with inactive users.

This command should be run periodically (e.g., every minute via cron or task scheduler)
to automatically mark chats as inactive if user hasn't sent a message in 5 minutes.

Usage:
    python manage.py check_inactive_chats
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from api.models import Chat
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Check and deactivate chats where user has been inactive for 5 minutes'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be done without actually changing anything',
        )

    def handle(self, *args, **options):
        now = timezone.now()
        five_minutes_ago = now - timedelta(minutes=5)
        
        # Find all active chats where user hasn't sent a message in 5 minutes
        inactive_chats = Chat.objects.filter(
            status=Chat.STATUS_ACTIVE,
            last_user_activity__lt=five_minutes_ago
        ).exclude(
            last_user_activity__isnull=True
        ).select_related('user', 'counsellor')
        
        count = 0
        dry_run = options.get('dry_run', False)
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING('DRY RUN MODE - No changes will be made')
            )
        
        for chat in inactive_chats:
            minutes_inactive = (now - chat.last_user_activity).total_seconds() / 60
            
            self.stdout.write(
                self.style.WARNING(
                    f"{'[DRY RUN] Would deactivate' if dry_run else 'Deactivating'} "
                    f"chat {chat.id}: User '{chat.user.username}' inactive for {minutes_inactive:.1f} minutes "
                    f"(last activity: {chat.last_user_activity})"
                )
            )
            
            if not dry_run:
                try:
                    chat.mark_inactive()
                    logger.info(
                        f"AUTO-INACTIVATED CHAT {chat.id}: User '{chat.user.username}' "
                        f"inactive for {minutes_inactive:.1f} minutes, "
                        f"last_user_activity={chat.last_user_activity}"
                    )
                    count += 1
                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(
                            f"Error deactivating chat {chat.id}: {e}"
                        )
                    )
                    logger.error(
                        f"Error deactivating chat {chat.id}: {e}",
                        exc_info=True
                    )
            else:
                count += 1
        
        total_found = inactive_chats.count()
        
        if count > 0:
            action = "Would deactivate" if dry_run else "Successfully deactivated"
            self.stdout.write(
                self.style.SUCCESS(f'{action} {count} inactive chat(s)')
            )
        else:
            self.stdout.write(self.style.SUCCESS('No inactive chats found'))
        
        if total_found > 0:
            self.stdout.write(
                self.style.NOTICE(
                    f'Found {total_found} active chat(s) with user inactive for 5+ minutes'
                )
            )
        
        return f"Checked chats, {'would deactivate' if dry_run else 'deactivated'} {count} inactive chat(s)"

