# from django.core.management.base import BaseCommand
# from django.contrib.auth.models import User
# from api.models import CounsellorProfile


# class Command(BaseCommand):
#     help = 'Creates a test counsellor user for login'

#     def add_arguments(self, parser):
#         parser.add_argument(
#             '--username',
#             type=str,
#             default='counsellor',
#             help='Username for the counsellor (default: counsellor)',
#         )
#         parser.add_argument(
#             '--email',
#             type=str,
#             default='counsellor@example.com',
#             help='Email for the counsellor (default: counsellor@example.com)',
#         )
#         parser.add_argument(
#             '--password',
#             type=str,
#             default='counsellor123',
#             help='Password for the counsellor (default: counsellor123)',
#         )

#     def handle(self, *args, **options):
#         username = options['username']
#         email = options['email']
#         password = options['password']

#         # Check if user already exists
#         if User.objects.filter(username=username).exists():
#             self.stdout.write(
#                 self.style.WARNING(f'User "{username}" already exists.')
#             )
#             user = User.objects.get(username=username)
            
#             # Ensure user is active
#             if not user.is_active:
#                 user.is_active = True
#                 user.save()
#                 self.stdout.write(
#                     self.style.SUCCESS(f'Activated user "{username}".')
#                 )
            
#             # Check if counsellor profile exists
#             if hasattr(user, 'counsellorprofile'):
#                 self.stdout.write(
#                     self.style.SUCCESS(
#                         f'Counsellor user "{username}" already exists with profile.'
#                     )
#                 )
#                 self.stdout.write(f'Username: {username}')
#                 self.stdout.write(f'Email: {user.email}')
#                 self.stdout.write(f'is_active: {user.is_active}')
#                 self.stdout.write(f'Password: (use existing password or reset it)')
#             else:
#                 # Create counsellor profile for existing user
#                 CounsellorProfile.objects.create(
#                     user=user,
#                     specialization='Mental Health',
#                     is_available=True
#                 )
#                 self.stdout.write(
#                     self.style.SUCCESS(
#                         f'Created counsellor profile for existing user "{username}".'
#                     )
#                 )
#                 self.stdout.write(f'Username: {username}')
#                 self.stdout.write(f'Email: {user.email}')
#                 self.stdout.write(f'is_active: {user.is_active}')
#                 self.stdout.write(f'Password: (use existing password)')
#         else:
#             # Create new user with is_active=True
#             user = User.objects.create_user(
#                 username=username,
#                 email=email,
#                 password=password,
#                 is_active=True  # Explicitly set to active
#             )
            
#             # Create counsellor profile
#             CounsellorProfile.objects.create(
#                 user=user,
#                 specialization='Mental Health',
#                 is_available=True
#             )
            
#             self.stdout.write(
#                 self.style.SUCCESS(
#                     f'Successfully created counsellor user "{username}".'
#                 )
#             )
#             self.stdout.write(f'Username: {username}')
#             self.stdout.write(f'Email: {email}')
#             self.stdout.write(f'is_active: {user.is_active}')
#             self.stdout.write(f'Password: {password}')

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
from api.models import CounsellorProfile


class Command(BaseCommand):
    help = 'Creates a test counsellor user for login'

    def add_arguments(self, parser):
        parser.add_argument(
            '--username',
            type=str,
            default='counsellor',
            help='Username for the counsellor (default: counsellor)',
        )
        parser.add_argument(
            '--email',
            type=str,
            default='counsellor@example.com',
            help='Email for the counsellor (default: counsellor@example.com)',
        )
        parser.add_argument(
            '--password',
            type=str,
            default='counsellor123',
            help='Password for the counsellor (default: counsellor123)',
        )
        parser.add_argument(
            '--specialization',
            type=str,
            default='Mental Health',
            help='Area of specialization (default: Mental Health)',
        )
        parser.add_argument(
            '--experience',
            type=int,
            default=0,
            help='Years of experience (default: 0)',
        )
        parser.add_argument(
            '--languages',
            type=str,
            default='English',
            help='Comma-separated languages (default: English)',
        )
        parser.add_argument(
            '--bio',
            type=str,
            default='',
            help='Counsellor bio (optional)',
        )

    def handle(self, *args, **options):
        username = options['username']
        email = options['email']
        password = options['password']
        specialization = options['specialization']
        experience = options['experience']
        languages = [lang.strip() for lang in options['languages'].split(',')]
        bio = options['bio']

        # Check if user already exists
        if User.objects.filter(username=username).exists():
            self.stdout.write(
                self.style.WARNING(f'User "{username}" already exists.')
            )
            user = User.objects.get(username=username)
            
            # Ensure user is active
            if not user.is_active:
                user.is_active = True
                user.save()
                self.stdout.write(
                    self.style.SUCCESS(f'Activated user "{username}".')
                )
            
            # Check if counsellor profile exists
            if hasattr(user, 'counsellorprofile'):
                self.stdout.write(
                    self.style.SUCCESS(
                        f'✅ Counsellor user "{username}" already exists with profile.'
                    )
                )
                self.stdout.write(f'   Username: {username}')
                self.stdout.write(f'   Email: {user.email}')
                self.stdout.write(f'   is_active: {user.is_active}')
            else:
                # Create counsellor profile for existing user
                CounsellorProfile.objects.create(
                    user=user,
                    specialization=specialization,
                    experience_years=experience,
                    languages=languages,
                    bio=bio,
                    is_available=True
                )
                self.stdout.write(
                    self.style.SUCCESS(
                        f'✅ Created counsellor profile for existing user "{username}".'
                    )
                )
                self.stdout.write(f'   Username: {username}')
                self.stdout.write(f'   Email: {user.email}')
                self.stdout.write(f'   Specialization: {specialization}')
                self.stdout.write(f'   Experience: {experience} years')
                self.stdout.write(f'   Languages: {", ".join(languages)}')
        else:
            # Create new user with is_active=True
            # ✅ Split username into first_name and last_name for auth_user table
            name_parts = username.split(maxsplit=1)
            first_name = name_parts[0] if len(name_parts) > 0 else ""
            last_name = name_parts[1] if len(name_parts) > 1 else ""
            
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                first_name=first_name,
                last_name=last_name,
                is_active=True  # Explicitly set to active
            )
            
            # Create counsellor profile
            CounsellorProfile.objects.create(
                user=user,
                specialization=specialization,
                experience_years=experience,
                languages=languages,
                bio=bio,
                is_available=True
            )
             

            # user = User.objects.create_user(
            # username="counsellor_admin",
            # password="Counsellor@123",
            # email="counsellor@example.com",
            # is_active=True
            # )

#             CounsellorProfile.objects.create(
#     user=user,
#     full_name="Permanent Counselor",
#     is_active=True
# )

#             print("Permanent counselor created.")

            
            self.stdout.write(
                self.style.SUCCESS(
                    f'✅ Successfully created counsellor user "{username}".'
                )
            )
            self.stdout.write(f'   Username: {username}')
            self.stdout.write(f'   Email: {email}')
            self.stdout.write(f'   Specialization: {specialization}')
            self.stdout.write(f'   Experience: {experience} years')
            self.stdout.write(f'   Languages: {", ".join(languages)}')
            self.stdout.write(f'   is_active: {user.is_active}')