#!/usr/bin/env python
import os
import sys
import django

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import EmailOTP

print("=== EmailOTP Records in Database ===\n")
otps = EmailOTP.objects.all().order_by('-created_at')

if not otps.exists():
    print("No EmailOTP records found in database.")
else:
    print(f"{'ID':<5} {'Email':<25} {'Purpose':<15} {'Verified':<10} {'Used':<10} {'Used At':<20}")
    print("-" * 85)
    for otp in otps:
        verified = "✓" if otp.is_verified else "✗"
        used = "✓" if otp.is_used else "✗"
        used_at = str(otp.used_at)[:19] if otp.used_at else "N/A"
        print(f"{otp.id:<5} {otp.email:<25} {otp.purpose:<15} {verified:<10} {used:<10} {used_at:<20}")

print(f"\nTotal OTP records: {EmailOTP.objects.count()}")
print(f"Used OTPs (successful registrations): {EmailOTP.objects.filter(is_used=True).count()}")
print(f"Verified but unused: {EmailOTP.objects.filter(is_verified=True, is_used=False).count()}")
print(f"Unverified: {EmailOTP.objects.filter(is_verified=False).count()}")