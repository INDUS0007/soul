from django.utils import timezone


class UpdateLastLoginMiddleware:
    """Update user.last_login for authenticated requests.

    This is helpful for token-based auth (JWT) where sessions/login() are not used.
    It only updates when last_login is null or older than a small threshold to
    avoid excessive writes.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        user = getattr(request, "user", None)
        try:
            if user and getattr(user, "is_authenticated", False):
                now = timezone.now()
                last = getattr(user, "last_login", None)
                # update only if missing or older than 60 seconds
                if not last or (now - last).total_seconds() > 60:
                    user.last_login = now
                    user.save(update_fields=["last_login"])
        except Exception:
            # never break the request because of last_login update failure
            pass

        response = self.get_response(request)
        return response