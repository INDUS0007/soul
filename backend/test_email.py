"""
Test script to verify email configuration and sending.
Run this to diagnose email sending issues.
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.conf import settings
from django.core.mail import send_mail

print("=" * 60)
print("EMAIL CONFIGURATION TEST")
print("=" * 60)
print(f"Email Backend: {settings.EMAIL_BACKEND}")
print(f"Email Host: {getattr(settings, 'EMAIL_HOST', 'Not set')}")
print(f"Email Port: {getattr(settings, 'EMAIL_PORT', 'Not set')}")
print(f"Email User: {getattr(settings, 'EMAIL_HOST_USER', 'Not set')}")
print(f"Email Password: {'*' * len(getattr(settings, 'EMAIL_HOST_PASSWORD', '')) if getattr(settings, 'EMAIL_HOST_PASSWORD', None) else 'Not set'}")
print(f"Email Use TLS: {getattr(settings, 'EMAIL_USE_TLS', 'Not set')}")
print(f"Default From Email: {settings.DEFAULT_FROM_EMAIL}")
print("=" * 60)

# Test email sending
test_email = input("\nEnter a test email address (or press Enter to skip): ").strip()

if test_email:
    print(f"\nAttempting to send test email to {test_email}...")
    try:
        result = send_mail(
            subject="Test Email from Soul Support",
            message="This is a test email to verify email configuration.",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[test_email],
            fail_silently=False,
        )
        print(f"✅ Email sent successfully! Result: {result}")
    except Exception as e:
        print(f"❌ Failed to send email: {e}")
        print(f"Error type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
else:
    print("\nSkipping email send test.")

print("\n" + "=" * 60)
print("To use console email backend (for development), set environment variable:")
print("  $env:USE_CONSOLE_EMAIL='true'  (PowerShell)")
print("  export USE_CONSOLE_EMAIL=true  (Bash)")
print("=" * 60)

