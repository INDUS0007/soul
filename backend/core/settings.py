from pathlib import Path
from datetime import timedelta
import sys

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = "change-me"

DEBUG = True

ALLOWED_HOSTS: list[str] = ["*"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",
    "channels",
    "api",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "core.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "core.wsgi.application"
ASGI_APPLICATION = "core.asgi.application"

# DATABASES = {
#     "default": {
#         "ENGINE": "django.db.backends.sqlite3",
#         "NAME": BASE_DIR / "db.sqlite3",
#     }
# }
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'ss_db',       # The database you created
        'USER': 'postgres',        # PostgreSQL username
        'PASSWORD': '12345',    # PostgreSQL password
        'HOST': 'localhost',               # or your server IP
        'PORT': '5432',                    # default PostgreSQL port
    }
}
AUTH_PASSWORD_VALIDATORS: list[dict[str, str]] = []

LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True

STATIC_URL = "static/"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.AllowAny",
    ),
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    # When True, Simple JWT will call Django's update_last_login()
    # so `auth_user.last_login` is updated when a token is issued.
    "UPDATE_LAST_LOGIN": True,
}

CORS_ALLOW_ALL_ORIGINS = True

# Email configuration -------------------------------------------------------
# In development we dump emails to the console so you can see OTP codes.
# Override these in production with your SMTP provider credentials.
# EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
# DEFAULT_FROM_EMAIL = "Soul Support <no-reply@soulsupport.example>"

# Example production overrides:
# EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
# EMAIL_HOST = "smtp.sendgrid.net"
# EMAIL_PORT = 587
# EMAIL_HOST_USER = os.environ.get("SENDGRID_USERNAME")
# EMAIL_HOST_PASSWORD = os.environ.get("SENDGRID_PASSWORD")
# EMAIL_USE_TLS = True
# --- Email Configuration ---
# For development: Use console backend to see OTPs in terminal
# For production: Use SMTP backend with proper credentials
import os
USE_CONSOLE_EMAIL = os.environ.get('USE_CONSOLE_EMAIL', 'false').lower() == 'true'

if USE_CONSOLE_EMAIL:
    # Development: Print emails to console (useful for debugging)
    EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
    DEFAULT_FROM_EMAIL = 'Soul Support <no-reply@soulsupport.example>'
    print("[EMAIL] Using console backend - emails will appear in terminal")
else:
    # Production: Use SMTP backend
    EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
    EMAIL_HOST = 'smtp.gmail.com'
    EMAIL_PORT = 587
    EMAIL_USE_TLS = True
    EMAIL_HOST_USER = 'python.nexnoratech@gmail.com'
    EMAIL_HOST_PASSWORD = 'aazm gwze vplo kehg'
    DEFAULT_FROM_EMAIL = EMAIL_HOST_USER
    print(f"[EMAIL] Using SMTP backend - {EMAIL_HOST}:{EMAIL_PORT}")

# Optional: Email verification
def verified_callback(user):
    user.is_active = True
    user.is_verified = True
    user.save()

EMAIL_VERIFIED_CALLBACK = verified_callback
EMAIL_FROM_ADDRESS = 'python.nexnoratech@gmail.com'
EMAIL_MAIL_SUBJECT = 'Verify your email'
EMAIL_PAGE_TEMPLATE = 'email_verification.html'
EMAIL_PAGE_DOMAIN = 'http://localhost:8000'

# Channels (WebSocket) configuration
# Using in-memory channel layer for development (no Redis required)
# For production, switch to Redis: "channels_redis.core.RedisChannelLayer"
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer",
    },
}

# Logging configuration - ALL logs to terminal/console ONLY (no files)
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,  # Keep existing loggers but redirect to console
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {message}",
            "style": "{",
        },
        "simple": {
            "format": "{levelname} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
            "stream": "ext://sys.stdout",  # Output to stdout (terminal)
        },
        # NO FILE HANDLERS - all logs go to terminal only
    },
    "root": {
        "handlers": ["console"],  # Root logger uses console only
        "level": "INFO",
    },
    "loggers": {
        # Django framework loggers
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,  # Don't propagate to root
        },
        "django.request": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "django.server": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "django.db.backends": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "django.security": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        # Channels/WebSocket loggers
        "channels": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "channels.server": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "daphne": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "daphne.server": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        # Application loggers
        "api": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "chat_consumer_debug": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        # Catch-all for any other loggers
        "": {  # Empty string = root logger
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
    # Explicitly disable any file handlers that might be added
    "filters": {},
}