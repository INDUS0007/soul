import logging
import secrets
from collections import defaultdict
from datetime import datetime, timedelta

from django.contrib.auth.models import User
from django.core.mail import send_mail
from django.db import transaction
from django.db.models import Avg, Count, Max, Q
from django.db.models.functions import TruncDate
from django.shortcuts import get_object_or_404
from django.utils import timezone
import pytz
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    Assessment,
    Chat,
    ChatMessage,
    CounsellorProfile,
    EmailOTP,
    GuidanceResource,
    Affirmation,
    MeditationSession,
    MindCareBooster,
    MoodLog,
    MusicTrack,
    SupportGroup,
    SupportGroupMembership,
    UpcomingSession,
    UserProfile,
    MyJournal,
    WellnessTask,
    BreathingSession,
)
from .serializers import (
    AssessmentCreateSerializer,
    AssessmentSerializer,
    ChatCreateSerializer,
    ChatMessageCreateSerializer,
    ChatMessageSerializer,
    ChatSerializer,
    CounsellorAppointmentSerializer,
    CounsellorProfileSerializer,
    CounsellorStatsSerializer,
    GuidanceResourceSerializer,
    MeditationSessionSerializer,
    MindCareBoosterSerializer,
    MoodUpdateSerializer,
    MusicTrackSerializer,
    QuickSessionSerializer,
    RegisterSerializer,
    SendOTPSerializer,
    SupportGroupJoinSerializer,
    SupportGroupSerializer,
    UpcomingSessionSerializer,
    UserProfileSerializer,
    UserSettingsSerializer,
    VerifyOTPSerializer,
    WalletRechargeSerializer,
    WalletUsageSerializer,
    MyJournalSerializer,
    WellnessTaskSerializer,
    BreathingSessionSerializer,
    BreathingSessionCreateSerializer,
    AffirmationSerializer,
    AffirmationCreateSerializer,
)
from .serializers import EmailOrUsernameTokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView as BaseTokenRefreshView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError


logger = logging.getLogger(__name__)

CALL_RATE_PER_MINUTE = 5
CHAT_RATE_PER_MINUTE = 1
MIN_CALL_BALANCE = 100
MIN_CHAT_BALANCE = 50
SERVICE_RATE_MAP = {
    "call": CALL_RATE_PER_MINUTE,
    "chat": CHAT_RATE_PER_MINUTE,
}
SERVICE_MIN_BALANCE_MAP = {
    "call": MIN_CALL_BALANCE,
    "chat": MIN_CHAT_BALANCE,
}


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        profile, _created = UserProfile.objects.get_or_create(user=self.request.user)
        return profile


class UserSettingsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(profile)
        return Response(serializer.data)

    def put(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class DashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        profile_data = UserProfileSerializer(profile).data

        data = {
            "profile": profile_data | {"display_name": request.user.username.title()},
            "wallet": {"minutes": profile.wallet_minutes},
            "mood": {
                "value": profile.last_mood,
                "updated_at": profile.last_mood_updated,
            },
            "upcoming": {
                "title": "Upcoming",
                "description": "No sessions scheduled",
            },
            "quick_actions": [
                {"title": "Schedule Session", "icon": "calendar_today"},
                {"title": "Mental Health", "icon": "psychology"},
                {"title": "Expert Connect", "icon": "person_outline"},
                {"title": "Meditation", "icon": "self_improvement"},
            ],
        }
        return Response(data)


class MoodUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = MoodUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        incoming_tz: str | None = serializer.validated_data.get("timezone")
        tzinfo = timezone.get_current_timezone()
        tz_source = incoming_tz or profile.timezone
        resolved_tz_name = getattr(tzinfo, "zone", str(tzinfo))
        if tz_source:
            try:
                # Normalize timezone format (handle UTC+00:00, UTC, etc.)
                normalized_tz = tz_source.strip().upper()
                # Convert UTC+00:00 format to UTC
                if normalized_tz.startswith('UTC+') or normalized_tz.startswith('UTC-'):
                    # Extract offset and convert to UTC
                    if normalized_tz == 'UTC+00:00' or normalized_tz == 'UTC-00:00' or normalized_tz == 'UTC+0' or normalized_tz == 'UTC-0':
                        normalized_tz = 'UTC'
                    else:
                        # For other offsets, try to parse or default to UTC
                        normalized_tz = 'UTC'
                tzinfo = pytz.timezone(normalized_tz)
                resolved_tz_name = getattr(tzinfo, "zone", normalized_tz)
            except (pytz.UnknownTimeZoneError, AttributeError):
                # Silently use default timezone instead of warning
                tzinfo = timezone.get_current_timezone()
                resolved_tz_name = getattr(tzinfo, "zone", "UTC")
        timezone_updated = False
        if incoming_tz and resolved_tz_name != profile.timezone:
            profile.timezone = resolved_tz_name
            timezone_updated = True

        now_utc = timezone.now()
        local_now = now_utc.astimezone(tzinfo)
        local_date = local_now.date()

        if profile.mood_updates_date != local_date:
            profile.mood_updates_date = local_date
            profile.mood_updates_count = 0

        if profile.mood_updates_count >= 3:
            next_reset_naive = datetime.combine(local_date + timedelta(days=1), datetime.min.time())
            next_reset = timezone.make_aware(next_reset_naive, tzinfo)
            return Response(
                {
                    "status": "limit_reached",
                    "detail": "You can update your mood only 3 times per day.",
                    "reset_at_local": next_reset.isoformat(),
                    "timezone": tzinfo.zone if hasattr(tzinfo, "zone") else str(tzinfo),
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        profile.last_mood = serializer.validated_data["value"]
        profile.last_mood_updated = now_utc
        profile.mood_updates_count += 1
        profile.mood_updates_date = local_date
        update_fields = [
            "last_mood",
            "last_mood_updated",
            "mood_updates_count",
            "mood_updates_date",
        ]
        if timezone_updated:
            update_fields.append("timezone")
        profile.save(update_fields=update_fields)
        MoodLog.objects.create(user=request.user, value=profile.last_mood)
        return Response(
            {
                "status": "ok",
                "mood": profile.last_mood,
                "updated_at": profile.last_mood_updated,
                "updates_used": profile.mood_updates_count,
                "updates_remaining": max(0, 3 - profile.mood_updates_count),
            }
        )


# Legacy content payloads -------------------------------------------------

LEGACY_GUIDELINES = [
    {
        "title": "Respect & Confidentiality",
        "bullets": [
            "Treat all members with dignity and respect.",
            "Never share personal information without consent.",
            "Maintain strict confidentiality of othersÃ¢â‚¬â„¢ stories.",
            "What is shared in the community stays in the community.",
        ],
    },
    {
        "title": "Responsible Communication",
        "bullets": [
            "Use kind and supportive language.",
            "Avoid judgment, criticism, or dismissive comments.",
            "Listen actively and empathetically.",
            "Share personal experiences, not medical advice.",
        ],
    },
    {
        "title": "Content Standards",
        "bullets": [
            "No hate speech, discrimination, or harassment.",
            "No self-harm, suicide, or crisis content.",
            "No spam, advertisements, or commercial promotion.",
            "No illegal content or activities.",
        ],
    },
    {
        "title": "Crisis Support",
        "bullets": [
            "If experiencing a crisis, contact emergency services.",
            "Call our 24/7 crisis hotline for immediate help.",
            "Book an urgent counselling session.",
            "Crisis support is not a replacement for professional help.",
        ],
    },
    {
        "title": "Privacy & Data Protection",
        "bullets": [
            "Your data is encrypted and protected.",
            "We never sell or share personal information.",
            "You can request data deletion anytime.",
            "Anonymous usage options are available.",
        ],
    },
]

LEGACY_COUNSELLORS = [
    {
        "name": "Dr. Aisha Khan",
        "expertise": ["Stress", "Anxiety"],
        "rating": 4.8,
        "languages": ["English", "Hindi"],
        "tagline": "Helping you find calm and clarity.",
        "is_available_now": True,
    },
    {
        "name": "Rahul Mehta",
        "expertise": ["Career", "Relationship"],
        "rating": 4.5,
        "languages": ["English", "Hindi"],
        "tagline": "Guiding you through lifeÃ¢â‚¬â„¢s big decisions.",
        "is_available_now": False,
    },
    {
        "name": "Sofia Fernandez",
        "expertise": ["Depression", "Stress"],
        "rating": 4.9,
        "languages": ["English"],
        "tagline": "Compassionate support for brighter days.",
        "is_available_now": True,
    },
]

LEGACY_ASSESSMENT_QUESTIONS = [
    {
        "question": "How have you been feeling lately?",
        "options": ["Very low", "Low", "Neutral", "Positive", "Very positive"],
    },
    {
        "question": "How is your sleep quality?",
        "options": ["Poor", "Fair", "Average", "Good", "Excellent"],
    },
    {
        "question": "How often do you feel anxious?",
        "options": ["Rarely", "Sometimes", "Often", "Very often", "Always"],
    },
]

LEGACY_ADVANCED_SERVICES = [
    {
        "title": "Professional Counseling",
        "description": "Connect with licensed therapists and counselors for personalized support.",
        "benefits": [
            "One-on-one sessions",
            "Personalized treatment plans",
            "Confidential support",
            "Flexible scheduling",
        ],
    },
    {
        "title": "Psychiatric Consultation",
        "description": "Expert psychiatric evaluation and medication management when needed.",
        "benefits": [
            "Clinical assessment",
            "Medication guidance",
            "Crisis intervention",
            "Treatment planning",
        ],
    },
    {
        "title": "Family Therapy",
        "description": "Strengthen relationships and improve communication with family members.",
        "benefits": [
            "Family sessions",
            "Conflict resolution",
            "Communication skills",
            "Support networks",
        ],
    },
]

LEGACY_ADVANCED_SPECIALISTS = [
    {
        "name": "Dr. Sarah Johnson",
        "specialization": "Clinical Psychology",
        "experience_years": 15,
    },
    {
        "name": "Dr. Rajesh Patel",
        "specialization": "Psychiatry",
        "experience_years": 12,
    },
    {
        "name": "Emma Wilson",
        "specialization": "Family Therapy",
        "experience_years": 10,
    },
]

LEGACY_FEATURE_DETAIL = {
    "title": "Legacy Feature Detail",
    "sections": [
        {
            "heading": "Overview",
            "bullets": [
                "This is the original feature detail demo page.",
                "Content is static and for presentation purposes only.",
            ],
        },
        {
            "heading": "Next steps",
            "bullets": [
                "Review how stories were structured in the prototype.",
                "Compare against the live feature implementation.",
            ],
        },
    ],
}


class LegacyGuidelinesView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({"sections": LEGACY_GUIDELINES})


class LegacyExpertConnectView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({"counsellors": LEGACY_COUNSELLORS})


class LegacyBreathingView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(
            {
                "cycle_options": [4, 5, 6, 8, 10],
                "tip": "For calm, try 6–8 second cycles. If you feel lightheaded stop and return to normal breathing.",
            }
        )


class BreathingSessionListCreateView(generics.ListCreateAPIView):
    """
    List user's breathing sessions and create new ones.
    
    GET /api/breathing/sessions/ - List all breathing sessions for the user
    POST /api/breathing/sessions/ - Create a new breathing session
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return BreathingSessionCreateSerializer
        return BreathingSessionSerializer
    
    def get_queryset(self):
        return BreathingSession.objects.filter(user=self.request.user).order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = BreathingSessionSerializer(queryset, many=True)
        
        # Calculate stats
        total_sessions = queryset.count()
        total_duration = sum(s.duration_seconds for s in queryset)
        total_cycles = sum(s.cycles_completed for s in queryset)
        
        return Response({
            "sessions": serializer.data,
            "stats": {
                "total_sessions": total_sessions,
                "total_duration_seconds": total_duration,
                "total_duration_minutes": round(total_duration / 60, 1),
                "total_cycles": total_cycles,
            }
        })
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        session = serializer.save()
        
        # Return the created session with full details
        return Response(
            BreathingSessionSerializer(session).data,
            status=status.HTTP_201_CREATED
        )


class BreathingSessionDetailView(generics.RetrieveDestroyAPIView):
    """
    Retrieve or delete a specific breathing session.
    
    GET /api/breathing/sessions/<id>/ - Get session details
    DELETE /api/breathing/sessions/<id>/ - Delete a session
    """
    serializer_class = BreathingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return BreathingSession.objects.filter(user=self.request.user)


class LegacyAssessmentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({"questions": LEGACY_ASSESSMENT_QUESTIONS})


class LegacyAffirmationsView(APIView):
    """Legacy view - now redirects to new affirmations endpoint."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # Use the new Affirmation model if data exists, else fallback
        affirmations = Affirmation.objects.filter(is_active=True).order_by('order', '-created_at')
        if affirmations.exists():
            return Response({
                "affirmations": [a.text for a in affirmations]
            })
        # Fallback for backwards compatibility
        return Response(
            {
                "affirmations": [
                    "I am worthy of care and respect.",
                    "I breathe in calm and exhale tension.",
                    "I am capable of handling what comes my way.",
                    "I give myself permission to rest and heal.",
                ]
            }
        )


class AffirmationListView(generics.ListAPIView):
    """
    List all active affirmations.
    Users can browse one at a time with arrows in the frontend.
    
    GET /api/affirmations/
    Returns: { affirmations: [...], total: count }
    """
    serializer_class = AffirmationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Affirmation.objects.filter(is_active=True).order_by('order', '-created_at')
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        
        # Get optional category filter
        category = request.query_params.get('category', None)
        if category:
            queryset = queryset.filter(category=category)
            serializer = self.get_serializer(queryset, many=True)
        
        return Response({
            "affirmations": serializer.data,
            "total": queryset.count(),
            "categories": list(Affirmation.objects.filter(is_active=True).values_list('category', flat=True).distinct())
        })


class AffirmationDetailView(generics.RetrieveAPIView):
    """
    Get a single affirmation by ID.
    
    GET /api/affirmations/<id>/
    """
    serializer_class = AffirmationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Affirmation.objects.filter(is_active=True)


class AffirmationAdminView(APIView):
    """
    Admin endpoint to create/manage affirmations.
    Only staff users can access this.
    
    POST /api/affirmations/admin/ - Create affirmation
    POST /api/affirmations/admin/bulk/ - Create multiple affirmations
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        # Check if user is staff/admin
        if not request.user.is_staff:
            return Response(
                {"error": "Admin access required"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = AffirmationCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        affirmation = serializer.save()
        
        return Response(
            AffirmationSerializer(affirmation).data,
            status=status.HTTP_201_CREATED
        )


class AffirmationBulkCreateView(APIView):
    """
    Bulk create affirmations (admin only).
    
    POST /api/affirmations/admin/bulk/
    Body: { "affirmations": ["text1", "text2", ...] }
    or: { "affirmations": [{"text": "...", "author": "..."}, ...] }
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        if not request.user.is_staff:
            return Response(
                {"error": "Admin access required"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        affirmations_data = request.data.get('affirmations', [])
        if not affirmations_data:
            return Response(
                {"error": "No affirmations provided"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        created = []
        for idx, item in enumerate(affirmations_data):
            if isinstance(item, str):
                # Simple text format
                aff = Affirmation.objects.create(
                    text=item,
                    order=idx
                )
            elif isinstance(item, dict):
                # Object format with optional fields
                aff = Affirmation.objects.create(
                    text=item.get('text', ''),
                    author=item.get('author', ''),
                    category=item.get('category', 'general'),
                    order=item.get('order', idx),
                    is_active=item.get('is_active', True)
                )
            else:
                continue
            created.append(aff)
        
        return Response({
            "created": len(created),
            "affirmations": AffirmationSerializer(created, many=True).data
        }, status=status.HTTP_201_CREATED)


class LegacyAdvancedCareSupportView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(
            {
                "services": LEGACY_ADVANCED_SERVICES,
                "specialists": LEGACY_ADVANCED_SPECIALISTS,
            }
        )


class LegacyFeatureDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(LEGACY_FEATURE_DETAIL)


class WalletRechargeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Accept both 'amount' (rupees) and 'minutes' for backward compatibility
        # Frontend sends 'amount' in rupees, but field name is 'minutes' for legacy reasons
        amount = request.data.get("amount") or request.data.get("minutes")
        if amount is None:
            return Response(
                {"detail": "Either 'amount' or 'minutes' field is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        try:
            amount = int(amount)
            if amount <= 0:
                return Response(
                    {"detail": "Amount must be greater than 0"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        except (ValueError, TypeError):
            return Response(
                {"detail": "Invalid amount value"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        profile.wallet_minutes += amount
        profile.save(update_fields=["wallet_minutes"])
        return Response(
            {"status": "ok", "wallet_minutes": profile.wallet_minutes},
            status=status.HTTP_200_OK,
        )


class WalletDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return Response(
            {
                "wallet_minutes": profile.wallet_minutes,
                "rates": SERVICE_RATE_MAP,
                "minimum_balance": SERVICE_MIN_BALANCE_MAP,
            }
        )


class WalletUsageView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = WalletUsageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        service = serializer.validated_data["service"]
        minutes = serializer.validated_data["minutes"]
        rate = SERVICE_RATE_MAP[service]
        charge = minutes * rate
        min_required = SERVICE_MIN_BALANCE_MAP[service]

        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        if profile.wallet_minutes < min_required:
            return Response(
                {
                    "detail": f"Minimum balance of Ã¢â€šÂ¹{min_required} required to start {service}.",
                    "wallet_minutes": profile.wallet_minutes,
                    "required_minimum": min_required,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        if profile.wallet_minutes < charge:
            return Response(
                {
                    "detail": "Insufficient wallet balance",
                    "wallet_minutes": profile.wallet_minutes,
                    "required": charge,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        profile.wallet_minutes -= charge
        profile.save(update_fields=["wallet_minutes"])
        return Response(
            {
                "status": "ok",
                "service": service,
                "minutes": minutes,
                "rate_per_minute": rate,
                "charged": charge,
                "wallet_minutes": profile.wallet_minutes,
            }
        )


DEFAULT_WELLNESS_TASKS = {
    WellnessTask.CATEGORY_DAILY: [
        "Meditation (10 min)",
        "Drink 2L Water",
        "Gratitude Note",
    ],
    WellnessTask.CATEGORY_EVENING: [
        "Journaling (5 min)",
        "Reflect on 3 positive things",
    ],
}


class WellnessTaskListCreateView(generics.ListCreateAPIView):
    serializer_class = WellnessTaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            WellnessTask.objects.filter(user=self.request.user)
            .order_by("category", "order", "id")
            .all()
        )

    def list(self, request, *args, **kwargs):
        self._ensure_default_tasks(request.user)
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        items = list(serializer.data)
        grouped = {
            WellnessTask.CATEGORY_DAILY: [item for item in items if item["category"] == WellnessTask.CATEGORY_DAILY],
            WellnessTask.CATEGORY_EVENING: [item for item in items if item["category"] == WellnessTask.CATEGORY_EVENING],
        }
        total = len(items)
        completed = sum(1 for item in items if item["is_completed"])
        return Response(
            {
                "tasks": items,
                "grouped": grouped,
                "summary": {
                    "total": total,
                    "completed": completed,
                },
            }
        )

    def perform_create(self, serializer):
        category = serializer.validated_data.get("category", WellnessTask.CATEGORY_DAILY)
        next_order = (
            WellnessTask.objects.filter(user=self.request.user, category=category).aggregate(Max("order"))[
                "order__max"
            ]
            or 0
        )
        serializer.save(user=self.request.user, order=next_order + 1)

    def _ensure_default_tasks(self, user):
        if WellnessTask.objects.filter(user=user).exists():
            return
        to_create = []
        for category, titles in DEFAULT_WELLNESS_TASKS.items():
            for index, title in enumerate(titles, start=1):
                to_create.append(
                    WellnessTask(
                        user=user,
                        title=title,
                        category=category,
                        order=index,
                    )
                )
        WellnessTask.objects.bulk_create(to_create)


class WellnessTaskDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = WellnessTaskSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_url_kwarg = "task_id"

    def get_queryset(self):
        return WellnessTask.objects.filter(user=self.request.user)


DEFAULT_SUPPORT_GROUPS = [
    {
        "slug": "anxiety-support",
        "name": "Anxiety Support",
        "description": "Discuss and manage anxiety together.",
        "icon": "people_alt_rounded",
    },
    {
        "slug": "career-stress",
        "name": "Career Stress",
        "description": "Talk about workplace pressure and burnout.",
        "icon": "work_outline_rounded",
    },
    {
        "slug": "relationships",
        "name": "Relationships",
        "description": "Express emotions and build healthy connections.",
        "icon": "favorite_outline_rounded",
    },
    {
        "slug": "general-awareness",
        "name": "General Awareness",
        "description": "Learn self-care and mental health awareness.",
        "icon": "self_improvement_rounded",
    },
]


class SupportGroupListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        self._ensure_default_groups()
        queryset = SupportGroup.objects.all()
        serializer = SupportGroupSerializer(
            queryset,
            many=True,
            context={"request": request},
        )
        joined_count = SupportGroupMembership.objects.filter(user=request.user).count()
        return Response(
            {
                "groups": serializer.data,
                "joined_count": joined_count,
            }
        )

    def post(self, request):
        serializer = SupportGroupJoinSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        slug = serializer.validated_data["slug"]
        action = serializer.validated_data["action"]
        group = get_object_or_404(SupportGroup, slug=slug)

        if action == "join":
            SupportGroupMembership.objects.get_or_create(user=request.user, group=group)
        else:
            SupportGroupMembership.objects.filter(user=request.user, group=group).delete()

        updated = SupportGroupSerializer(group, context={"request": request}).data
        return Response({"status": "ok", "group": updated})

    def _ensure_default_groups(self):
        existing_slugs = set(SupportGroup.objects.values_list("slug", flat=True))
        to_create = []
        for item in DEFAULT_SUPPORT_GROUPS:
            if item["slug"] in existing_slugs:
                continue
            to_create.append(
                SupportGroup(
                    slug=item["slug"],
                    name=item["name"],
                    description=item["description"],
                    icon=item["icon"],
                )
            )
        if to_create:
            SupportGroup.objects.bulk_create(to_create)


class UpcomingSessionListCreateView(generics.ListCreateAPIView):
    serializer_class = UpcomingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UpcomingSession.objects.filter(user=self.request.user).order_by("start_time", "id")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UpcomingSessionDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = UpcomingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_url_kwarg = "session_id"

    def get_queryset(self):
        return UpcomingSession.objects.filter(user=self.request.user)


class SessionStartView(APIView):
    """Endpoint to start a session. Accepts session_id or chat_id."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, session_id):
        try:
            session = None
            
            # Try to find session by ID first
            session = UpcomingSession.objects.filter(
                Q(id=session_id) & (Q(user=request.user) | Q(counsellor=request.user))
            ).first()
            
            # If not found by session_id, try to find by chat_id (session_id might be chat_id)
            if not session:
                try:
                    chat_id = int(session_id)
                    chat = Chat.objects.filter(
                        Q(id=chat_id) & (Q(user=request.user) | Q(counsellor=request.user))
                    ).first()
                    
                    if chat and chat.user and chat.counsellor:
                        # Find or create associated UpcomingSession by user and counsellor
                        session = UpcomingSession.objects.filter(
                            Q(user=chat.user) & 
                            Q(counsellor=chat.counsellor) &
                            Q(session_status__in=['scheduled', 'in_progress'])
                        ).order_by('-start_time', '-id').first()
                        
                        # If no session exists, create one
                        if not session:
                            from datetime import timedelta
                            session = UpcomingSession.objects.create(
                                user=chat.user,
                                counsellor=chat.counsellor,
                                title=f"Chat Session with {chat.user.username}",
                                session_type=UpcomingSession.SESSION_TYPE_ONE_ON_ONE,
                                start_time=timezone.now(),
                                counsellor_name=chat.counsellor.username,
                                session_status='scheduled',
                            )
                            logger.info(
                                f"Created new session {session.id} for chat {chat_id} "
                                f"(user={chat.user.username}, counsellor={chat.counsellor.username})"
                            )
                        else:
                            logger.info(
                                f"Found existing session {session.id} for chat {chat_id} "
                                f"(user={chat.user.username}, counsellor={chat.counsellor.username})"
                            )
                except (ValueError, TypeError):
                    # session_id is not a valid integer, continue to return error
                    pass
            
            if not session:
                return Response(
                    {"error": "Session not found or access denied"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # If already started, return current state
            if session.actual_start_time and session.session_status == 'in_progress':
                return Response(
                    {
                        "status": "already_started",
                        "session_id": session.id,  # Return actual UpcomingSession ID
                        "chat_id": session_id if str(session_id) != str(session.id) else None,
                        "message": "Session already started",
                        "start_time": session.actual_start_time.isoformat(),
                        "duration_seconds": session.duration_seconds,
                    },
                    status=status.HTTP_200_OK
                )
            
            # Store actual start time and update status
            now = timezone.now()
            session.actual_start_time = now
            session.session_status = 'in_progress'
            session.is_confirmed = True
            
            # Add start note to notes field
            start_note = f"\n[Session started at {now.strftime('%Y-%m-%d %H:%M:%S')}]"
            if session.notes:
                session.notes += start_note
            else:
                session.notes = start_note.strip()
            
            session.save()
            
            logger.info(f"Session {session_id} started by user {request.user.username} at {now}")
            
            return Response(
                {
                    "status": "started",
                    "session_id": session.id,  # Return actual UpcomingSession ID
                    "chat_id": session_id if str(session_id) != str(session.id) else None,  # Include chat_id if different
                    "message": "Session started successfully",
                    "start_time": session.actual_start_time.isoformat(),
                    "duration_seconds": 0,
                },
                status=status.HTTP_200_OK
            )
        except Exception as e:
            logger.error(f"Error starting session {session_id}: {e}", exc_info=True)
            return Response(
                {"error": f"Failed to start session: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SessionEndView(APIView):
    """Endpoint to end a session. Accepts session_id or chat_id."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, session_id):
        # Log the raw request data for debugging
        logger.info("=" * 80)
        logger.info(
            f"SessionEndView: ===== REQUEST TO END SESSION ====="
        )
        logger.info(
            f"SessionEndView: Request to end session. "
            f"session_id={session_id} (type={type(session_id).__name__}), "
            f"user={request.user.username} (id={request.user.id}), "
            f"is_counsellor={hasattr(request.user, 'counsellorprofile')}"
        )
        
        try:
            
            session = None
            
            # Try to find session by ID first
            session = UpcomingSession.objects.filter(
                Q(id=session_id) & (Q(user=request.user) | Q(counsellor=request.user))
            ).first()
            
            if session:
                logger.info(
                    f"SessionEndView: Found session {session.id} by session_id. "
                    f"status={session.session_status}, "
                    f"user={session.user.username if session.user else None}, "
                    f"counsellor={session.counsellor.username if session.counsellor else None}"
                )
            
            # If not found by session_id, try to find by chat_id (session_id might be chat_id)
            chat = None
            if not session:
                try:
                    chat_id = int(session_id)
                    # First, try to get the chat without access filter to check if it exists
                    chat = Chat.objects.filter(id=chat_id).first()
                    
                    if chat:
                        logger.info(
                            f"SessionEndView: Found chat {chat_id} by session_id. "
                            f"Request by user={request.user.username} "
                            f"(chat.user={chat.user.username if chat.user else None}, "
                            f"counsellor={chat.counsellor.username if chat.counsellor else None}, "
                            f"status={chat.status})"
                        )
                        
                        # Access control: only the chat user or assigned counsellor may end the chat
                        if not (chat.user_id == request.user.id or (chat.counsellor_id and chat.counsellor_id == request.user.id)):
                            logger.warning(
                                f"SessionEndView: Access denied to end chat {chat.id} for user {request.user.username}. "
                                f"Chat owned by user_id={chat.user_id}, counsellor_id={chat.counsellor_id}, "
                                f"request.user.id={request.user.id}"
                            )
                            return Response(
                                {"error": "Access denied to end this chat"},
                                status=status.HTTP_403_FORBIDDEN
                            )
                        
                        # If chat has a counsellor, try to find associated session
                        if chat.user and chat.counsellor:
                            # Find associated UpcomingSession by user and counsellor
                            # Look for ANY session status, not just scheduled/in_progress
                            session = UpcomingSession.objects.filter(
                                Q(user=chat.user) & 
                                Q(counsellor=chat.counsellor)
                            ).order_by('-start_time', '-id').first()
                            
                            if session:
                                logger.info(
                                    f"SessionEndView: Found session {session.id} for chat {chat_id} "
                                    f"(user={chat.user.username}, counsellor={chat.counsellor.username}, "
                                    f"status={session.session_status})"
                                )
                            else:
                                # No session exists for this chat
                                logger.info(
                                    f"SessionEndView: No session found for chat {chat_id}, "
                                    f"will end chat directly if active/inactive"
                                )
                        else:
                            # Chat has no counsellor assigned (queued)
                            logger.info(
                                f"SessionEndView: Chat {chat.id} has no counsellor assigned "
                                f"(status={chat.status})"
                            )
                except (ValueError, TypeError) as e:
                    # session_id is not a valid integer, continue to return error
                    logger.debug(
                        f"SessionEndView: session_id={session_id} is not a valid integer. "
                        f"Error: {e}"
                    )
                    pass
            
            # If still no session found, but we have a chat, handle ending the chat directly
            if not session and chat:
                logger.info(
                    f"SessionEndView: No session exists for chat {chat.id}. "
                    f"Request by user={request.user.username} "
                    f"(chat.user={chat.user.username if chat.user else None}, "
                    f"counsellor={chat.counsellor.username if chat.counsellor else None}, "
                    f"status={chat.status})"
                )
                
                # If there's no counsellor assigned and chat is queued, return a clear message
                if chat.counsellor is None:
                    logger.info(
                        f"SessionEndView: Chat {chat.id} has no counsellor assigned Ã¢â‚¬â€ cannot end session by chat id"
                    )
                    return Response(
                        {"error": "Chat has no counselor assigned; cannot end session by chat id"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # If chat is active or inactive, proceed to end and bill
                if chat.status in [Chat.STATUS_ACTIVE, Chat.STATUS_INACTIVE]:
                    now = timezone.now()
                    
                    # End the chat
                    chat.status = Chat.STATUS_COMPLETED
                    if not chat.ended_at:
                        chat.ended_at = now
                    if not chat.started_at:
                        chat.started_at = now  # Fallback for duration calculation
                    
                    # Save (this should trigger billing in Chat.save())
                    chat.save()
                    
                    # Explicitly trigger billing to ensure it happens
                    from .utils.billing import calculate_and_deduct_chat_billing
                    try:
                        chat.refresh_from_db()
                        if not chat.is_billed:
                            logger.info(f"Explicitly triggering billing for chat {chat.id} from SessionEndView")
                            calculate_and_deduct_chat_billing(chat)
                    except Exception as e:
                        logger.error(f"Error explicitly triggering billing for chat {chat.id}: {e}", exc_info=True)
                    
                    # Refresh to get billing info
                    chat.refresh_from_db()
                    
                    billing_info = None
                    if getattr(chat, "is_billed", False):
                        billing_info = {
                            "billed_amount": float(getattr(chat, "billed_amount", 0.0)),
                            "duration_minutes": getattr(chat, "duration_minutes", 0),
                        }
                    
                    # Calculate duration manually if needed
                    duration_seconds = 0
                    duration_minutes = 0
                    if chat.started_at and chat.ended_at:
                        delta = chat.ended_at - chat.started_at
                        from math import ceil
                        duration_seconds = int(delta.total_seconds())
                        duration_minutes = int(ceil(duration_seconds / 60))
                    
                    logger.info(
                        f"SessionEndView: Chat {chat.id} ended successfully (no session existed). "
                        f"Duration: {duration_minutes} minutes, Billing: Ã¢â€šÂ¹{billing_info['billed_amount'] if billing_info else 0}"
                    )
                    
                    return Response(
                        {
                            "status": "ended",
                            "message": "Chat ended successfully (no session existed)",
                            "chat_id": chat.id,
                            "end_time": chat.ended_at.isoformat() if chat.ended_at else None,
                            "duration_seconds": duration_seconds,
                            "duration_minutes": duration_minutes,
                            "billing": billing_info,
                        },
                        status=status.HTTP_200_OK
                    )
                
                # Chat cannot be ended because it's not active/inactive
                logger.info(
                    f"SessionEndView: Chat {chat.id} is in status {chat.status}, cannot end"
                )
                return Response(
                    {"error": f"Chat {chat.id} is currently {chat.status} and cannot be ended"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Final check: if still no session found
            if not session:
                logger.warning("=" * 80)
                logger.warning(
                    f"SessionEndView: ===== FINAL CHECK - NO SESSION FOUND ====="
                )
                
                # Check if chat lookup failed because chat doesn't exist or access denied
                if chat is None:
                    # Try to see if chat exists but we don't have access
                    try:
                        chat_id = int(session_id)
                        existing_chat = Chat.objects.filter(id=chat_id).first()
                        if existing_chat:
                            logger.warning(
                                f"SessionEndView: Chat {chat_id} EXISTS but ACCESS DENIED. "
                                f"Request by user={request.user.username} (id={request.user.id}), "
                                f"chat.user_id={existing_chat.user_id}, "
                                f"chat.counsellor_id={existing_chat.counsellor_id}, "
                                f"chat.status={existing_chat.status}"
                            )
                            return Response(
                                {
                                    "error": "Access denied to end this chat",
                                    "chat_id": chat_id,
                                    "details": f"Chat exists but user {request.user.username} does not have access"
                                },
                                status=status.HTTP_403_FORBIDDEN
                            )
                        else:
                            logger.warning(
                                f"SessionEndView: Chat {chat_id} DOES NOT EXIST in database. "
                                f"Request by user={request.user.username}"
                            )
                    except (ValueError, TypeError) as parse_error:
                        logger.warning(
                            f"SessionEndView: Cannot parse session_id={session_id} as integer. "
                            f"Error: {parse_error}"
                        )
                
                # Log summary of what we found
                logger.warning(
                    f"SessionEndView: ===== SUMMARY ====="
                )
                logger.warning(
                    f"SessionEndView: session_id provided: {session_id} (type={type(session_id).__name__})"
                )
                logger.warning(
                    f"SessionEndView: session found: {session is not None}"
                )
                logger.warning(
                    f"SessionEndView: chat found: {chat is not None}"
                )
                if chat:
                    logger.warning(
                        f"SessionEndView: chat.id={chat.id}, chat.status={chat.status}, "
                        f"chat.user_id={chat.user_id}, chat.counsellor_id={chat.counsellor_id}"
                    )
                logger.warning(
                    f"SessionEndView: requesting user={request.user.username} (id={request.user.id}), "
                    f"is_counsellor={hasattr(request.user, 'counsellorprofile')}"
                )
                logger.warning("=" * 80)
                
                return Response(
                    {
                        "error": "Session not found or access denied",
                        "details": f"No session or chat found with id={session_id} for user={request.user.username}",
                        "session_id": session_id,
                        "debug_info": {
                            "session_found": session is not None,
                            "chat_found": chat is not None,
                            "chat_id": chat.id if chat else None,
                            "chat_status": chat.status if chat else None,
                        }
                    },
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # If already ended, return current state
            if session.actual_end_time and session.session_status == 'completed':
                return Response(
                    {
                        "status": "already_ended",
                        "session_id": session.id,  # Return actual UpcomingSession ID
                        "chat_id": session_id if str(session_id) != str(session.id) else None,
                        "message": "Session already ended",
                        "end_time": session.actual_end_time.isoformat(),
                        "duration_seconds": session.duration_seconds,
                    },
                    status=status.HTTP_200_OK
                )
            
            # Store actual end time and calculate duration
            now = timezone.now()
            session.actual_end_time = now
            session.session_status = 'completed'
            session.is_confirmed = False
            
            # Ensure start time exists (for duration calculation)
            if not session.actual_start_time:
                session.actual_start_time = now  # Fallback if never explicitly started
            
            # Add end note to notes field
            end_note = f"\n[Session ended at {now.strftime('%Y-%m-%d %H:%M:%S')}]"
            if session.notes:
                session.notes += end_note
            else:
                session.notes = end_note.strip()
            
            session.save()
            
            # Process billing for associated chat if exists
            billing_info = None
            if session.user and session.counsellor:
                try:
                    chat = Chat.objects.filter(
                        user=session.user,
                        counsellor=session.counsellor,
                        status__in=[Chat.STATUS_ACTIVE, Chat.STATUS_INACTIVE]
                    ).order_by('-started_at', '-id').first()
                    
                    if chat and not chat.is_billed and chat.started_at:
                        logger.info(
                            f"Processing billing for chat {chat.id} when session {session.id} ended: "
                            f"current_status={chat.status}, started_at={chat.started_at}, ended_at={chat.ended_at}"
                        )
                        
                        # Ensure chat is ended if session is ending
                        if chat.status != Chat.STATUS_COMPLETED:
                            chat.status = Chat.STATUS_COMPLETED
                            if not chat.ended_at:
                                chat.ended_at = now
                            chat.save()  # This will trigger billing in Chat.save()
                        
                        # Get billing info after save
                        chat.refresh_from_db()
                        
                        # If billing wasn't triggered by save(), trigger it explicitly
                        if not chat.is_billed and chat.started_at and chat.ended_at:
                            logger.warning(
                                f"Billing not triggered automatically for chat {chat.id}, "
                                f"triggering explicitly..."
                            )
                            from .utils.billing import calculate_and_deduct_chat_billing
                            try:
                                success = calculate_and_deduct_chat_billing(chat)
                                chat.refresh_from_db()
                                if success:
                                    logger.info(
                                        f"Ã¢Å“â€¦ Explicit billing triggered successfully for chat {chat.id}"
                                    )
                                else:
                                    logger.error(
                                        f"Ã¢ÂÅ’ Explicit billing failed for chat {chat.id}"
                                    )
                            except Exception as e:
                                logger.error(
                                    f"Error triggering explicit billing for chat {chat.id}: {e}",
                                    exc_info=True
                                )
                        
                        if chat.is_billed:
                            billing_info = {
                                "billed_amount": float(chat.billed_amount),
                                "duration_minutes": chat.duration_minutes,
                            }
                            logger.info(
                                f"Ã¢Å“â€¦ Billing processed for chat {chat.id} when session {session.id} ended: "
                                f"Ã¢â€šÂ¹{chat.billed_amount} for {chat.duration_minutes} minutes"
                            )
                        else:
                            logger.warning(
                                f"Ã¢Å¡ Ã¯Â¸Â Billing not processed for chat {chat.id} after session {session.id} ended: "
                                f"is_billed={chat.is_billed}, duration_minutes={chat.duration_minutes}"
                            )
                except Exception as e:
                    logger.error(f"Error processing billing when session {session.id} ended: {e}", exc_info=True)
            
            logger.info(f"Session {session_id} ended by user {request.user.username} at {now}")
            
            response_data = {
                "status": "ended",
                "session_id": session.id,  # Return actual UpcomingSession ID
                "chat_id": session_id if str(session_id) != str(session.id) else None,  # Include chat_id if different
                "message": "Session ended successfully",
                "end_time": session.actual_end_time.isoformat(),
                "duration_seconds": session.duration_seconds,
                "duration_minutes": session.duration_minutes,
            }
            
            if billing_info:
                response_data["billing"] = billing_info
            
            return Response(
                response_data,
                status=status.HTTP_200_OK
            )
        except Exception as e:
            logger.error("=" * 80)
            logger.error(
                f"SessionEndView: ===== EXCEPTION IN END SESSION ====="
            )
            logger.error(
                f"SessionEndView: Error ending session. "
                f"session_id={session_id}, user={request.user.username} (id={request.user.id}), "
                f"error={str(e)}, type={type(e).__name__}"
            )
            logger.error(f"SessionEndView: Full traceback:", exc_info=True)
            logger.error("=" * 80)
            return Response(
                {
                    "error": f"Failed to end session: {str(e)}",
                    "session_id": session_id,
                    "details": f"An unexpected error occurred: {type(e).__name__}: {str(e)}"
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SessionDurationView(APIView):
    """Get current session duration from backend."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, session_id):
        try:
            # Check if user is the session owner or assigned counselor
            session = UpcomingSession.objects.filter(
                Q(id=session_id) & (Q(user=request.user) | Q(counsellor=request.user))
            ).first()
            
            if not session:
                return Response(
                    {"error": "Session not found or access denied"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Calculate duration
            duration_seconds = session.duration_seconds
            duration_minutes = session.duration_minutes
            
            return Response({
                "session_id": session_id,
                "status": session.session_status,
                "start_time": session.actual_start_time.isoformat() if session.actual_start_time else None,
                "end_time": session.actual_end_time.isoformat() if session.actual_end_time else None,
                "duration_seconds": duration_seconds,
                "duration_minutes": duration_minutes,
                "is_active": session.session_status == 'in_progress',
            }, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error getting session duration {session_id}: {e}", exc_info=True)
            return Response(
                {"error": f"Failed to get session duration: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SessionUpdateView(APIView):
    """Update session risk level, notes, manual flag."""
    permission_classes = [permissions.IsAuthenticated]
    
    def patch(self, request, session_id):
        try:
            # Check if user is the session owner or assigned counselor
            session = UpcomingSession.objects.filter(
                Q(id=session_id) & (Q(user=request.user) | Q(counsellor=request.user))
            ).first()
            
            if not session:
                return Response(
                    {"error": "Session not found or access denied"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Update allowed fields
            allowed_fields = ['risk_level', 'manual_flag', 'notes']
            update_data = {k: v for k, v in request.data.items() if k in allowed_fields}
            
            if not update_data:
                return Response(
                    {"error": "No valid fields to update"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate risk_level
            if 'risk_level' in update_data:
                valid_risk_levels = ['none', 'low', 'medium', 'high', 'critical']
                if update_data['risk_level'] not in valid_risk_levels:
                    return Response(
                        {"error": f"Invalid risk_level. Must be one of: {valid_risk_levels}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # Validate manual_flag
            if 'manual_flag' in update_data:
                valid_flags = ['green', 'yellow', 'red']
                if update_data['manual_flag'] not in valid_flags:
                    return Response(
                        {"error": f"Invalid manual_flag. Must be one of: {valid_flags}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # Update session
            for field, value in update_data.items():
                setattr(session, field, value)
            
            session.save()
            
            logger.info(f"Session {session_id} updated by user {request.user.username}: {update_data}")
            
            serializer = UpcomingSessionSerializer(session)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error updating session {session_id}: {e}", exc_info=True)
            return Response(
                {"error": f"Failed to update session: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SessionSummaryView(APIView):
    """Get complete session summary with all data."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, session_id):
        try:
            # Check if user is the session owner or assigned counselor
            session = UpcomingSession.objects.filter(
                Q(id=session_id) & (Q(user=request.user) | Q(counsellor=request.user))
            ).first()
            
            if not session:
                return Response(
                    {"error": "Session not found or access denied"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Get associated chat to count messages
            chat = None
            message_count = 0
            if session.user and session.counsellor:
                # Find associated chat for this session
                chat = Chat.objects.filter(
                    user=session.user,
                    counsellor=session.counsellor
                ).order_by('-created_at').first()
                
                if chat:
                    message_count = ChatMessage.objects.filter(chat=chat).count()
            
            return Response({
                "session_id": session.id,
                "client_name": session.counsellor_name or session.user.username if session.user else "Unknown",
                "session_type": session.session_type,
                "scheduled_time": session.start_time.isoformat() if session.start_time else None,
                "start_time": session.actual_start_time.isoformat() if session.actual_start_time else None,
                "end_time": session.actual_end_time.isoformat() if session.actual_end_time else None,
                "duration_seconds": session.duration_seconds,
                "duration_minutes": session.duration_minutes,
                "message_count": message_count,
                "risk_level": session.risk_level,
                "manual_flag": session.manual_flag,
                "notes": session.notes,
                "status": session.session_status,
                "is_confirmed": session.is_confirmed,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error getting session summary {session_id}: {e}", exc_info=True)
            return Response(
                {"error": f"Failed to get session summary: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class QuickSessionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = QuickSessionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        session_date = serializer.validated_data["date"]
        session_time = serializer.validated_data["time"]
        start_naive = datetime.combine(session_date, session_time)
        start_at = timezone.make_aware(start_naive, timezone.get_current_timezone())

        session = UpcomingSession.objects.create(
            user=request.user,
            title=serializer.validated_data.get("title") or "Counselling Session",
            session_type="one_on_one",
            start_time=start_at,
            counsellor_name="Assigned Counsellor",
            notes=serializer.validated_data.get("notes", ""),
            is_confirmed=False,
        )
        return Response(
            {
                "status": "scheduled",
                "session": UpcomingSessionSerializer(session).data,
            },
            status=status.HTTP_201_CREATED,
        )


class MyJournalListCreateView(generics.ListCreateAPIView):
    """List and create simple MyJournal entries for the authenticated user."""
    serializer_class = MyJournalSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MyJournal.objects.filter(user=self.request.user).order_by("-date", "-created_at")

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({"entries": serializer.data})

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class MyJournalDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = MyJournalSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = "pk"

    def get_queryset(self):
        return MyJournal.objects.filter(user=self.request.user)





class RegistrationSendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"]

        with transaction.atomic():
            EmailOTP.objects.filter(email=email, purpose=EmailOTP.PURPOSE_REGISTRATION).delete()
            code = f"{secrets.randbelow(1_000_000):06d}"
            token = secrets.token_urlsafe(32)
            otp = EmailOTP.objects.create(
                email=email,
                code=code,
                purpose=EmailOTP.PURPOSE_REGISTRATION,
                token=token,
                expires_at=timezone.now() + timezone.timedelta(minutes=10),
            )

        logger.info("Registration OTP for %s is %s", email, code)
        print(f"[OTP] Registration code for {email}: {code}")

        # Send email with proper error handling
        try:
            from django.conf import settings
            
            # Use DEFAULT_FROM_EMAIL from settings
            from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'python.nexnoratech@gmail.com')
            
            logger.info(f"Attempting to send OTP email to {email} from {from_email}")
            print(f"[OTP] Sending email to {email} from {from_email}")
            
            result = send_mail(
            subject="Your Soul Support verification code",
            message=f"Use this code to finish your sign up: {otp.code}. It expires in 10 minutes.",
                from_email=from_email,
            recipient_list=[email],
            fail_silently=False,
        )

            logger.info(f"OTP email sent successfully to {email}. Result: {result}")
            print(f"[OTP] Email sent successfully to {email}")
            
            return Response({"status": "sent", "message": "OTP sent successfully"})
            
        except Exception as e:
            error_msg = f"Failed to send OTP email to {email}: {str(e)}"
            logger.error(error_msg, exc_info=True)
            print(f"[OTP ERROR] {error_msg}")
            
            # Still return success to user (security: don't reveal email issues)
            # But log the error for debugging
            return Response(
                {"status": "sent", "message": "OTP sent successfully"},
                status=status.HTTP_200_OK
            )


class RegistrationVerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        otp: EmailOTP = serializer.validated_data["otp"]
        otp.mark_verified()
        return Response({"status": "verified", "token": otp.token})


class PasswordResetSendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from .serializers import PasswordResetSendOTPSerializer

        serializer = PasswordResetSendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"]

        with transaction.atomic():
            # remove previous password-reset OTPs for this email
            EmailOTP.objects.filter(email=email, purpose=EmailOTP.PURPOSE_PASSWORD_RESET).delete()
            code = f"{secrets.randbelow(1_000_000):06d}"
            token = secrets.token_urlsafe(32)
            otp = EmailOTP.objects.create(
                email=email,
                code=code,
                purpose=EmailOTP.PURPOSE_PASSWORD_RESET,
                token=token,
                expires_at=timezone.now() + timezone.timedelta(minutes=10),
            )

        logger.info("Password-reset OTP for %s is %s", email, code)
        print(f"[OTP] Password-reset code for {email}: {code}")

        # send email
        try:
            from django.conf import settings
            from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'python.nexnoratech@gmail.com')
            logger.info(f"Attempting to send password-reset email to {email} from {from_email}")
            result = send_mail(
                subject="Your Soul Support password reset code",
                message=f"Use this code to reset your password: {otp.code}. It expires in 10 minutes.",
                from_email=from_email,
                recipient_list=[email],
                fail_silently=False,
            )
            logger.info(f"Password-reset OTP email sent successfully to {email}. Result: {result}")
            return Response({"status": "sent", "message": "OTP sent successfully"})
        except Exception as e:
            error_msg = f"Failed to send password-reset OTP email to {email}: {str(e)}"
            logger.error(error_msg, exc_info=True)
            print(f"[OTP ERROR] {error_msg}")
            return Response({"status": "sent", "message": "OTP sent successfully"}, status=status.HTTP_200_OK)


class PasswordResetVerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from .serializers import PasswordResetVerifyOTPSerializer

        serializer = PasswordResetVerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        otp: EmailOTP = serializer.validated_data["otp"]
        otp.mark_verified()
        return Response({"status": "verified", "token": otp.token})


class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from .serializers import PasswordResetConfirmSerializer

        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        otp: EmailOTP = serializer.validated_data['otp']
        new_password = serializer.validated_data['new_password']

        # find user by email and set new password
        try:
            user = User.objects.get(email__iexact=otp.email)
        except User.DoesNotExist:
            return Response({"detail": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        with transaction.atomic():
            user.set_password(new_password)
            user.save(update_fields=['password'])
            otp.mark_used()

        return Response({"status": "ok", "message": "Password updated successfully"})


class EmailOrUsernameTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailOrUsernameTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        
        if response.status_code == 200:
            # Get user from serializer
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=False)
            user = serializer.user
            
            # Determine user role
            role = 'user'
            if hasattr(user, 'counsellorprofile'):
                role = 'counsellor'
            elif hasattr(user, 'doctorprofile'):
                role = 'doctor'
            elif user.is_superuser:
                role = 'admin'
            
            # Add role to response
            data = response.data
            data['role'] = role
            data['user_id'] = user.id
            data['username'] = user.username
            
            return Response(data)
        return response


class TokenRefreshView(BaseTokenRefreshView):
    """
    Custom token refresh view that handles cases where the user no longer exists.
    Returns 401 Unauthorized instead of 500 Internal Server Error.
    """
    
    def post(self, request, *args, **kwargs):
        try:
            return super().post(request, *args, **kwargs)
        except User.DoesNotExist:
            logger.warning(
                f"Token refresh attempted for non-existent user. "
                f"Request data: {request.data if hasattr(request, 'data') else 'N/A'}"
            )
            return Response(
                {
                    "detail": "Token is invalid or user no longer exists. Please login again.",
                    "code": "token_invalid"
                },
                status=status.HTTP_401_UNAUTHORIZED
            )
        except (InvalidToken, TokenError) as e:
            logger.warning(f"Token refresh failed: {e}")
            return Response(
                {
                    "detail": str(e),
                    "code": "token_invalid"
                },
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            logger.error(f"Unexpected error in token refresh: {e}", exc_info=True)
            return Response(
                {
                    "detail": "An error occurred while refreshing the token. Please try again.",
                    "code": "token_refresh_error"
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ReportsAnalyticsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        now = timezone.now()
        seven_days_ago = now - timezone.timedelta(days=6)
        thirty_days_ago = now - timezone.timedelta(days=29)

        weekly_logs = (
            MoodLog.objects.filter(user=user, recorded_at__date__gte=seven_days_ago.date())
            .annotate(day=TruncDate("recorded_at"))
            .values("day")
            .annotate(average=Avg("value"), count=Count("id"))
            .order_by("day")
        )
        monthly_logs = (
            MoodLog.objects.filter(user=user, recorded_at__date__gte=thirty_days_ago.date())
            .annotate(day=TruncDate("recorded_at"))
            .values("day")
            .annotate(average=Avg("value"), count=Count("id"))
            .order_by("day")
        )

        weekly_data = [
            {"date": entry["day"].isoformat(), "average": round(entry["average"], 2), "count": entry["count"]}
            for entry in weekly_logs
        ]
        monthly_data = [
            {"date": entry["day"].isoformat(), "average": round(entry["average"], 2), "count": entry["count"]}
            for entry in monthly_logs
        ]

        tasks_qs = WellnessTask.objects.filter(user=user)
        tasks_total = tasks_qs.count()
        tasks_completed = tasks_qs.filter(is_completed=True).count()
        tasks_daily = tasks_qs.filter(category=WellnessTask.CATEGORY_DAILY).count()
        tasks_evening = tasks_qs.filter(category=WellnessTask.CATEGORY_EVENING).count()
        completion_rate = (tasks_completed / tasks_total) if tasks_total else 0

        top_tasks = list(
            tasks_qs.values("title")
            .annotate(total=Count("id"))
            .order_by("-total", "title")[:5]
        )

        sessions_qs = UpcomingSession.objects.filter(user=user)
        total_sessions = sessions_qs.count()
        upcoming_sessions = sessions_qs.filter(start_time__gte=now).count()
        past_sessions = total_sessions - upcoming_sessions

        profile, _ = UserProfile.objects.get_or_create(user=user)

        if completion_rate >= 0.7 and weekly_data:
            insight = "Fantastic consistency! You're completing most of your planned tasks."
        elif upcoming_sessions == 0 and total_sessions > 0:
            insight = "You have no upcoming sessions. Consider booking a follow-up to stay on track."
        elif profile.last_mood <= 2:
            insight = "Your recent mood updates seem low. Try a relaxation activity or journaling."
        else:
            insight = "Great work staying engaged with your wellness plan. Keep the momentum going!"

        return Response(
            {
                "mood": {
                    "weekly": weekly_data,
                    "monthly": monthly_data,
                },
                "tasks": {
                    "total": tasks_total,
                    "completed": tasks_completed,
                    "completion_rate": round(completion_rate, 2),
                    "by_category": {
                        "daily": tasks_daily,
                        "evening": tasks_evening,
                    },
                    "top_tasks": top_tasks,
                },
                "sessions": {
                    "total": total_sessions,
                    "upcoming": upcoming_sessions,
                    "completed": past_sessions if past_sessions > 0 else 0,
                },
                "wallet": {"minutes": profile.wallet_minutes},
                "insight": insight,
            }
        )


class ProfessionalGuidanceListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        resource_type = request.query_params.get("type")
        category = request.query_params.get("category")
        featured = request.query_params.get("featured")

        queryset = GuidanceResource.objects.all()
        if resource_type:
            queryset = queryset.filter(resource_type=resource_type)
        if category:
            queryset = queryset.filter(category__iexact=category)
        if featured:
            queryset = queryset.filter(is_featured=True)

        serializer = GuidanceResourceSerializer(queryset, many=True)
        categories = (
            GuidanceResource.objects.exclude(category="")
            .order_by("category")
            .values_list("category", flat=True)
            .distinct()
        )
        return Response(
            {
                "resources": serializer.data,
                "categories": list(categories),
            }
        )


class MusicTrackListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        mood = request.query_params.get("mood")
        queryset = MusicTrack.objects.all()
        if mood:
            queryset = queryset.filter(mood=mood)

        serializer = MusicTrackSerializer(queryset, many=True)
        moods = (
            MusicTrack.objects.order_by("mood")
            .values_list("mood", flat=True)
            .distinct()
        )
        return Response(
            {
                "tracks": serializer.data,
                "moods": list(moods),
                "count": queryset.count(),
            }
        )


class MindCareBoosterListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        category = request.query_params.get("category")
        queryset = MindCareBooster.objects.all()
        if category:
            queryset = queryset.filter(category=category)

        serializer = MindCareBoosterSerializer(queryset, many=True)
        grouped: dict[str, list[dict]] = defaultdict(list)
        for item in serializer.data:
            grouped[item["category"]].append(item)

        categories = (
            MindCareBooster.objects.order_by("category")
            .values_list("category", flat=True)
            .distinct()
        )
        grouped_dict = {key: value for key, value in grouped.items()}
        return Response(
            {
                "boosters": serializer.data,
                "categories": list(categories),
                "grouped": grouped_dict,
            }
        )


class MeditationSessionListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        category = request.query_params.get("category")
        difficulty = request.query_params.get("difficulty")
        featured = request.query_params.get("featured")

        queryset = MeditationSession.objects.all()
        if category:
            queryset = queryset.filter(category__iexact=category)
        if difficulty:
            queryset = queryset.filter(difficulty=difficulty)
        if featured:
            queryset = queryset.filter(is_featured=True)

        serializer = MeditationSessionSerializer(queryset, many=True)
        grouped: dict[str, list[dict]] = defaultdict(list)
        featured_items = []
        for item in serializer.data:
            grouped[item["category"]].append(item)
            if item["is_featured"]:
                featured_items.append(item)

        categories = (
            MeditationSession.objects.order_by("category")
            .values_list("category", flat=True)
            .distinct()
        )
        grouped_dict = {key: value for key, value in grouped.items()}
        return Response(
            {
                "sessions": serializer.data,
                "categories": list(categories),
                "grouped": grouped_dict,
                "featured": featured_items,
            }
        )


class CounsellorProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = CounsellorProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        if not hasattr(self.request.user, 'counsellorprofile'):
            raise generics.NotFound("Counsellor profile not found")
        return self.request.user.counsellorprofile


class CounsellorAppointmentsView(generics.ListAPIView):
    serializer_class = CounsellorAppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if not hasattr(self.request.user, 'counsellorprofile'):
            return UpcomingSession.objects.none()
        
        # Get all sessions where counsellor_name matches this counselor
        counsellor_name = self.request.user.counsellorprofile.user.get_full_name() or self.request.user.username
        
        queryset = UpcomingSession.objects.filter(
            counsellor_name__icontains=counsellor_name
        ).order_by('start_time')
        
        # Filter by status if provided
        status = self.request.query_params.get('status', None)
        now = timezone.now()
        if status == 'upcoming':
            queryset = queryset.filter(start_time__gt=now)
        elif status == 'completed':
            queryset = queryset.filter(start_time__lt=now)
        elif status == 'today':
            today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
            today_end = today_start + timedelta(days=1)
            queryset = queryset.filter(start_time__gte=today_start, start_time__lt=today_end)
        
        return queryset


class CounsellorStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if not hasattr(request.user, 'counsellorprofile'):
            return Response(
                {"error": "Counsellor profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        counsellor_name = request.user.counsellorprofile.user.get_full_name() or request.user.username
        now = timezone.now()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # Get all sessions for this counselor
        all_sessions = UpcomingSession.objects.filter(
            counsellor_name__icontains=counsellor_name
        )
        
        total_sessions = all_sessions.count()
        today_sessions = all_sessions.filter(
            start_time__gte=today_start,
            start_time__lt=today_start + timedelta(days=1)
        ).count()
        upcoming_sessions = all_sessions.filter(start_time__gt=now).count()
        completed_sessions = all_sessions.filter(start_time__lt=now).count()
        
        # Get unique clients
        total_clients = all_sessions.values('user').distinct().count()
        
        # Get counselor profile for rating
        profile = request.user.counsellorprofile
        average_rating = float(profile.rating)
        
        # Calculate earnings (simplified - 100 per session)
        session_rate = 100
        monthly_earnings = all_sessions.filter(
            start_time__gte=month_start,
            start_time__lt=now
        ).count() * session_rate
        total_earnings = completed_sessions * session_rate
        
        # Get queued chats count
        queued_chats = Chat.objects.filter(
            status="queued",
            counsellor__isnull=True
        ).count()
        
        stats = {
            "total_sessions": total_sessions,
            "today_sessions": today_sessions,
            "upcoming_sessions": upcoming_sessions,
            "completed_sessions": completed_sessions,
            "average_rating": average_rating,
            "total_clients": total_clients,
            "monthly_earnings": monthly_earnings,
            "total_earnings": total_earnings,
            "queued_chats": queued_chats,
        }
        
        serializer = CounsellorStatsSerializer(stats)
        return Response(serializer.data)


class ChatCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Check wallet balance before allowing chat creation
        from .utils.billing import check_chat_wallet_balance
        
        has_balance, message, current_balance = check_chat_wallet_balance(request.user)
        if not has_balance:
            return Response(
                {
                    "error": message,
                    "wallet_minutes": current_balance,
                    "required_minimum": 1,  # Minimum 1 rupee (1 minute) to start chat
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = ChatCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        chat = Chat.objects.create(
            user=request.user,
            status="queued",
            initial_message=serializer.validated_data.get("initial_message", ""),
        )

        logger.info(
            f"Chat {chat.id} created by user {request.user.username} "
            f"(wallet balance: {current_balance} minutes)"
        )

        return Response(
            ChatSerializer(chat).data,
            status=status.HTTP_201_CREATED,
        )


class ChatListView(generics.ListAPIView):
    serializer_class = ChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Check if user is a counselor
        is_counselor = hasattr(self.request.user, 'counsellorprofile')
        
        logger.debug(
            f"ChatListView: User {self.request.user.username} (ID: {self.request.user.id}) requesting chats. "
            f"Is counselor: {is_counselor}"
        )
        
        if is_counselor:
            # For counselors: return ALL chats where they are assigned as counselor
            # Include ALL statuses (active, completed, etc.) - counselors should see their chat history
            counselor_id = self.request.user.id
            
            # Query: Get all chats where this counselor is assigned
            queryset = Chat.objects.filter(
                counsellor_id=counselor_id  # Use counsellor_id for direct database query
            ).select_related('user', 'counsellor').prefetch_related('messages').order_by("-created_at", "-updated_at")
            
            count = queryset.count()
            logger.debug(
                f"ChatListView: Counselor {self.request.user.username} (ID: {counselor_id}) requesting chats. "
                f"Query: counsellor_id={counselor_id}, Found {count} chats"
            )
            
            # Log details of each chat for debugging
            if count > 0:
                logger.debug(f"ChatListView: Showing {min(count, 10)} chats to counselor:")
                for chat in queryset[:10]:
                    msg_count = chat.messages.count() if hasattr(chat, 'messages') else ChatMessage.objects.filter(chat=chat).count()
                    logger.debug(
                        f"  - Chat ID: {chat.id}, User: {chat.user.username} (ID: {chat.user.id}), "
                        f"Status: {chat.status}, Counsellor ID: {chat.counsellor_id}, "
                        f"Messages: {msg_count}, Created: {chat.created_at}"
                    )
            else:
                # Check if there are any chats in database and what counselor IDs exist
                all_chats = Chat.objects.select_related('counsellor').all()[:10]
                total_chats = Chat.objects.count()
                chats_with_counselor = Chat.objects.exclude(counsellor__isnull=True).count()
                
                logger.warning(
                    f"ChatListView: No chats found for counselor ID {counselor_id}. "
                    f"Total chats in DB: {total_chats}, Chats with counselor: {chats_with_counselor}"
                )
                
                # Log all chats to see what's in database
                for chat in all_chats:
                    logger.debug(
                        f"  - Chat ID: {chat.id}, User: {chat.user.username}, Status: {chat.status}, "
                        f"Counsellor ID: {chat.counsellor_id}, "
                        f"Counsellor Username: {chat.counsellor.username if chat.counsellor else None}, "
                        f"Created: {chat.created_at}"
                    )
            
            return queryset
        else:
            # For regular users: return only their own chats
            user_id = self.request.user.id
            queryset = Chat.objects.filter(user_id=user_id).select_related('user', 'counsellor').order_by("-created_at", "-updated_at")
            count = queryset.count()
            logger.debug(
                f"ChatListView: User {self.request.user.username} (ID: {user_id}) requesting chats. "
                f"Query: user_id={user_id}, Found {count} chats"
            )
            return queryset


class QueuedChatsView(generics.ListAPIView):
    serializer_class = ChatSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if not hasattr(self.request.user, 'counsellorprofile'):
            logger.warning(f"QueuedChatsView: User {self.request.user.username} (ID: {self.request.user.id}) does not have counsellorprofile")
            return Chat.objects.none()
        
        # Get all queued chats without counselor assigned
        queryset = Chat.objects.filter(
            status="queued",
            counsellor__isnull=True
        ).select_related('user').order_by("created_at")
        
        count = queryset.count()
        logger.debug(f"QueuedChatsView: Found {count} queued chats for counselor {self.request.user.username} (ID: {self.request.user.id})")
        
        # Log details of each queued chat for debugging
        if count > 0:
            for chat in queryset[:5]:  # Log first 5
                logger.debug(f"  - Chat ID: {chat.id}, User: {chat.user.username}, Status: {chat.status}, Counsellor: {chat.counsellor}, Created: {chat.created_at}")
        else:
            # Log all chats to see what's in the database (only at DEBUG level to reduce noise)
            all_chats = Chat.objects.all()[:10]
            logger.debug(f"QueuedChatsView: No queued chats found. Total chats in DB: {Chat.objects.count()}")
            for chat in all_chats:
                logger.debug(f"  - Chat ID: {chat.id}, User: {chat.user.username}, Status: {chat.status}, Counsellor: {chat.counsellor_id}, Created: {chat.created_at}")
        
        return queryset


class UserChatHistoryView(generics.ListAPIView):
    """
    View for users to see their past chat connections (history).
    Returns all chats (completed, cancelled, etc.) with detailed info.
    
    GET /api/chats/history/
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        from .serializers import ChatHistorySerializer
        return ChatHistorySerializer
    
    def get_queryset(self):
        # Get all chats for this user (excluding active ones for history view)
        return Chat.objects.filter(
            user=self.request.user
        ).select_related(
            'user', 'counsellor'
        ).prefetch_related(
            'messages'
        ).order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        
        # Split into active and history
        active_chats = queryset.filter(status__in=['queued', 'active', 'inactive'])
        history_chats = queryset.filter(status__in=['completed', 'cancelled'])
        
        serializer_class = self.get_serializer_class()
        
        return Response({
            "active_chats": serializer_class(active_chats, many=True).data,
            "history": serializer_class(history_chats, many=True).data,
            "total_history_count": history_chats.count(),
        })


class CounsellorAllUserHistoryView(APIView):
    """
    View for counselors to see all users they have chatted with.
    Returns a summary of each user's chat history.
    
    GET /api/counselor/users-history/
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        if not hasattr(request.user, 'counsellorprofile'):
            return Response(
                {"error": "Only counsellors can access this endpoint"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get all unique users this counselor has chatted with
        from django.db.models import Count, Sum, Max
        
        user_summaries = Chat.objects.filter(
            counsellor=request.user
        ).values(
            'user__id', 'user__username'
        ).annotate(
            total_chats=Count('id'),
            total_duration_minutes=Sum('duration_minutes'),
            last_chat_date=Max('created_at'),
            total_messages=Count('messages')
        ).order_by('-last_chat_date')
        
        result = []
        for summary in user_summaries:
            user = User.objects.get(id=summary['user__id'])
            user_name = user.username
            if hasattr(user, 'profile') and user.profile.full_name:
                user_name = user.profile.full_name
            
            result.append({
                "user_id": summary['user__id'],
                "username": summary['user__username'],
                "user_name": user_name,
                "total_chats": summary['total_chats'],
                "total_messages": summary['total_messages'] or 0,
                "total_duration_minutes": summary['total_duration_minutes'] or 0,
                "last_chat_date": summary['last_chat_date'],
            })
        
        return Response({
            "total_users": len(result),
            "users": result
        })


class CounsellorUserChatHistoryView(generics.ListAPIView):
    """
    View for counselors to see a specific user's complete chat history.
    
    GET /api/counselor/users-history/<user_id>/
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        from .serializers import ChatHistorySerializer
        return ChatHistorySerializer
    
    def get_queryset(self):
        user_id = self.kwargs.get('user_id')
        
        if not hasattr(self.request.user, 'counsellorprofile'):
            return Chat.objects.none()
        
        # Get all chats between this counselor and the specified user
        return Chat.objects.filter(
            counsellor=self.request.user,
            user_id=user_id
        ).select_related(
            'user', 'counsellor'
        ).prefetch_related(
            'messages'
        ).order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        user_id = self.kwargs.get('user_id')
        
        if not hasattr(request.user, 'counsellorprofile'):
            return Response(
                {"error": "Only counsellors can access this endpoint"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get user info
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response(
                {"error": "User not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        queryset = self.get_queryset()
        serializer_class = self.get_serializer_class()
        
        user_name = user.username
        if hasattr(user, 'profile') and user.profile.full_name:
            user_name = user.profile.full_name
        
        # Calculate totals
        from django.db.models import Sum, Count
        stats = queryset.aggregate(
            total_duration=Sum('duration_minutes'),
            total_messages=Count('messages')
        )
        
        return Response({
            "user_id": user.id,
            "username": user.username,
            "user_name": user_name,
            "total_chats": queryset.count(),
            "total_messages": stats['total_messages'] or 0,
            "total_duration_minutes": stats['total_duration'] or 0,
            "chats": serializer_class(queryset, many=True).data
        })


class ChatAcceptView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, chat_id):
        if not hasattr(request.user, 'counsellorprofile'):
            logger.warning(
                f"ChatAcceptView: User {request.user.username} (ID: {request.user.id}) "
                f"does not have counsellorprofile"
            )
            return Response(
                {"error": "Only counsellors can accept chats"},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            chat = Chat.objects.select_related('user', 'counsellor').get(id=chat_id, status="queued")
        except Chat.DoesNotExist:
            logger.warning(
                f"ChatAcceptView: Chat {chat_id} not found or not queued. "
                f"User: {request.user.username} (ID: {request.user.id})"
            )
            return Response(
                {"error": "Chat not found or not available"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Assign counselor to chat and activate it
        logger.info(
            f"ChatAcceptView: Counselor {request.user.username} (ID: {request.user.id}) "
            f"accepting chat {chat_id} from user {chat.user.username} (ID: {chat.user.id})"
            )

        chat.counsellor = request.user
        chat.status = "active"
        chat.started_at = timezone.now()
        chat.save(update_fields=['counsellor', 'status', 'started_at', 'updated_at'])

        # Verify the save
        updated_chat = Chat.objects.get(id=chat_id)
        logger.info(
            f"ChatAcceptView: Chat {chat_id} updated successfully. "
            f"Counsellor ID: {updated_chat.counsellor_id}, Status: {updated_chat.status}"
        )

        return Response(ChatSerializer(updated_chat).data)


class ChatMessageListView(generics.ListCreateAPIView):
    serializer_class = ChatMessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        chat_id = self.kwargs.get('chat_id')
        request_user_id = self.request.user.id
        request_username = self.request.user.username
        
        logger.debug(
            f"ChatMessageListView GET: chat_id={chat_id}, "
            f"request_user={request_username} (id={request_user_id})"
        )
        
        try:
            # Get chat with all related data
            chat = Chat.objects.select_related('user', 'counsellor').prefetch_related('messages').get(id=chat_id)
            
            # Log chat details
            logger.debug(
                f"ChatMessageListView: Chat found - ID: {chat_id}, "
                f"User: {chat.user.username} (ID: {chat.user.id}), "
                f"Counsellor: {chat.counsellor.username if chat.counsellor else None} (ID: {chat.counsellor_id}), "
                f"Status: {chat.status}"
            )
            
            # Check if user has access to this chat
            is_chat_user = chat.user_id == request_user_id
            is_chat_counsellor = chat.counsellor_id is not None and chat.counsellor_id == request_user_id
            
            logger.debug(
                f"ChatMessageListView: Access check - is_chat_user={is_chat_user}, "
                f"is_chat_counsellor={is_chat_counsellor}, "
                f"chat_user_id={chat.user_id}, chat_counsellor_id={chat.counsellor_id}, "
                f"request_user_id={request_user_id}"
            )
            
            if not is_chat_user and not is_chat_counsellor:
                logger.warning(
                    f"ChatMessageListView: Access DENIED for user {request_username} (ID: {request_user_id}) "
                    f"to chat {chat_id}. User is not the chat user or assigned counselor."
                )
                return ChatMessage.objects.none()
            
            # IMPORTANT: Only user interaction should activate/reactivate chats
            # When user opens the chat, update last_user_activity and check for inactivity
            if is_chat_user:
                now = timezone.now()
                chat.last_user_activity = now
                
                # Check if chat is active but user has been inactive for > 1 hour
                # Auto-disconnect inactive chats
                if chat.status == 'active' and chat.last_user_activity:
                    one_hour_ago = now - timedelta(hours=1)
                    if chat.last_user_activity < one_hour_ago:
                        # User was inactive for > 1 hour, auto-disconnect
                        logger.info(
                            f"ChatMessageListView GET: Auto-disconnecting inactive chat {chat_id}, "
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
                        logger.info(f"Chat {chat_id} auto-disconnected due to 1 hour inactivity")
                    else:
                        # User is active, just update last_user_activity
                        chat.save(update_fields=['last_user_activity', 'updated_at'])
                elif chat.status in ['completed', 'cancelled']:
                    # User is opening a completed/cancelled chat - allow reopening
                    # This will be handled when user sends a message
                    chat.save(update_fields=['last_user_activity', 'updated_at'])
                else:
                    # Chat is queued or active, just update last_user_activity
                    chat.save(update_fields=['last_user_activity', 'updated_at'])
            
            # User has access - return ALL messages for this chat from database
            messages = ChatMessage.objects.filter(
                chat_id=chat_id  # Use chat_id for direct database query
            ).select_related('sender', 'chat').order_by("created_at", "id")
            
            msg_count = messages.count()
            
            logger.debug(
                f"ChatMessageListView: Access GRANTED. Returning {msg_count} messages for chat {chat_id}. "
                f"User {request_username} has access."
            )
            
            # Log first few messages for debugging
            if msg_count > 0:
                logger.debug(f"ChatMessageListView: First {min(msg_count, 5)} messages:")
                for msg in messages[:5]:
                    logger.debug(
                        f"  - Message ID: {msg.id}, Sender: {msg.sender.username} (ID: {msg.sender_id}), "
                        f"Text: {msg.text[:50]}..., Created: {msg.created_at}"
                    )
            else:
                logger.debug(
                    f"ChatMessageListView: No messages found in database for chat {chat_id}. "
                    f"Chat exists but has no messages."
                )
            
            return messages
        except Chat.DoesNotExist:
            logger.error(
                f"ChatMessageListView: Chat {chat_id} NOT FOUND in database. "
                f"User: {request_username} (ID: {request_user_id})"
            )
            return ChatMessage.objects.none()
        except Exception as e:
            logger.error(
                f"ChatMessageListView: ERROR getting messages for chat {chat_id}: {e}", 
                exc_info=True
            )
            return ChatMessage.objects.none()

    def post(self, request, chat_id):
        try:
            chat = Chat.objects.select_related('user', 'counsellor').get(id=chat_id)
        except Chat.DoesNotExist:
            logger.error(f"ChatMessageListView POST: Chat {chat_id} not found")
            return Response(
                {"error": "Chat not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Log access check
        logger.info(
            f"ChatMessageListView POST: chat_id={chat_id}, "
            f"request_user={request.user.username} (id={request.user.id}), "
            f"chat_user={chat.user.username} (id={chat.user.id}), "
            f"chat_counsellor={chat.counsellor.username if chat.counsellor else None} "
            f"(id={chat.counsellor_id if chat.counsellor else None}), "
            f"chat_status={chat.status}"
        )

        # Check if user has access to this chat
        is_chat_user = chat.user == request.user
        is_chat_counsellor = chat.counsellor is not None and chat.counsellor == request.user
        
        if not is_chat_user and not is_chat_counsellor:
            logger.warning(
                f"ChatMessageListView POST: Access denied for user {request.user.username} (ID: {request.user.id}) "
                f"to chat {chat_id}"
            )
            return Response(
                {"error": "You don't have access to this chat"},
                status=status.HTTP_403_FORBIDDEN
            )

        # IMPORTANT: Only user can reactivate chats, not counselor
        # If user is sending a message to a completed/cancelled chat, reopen it
        if is_chat_user and chat.status in ['completed', 'cancelled']:
            # User wants to continue the conversation - always allow reopening
            logger.info(
                f"ChatMessageListView POST: User {request.user.username} reopening chat {chat_id} "
                f"(old_status={chat.status}, ended_at={chat.ended_at})"
            )
            chat.reopen()
            # Update last_user_activity
            chat.last_user_activity = timezone.now()
            chat.save(update_fields=['status', 'ended_at', 'last_user_activity', 'updated_at'])
            
            # Notify counselor that user wants to continue chat
            # This will be handled via WebSocket in the consumer
        
        # Check if chat is active (after potential reopen)
        if chat.status != "active":
            logger.warning(
                f"ChatMessageListView POST: Chat {chat_id} is not active (status: {chat.status})"
            )
            return Response(
                {"error": "Chat is not active"},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = ChatMessageCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        text = serializer.validated_data["text"]
        logger.info(f"API SAVING MESSAGE: chat_id={chat_id}, sender={request.user.username} (id={request.user.id}), text_length={len(text)}")
        
        try:
            message = ChatMessage.objects.create(
                chat=chat,
                sender=request.user,
                text=text
            )
            
            # Verify it was saved
            saved_message = ChatMessage.objects.get(id=message.id)
            logger.info(f"API MESSAGE SAVED SUCCESSFULLY: message_id={saved_message.id}, chat_id={saved_message.chat_id}, created_at={saved_message.created_at}")
            
            # Count total messages for this chat
            total_messages = ChatMessage.objects.filter(chat=chat).count()
            logger.info(f"Total messages in chat {chat_id}: {total_messages}")
            
        except Exception as e:
            logger.error(f"ERROR SAVING MESSAGE VIA API: chat_id={chat_id}, error={e}", exc_info=True)
            return Response(
                {"error": f"Failed to save message: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response(
            ChatMessageSerializer(message).data,
            status=status.HTTP_201_CREATED
        )


# ============================================================================
# ASSESSMENT VIEWS
# ============================================================================

class AssessmentListCreateView(APIView):
    """
    List all assessments for the authenticated user and create new assessments.
    
    GET: Returns all past assessments for the user
    POST: Creates a new assessment with the user's responses
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        """Get all assessments for the current user."""
        assessments = Assessment.objects.filter(user=request.user).order_by('-created_at')
        serializer = AssessmentSerializer(assessments, many=True)
        return Response({
            "count": assessments.count(),
            "assessments": serializer.data
        })
    
    def post(self, request):
        """Create a new assessment."""
        serializer = AssessmentCreateSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        assessment = serializer.save()
        
        logger.info(
            f"Assessment created: user={request.user.username}, "
            f"mood_score={assessment.mood_score}, assessment_id={assessment.id}"
        )
        
        return Response(
            AssessmentSerializer(assessment).data,
            status=status.HTTP_201_CREATED
        )


class AssessmentDetailView(APIView):
    """
    Retrieve a specific assessment by ID.
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, assessment_id):
        """Get a specific assessment."""
        assessment = get_object_or_404(
            Assessment,
            id=assessment_id,
            user=request.user
        )
        return Response(AssessmentSerializer(assessment).data)


class AssessmentStatsView(APIView):
    """
    Get assessment statistics for the authenticated user.
    
    Returns:
    - Total number of assessments taken
    - Average mood score
    - Latest assessment
    - Mood trend (improving/declining/stable)
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        """Get assessment statistics."""
        assessments = Assessment.objects.filter(user=request.user)
        
        if not assessments.exists():
            return Response({
                "total_assessments": 0,
                "average_mood_score": None,
                "latest_assessment": None,
                "mood_trend": "no_data",
                "message": "No assessments taken yet"
            })
        
        total = assessments.count()
        avg_score = assessments.aggregate(avg=Avg('mood_score'))['avg']
        latest = assessments.order_by('-created_at').first()
        
        # Calculate mood trend based on last 5 assessments
        recent_assessments = list(assessments.order_by('-created_at')[:5])
        mood_trend = "stable"
        
        if len(recent_assessments) >= 2:
            # Compare first half vs second half averages
            first_half = recent_assessments[:len(recent_assessments)//2]
            second_half = recent_assessments[len(recent_assessments)//2:]
            
            first_avg = sum(a.mood_score for a in first_half) / len(first_half)
            second_avg = sum(a.mood_score for a in second_half) / len(second_half)
            
            diff = first_avg - second_avg
            if diff > 5:
                mood_trend = "improving"
            elif diff < -5:
                mood_trend = "declining"
        
        return Response({
            "total_assessments": total,
            "average_mood_score": round(avg_score, 1) if avg_score else None,
            "latest_assessment": AssessmentSerializer(latest).data if latest else None,
            "mood_trend": mood_trend
        })