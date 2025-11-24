"""
Django management command to list all users.
Usage: python manage.py list_users
"""

from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from api.models import CounsellorProfile, DoctorProfile


class Command(BaseCommand):
    help = 'List all users in the database'

    def add_arguments(self, parser):
        parser.add_argument(
            '--type',
            type=str,
            choices=['all', 'regular', 'counselor', 'doctor'],
            default='all',
            help='Type of users to list (default: all)'
        )

    def handle(self, *args, **options):
        user_type = options['type']
        
        if user_type == 'all':
            users = User.objects.all().order_by('id')
        elif user_type == 'regular':
            # Users who are not counselors or doctors
            counselor_ids = CounsellorProfile.objects.values_list('user_id', flat=True)
            doctor_ids = DoctorProfile.objects.values_list('user_id', flat=True)
            users = User.objects.exclude(
                id__in=list(counselor_ids) + list(doctor_ids)
            ).order_by('id')
        elif user_type == 'counselor':
            counselor_ids = CounsellorProfile.objects.values_list('user_id', flat=True)
            users = User.objects.filter(id__in=counselor_ids).order_by('id')
        elif user_type == 'doctor':
            doctor_ids = DoctorProfile.objects.values_list('user_id', flat=True)
            users = User.objects.filter(id__in=doctor_ids).order_by('id')
        
        self.stdout.write(self.style.WARNING(f"\n{'='*80}"))
        self.stdout.write(self.style.WARNING(f"Users ({user_type}): {users.count()}"))
        self.stdout.write(self.style.WARNING(f"{'='*80}\n"))
        
        for user in users:
            is_counselor = hasattr(user, 'counsellorprofile')
            is_doctor = hasattr(user, 'doctorprofile')
            user_type_str = []
            if is_counselor:
                user_type_str.append('Counselor')
            if is_doctor:
                user_type_str.append('Doctor')
            if not user_type_str:
                user_type_str.append('Regular User')
            
            self.stdout.write(
                f"ID: {user.id:3d} | "
                f"Username: {user.username:20s} | "
                f"Email: {user.email:30s} | "
                f"Type: {', '.join(user_type_str)}"
            )
        
        self.stdout.write(f"\n{'='*80}\n")

