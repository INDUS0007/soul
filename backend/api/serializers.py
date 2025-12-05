from django.contrib.auth import get_user_model
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import serializers
import logging

from .models import (
    Assessment,
    Chat,
    ChatMessage,
    CounsellorProfile,
    EmailOTP,
    GuidanceResource,
    MeditationSession,
    MindCareBooster,
    MusicTrack,
    SupportGroup,
    SupportGroupMembership,
    UpcomingSession,
    UserProfile,
    WellnessJournalEntry,
    WellnessTask,
)
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(required=False, allow_blank=True)
    nickname = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    # phone = serializers.CharField(required=False, allow_blank=True, max_length=10, min_length=6)
    age = serializers.IntegerField(required=False, allow_null=True, min_value=0)
    gender = serializers.CharField(required=False, allow_blank=True)
    otp_token = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = (
            "username",
            "email",
            "password",
            "full_name",
            "nickname",
            "phone",
            "age",
            "gender",
            "otp_token",
        )

    def validate_username(self, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise serializers.ValidationError("Username cannot be blank")
        if not normalized.isalnum():
            raise serializers.ValidationError("Username must be letters and numbers only")
        normalized = normalized.lower()
        if User.objects.filter(username=normalized).exists():
            raise serializers.ValidationError("Username already exists")
        return normalized

    def validate_email(self, value: str) -> str:
        normalized = value.strip().lower()
        if User.objects.filter(email__iexact=normalized).exists():
            raise serializers.ValidationError("Email already in use")
        return normalized

    def validate(self, attrs):
        attrs = super().validate(attrs)
        email = attrs.get("email")
        token = attrs.get("otp_token")
        if not email:
            raise serializers.ValidationError({"email": "Email is required for registration."})

        otp = (
            EmailOTP.objects.filter(token=token, purpose=EmailOTP.PURPOSE_REGISTRATION, email__iexact=email)
            .order_by("-created_at")
            .first()
        )
        if not otp or not otp.is_verified or otp.is_expired:
            raise serializers.ValidationError({"otp_token": "The provided OTP token is invalid or expired."})

        self.context["otp_instance"] = otp
        return attrs

    def create(self, validated_data):
        otp_instance: EmailOTP = self.context["otp_instance"]

        full_name = validated_data.pop("full_name", "").strip()
        
        # Split full_name into first_name and last_name for auth_user table
        name_parts = full_name.split(maxsplit=1)
        first_name = name_parts[0] if len(name_parts) > 0 else ""
        last_name = name_parts[1] if len(name_parts) > 1 else ""
        
        profile_fields = {
            "full_name": full_name,
            "nickname": validated_data.pop("nickname", ""),
            "phone": validated_data.pop("phone", ""),
            "age": validated_data.pop("age", None),
            "gender": validated_data.pop("gender", ""),
        }
        validated_data.pop("otp_token", None)
        normalized_email = validated_data.get("email")
        if normalized_email:
            normalized_email = normalized_email.strip().lower()

        # Ã¢Å“â€¦ Create user with first_name and last_name for auth_user table
        user = User.objects.create_user(
            username=validated_data["username"],
            email=normalized_email,
            password=validated_data["password"],
            first_name=first_name,
            last_name=last_name,
        )
        profile, _ = UserProfile.objects.get_or_create(user=user)
        for attr, value in profile_fields.items():
            if value not in (None, "", []):
                setattr(profile, attr, value)
        profile.save()

        # Mark OTP as used instead of deleting it (for audit trail)
        otp_instance.mark_used()
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)
    email = serializers.CharField(source="user.email", read_only=True)
    first_name = serializers.CharField(source="user.first_name", read_only=True)
    last_name = serializers.CharField(source="user.last_name", read_only=True)

    class Meta:
        model = UserProfile
        fields = (
            "first_name",
            "last_name",
            "username",
            "email",
            "full_name",
            "nickname",
            "phone",
            "age",
            "gender",
            "wallet_minutes",
            "last_mood",
            "last_mood_updated",
            "mood_updates_count",
            "mood_updates_date",
            "timezone",
            "notifications_enabled",
            "prefers_dark_mode",
            "language",
            "created_at",
        )
        read_only_fields = (
            "wallet_minutes",
            "last_mood",
            "last_mood_updated",
            "mood_updates_count",
            "mood_updates_date",
        )


class UserSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = (
            "full_name",
            "nickname",
            "phone",
            "age",
            "gender",
            "timezone",
            "notifications_enabled",
            "prefers_dark_mode",
            "language",
        )


class MoodUpdateSerializer(serializers.Serializer):
    value = serializers.IntegerField(min_value=1, max_value=5)
    timezone = serializers.CharField(required=False, allow_blank=True, allow_null=True)


class WalletRechargeSerializer(serializers.Serializer):
    minutes = serializers.IntegerField(min_value=1, max_value=600)


class WalletUsageSerializer(serializers.Serializer):
    SERVICE_CHOICES = (
        ("call", "Call"),
        ("chat", "Chat"),
    )

    service = serializers.ChoiceField(choices=SERVICE_CHOICES)
    minutes = serializers.IntegerField(min_value=1, max_value=240)

class WellnessTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = WellnessTask
        fields = (
            "id",
            "title",
            "category",
            "is_completed",
            "order",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class WellnessJournalEntrySerializer(serializers.ModelSerializer):
    formatted_date = serializers.SerializerMethodField()

    class Meta:
        model = WellnessJournalEntry
        fields = (
            "id",
            "title",
            "note",
            "mood",
            "entry_type",
            "created_at",
            "formatted_date",
        )
        read_only_fields = ("id", "created_at", "formatted_date")

    def get_formatted_date(self, obj: WellnessJournalEntry) -> str:
        local_dt = timezone.localtime(obj.created_at)
        return local_dt.strftime("%d %b %Y Ã¢â‚¬Â¢ %I:%M %p")


class SupportGroupSerializer(serializers.ModelSerializer):
    is_joined = serializers.SerializerMethodField()

    class Meta:
        model = SupportGroup
        fields = ("slug", "name", "description", "icon", "is_joined")

    def get_is_joined(self, obj: SupportGroup) -> bool:
        request = self.context.get("request")
        if request is None or not request.user.is_authenticated:
            return False
        return SupportGroupMembership.objects.filter(user=request.user, group=obj).exists()


class SupportGroupJoinSerializer(serializers.Serializer):
    slug = serializers.SlugField(max_length=80)
    action = serializers.ChoiceField(choices=("join", "leave"))


class UpcomingSessionSerializer(serializers.ModelSerializer):
    duration_seconds = serializers.IntegerField(read_only=True)
    duration_minutes = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = UpcomingSession
        fields = (
            "id",
            "title",
            "session_type",
            "start_time",
            "counsellor_name",
            "notes",
            "is_confirmed",
            "actual_start_time",
            "actual_end_time",
            "session_status",
            "risk_level",
            "manual_flag",
            "duration_seconds",
            "duration_minutes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at", "duration_seconds", "duration_minutes")


class ChatSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source="user.username", read_only=True)
    user_name = serializers.SerializerMethodField()
    counsellor_username = serializers.CharField(source="counsellor.username", read_only=True, allow_null=True)
    counsellor_name = serializers.SerializerMethodField()
    current_duration_minutes = serializers.IntegerField(read_only=True)
    current_estimated_cost = serializers.FloatField(read_only=True)

    class Meta:
        model = Chat
        fields = (
            "id",
            "user",
            "user_username",
            "user_name",
            "counsellor",
            "counsellor_username",
            "counsellor_name",
            "status",
            "initial_message",
            "created_at",
            "started_at",
            "ended_at",
            "updated_at",
            "billed_amount",
            "duration_minutes",
            "is_billed",
            "billing_processed_at",
            "current_duration_minutes",
            "current_estimated_cost",
        )
        read_only_fields = (
            "id", "user", "counsellor", "started_at", "ended_at", "created_at", "updated_at",
            "billed_amount", "duration_minutes", "is_billed", "billing_processed_at",
            "current_duration_minutes", "current_estimated_cost"
        )

    def get_user_name(self, obj):
        if hasattr(obj.user, "profile"):
            return obj.user.profile.full_name or obj.user.username
        return obj.user.username

    def get_counsellor_name(self, obj):
        if obj.counsellor and hasattr(obj.counsellor, "counsellorprofile"):
            return obj.counsellor.get_full_name() or obj.counsellor.username
        return None


class ChatCreateSerializer(serializers.Serializer):
    initial_message = serializers.CharField(required=False, allow_blank=True)


class ChatMessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source="sender.username", read_only=True)
    sender_name = serializers.SerializerMethodField()
    is_user = serializers.SerializerMethodField()

    class Meta:
        model = ChatMessage
        fields = (
            "id",
            "chat",
            "sender",
            "sender_username",
            "sender_name",
            "text",
            "is_user",
            "created_at",
        )
        read_only_fields = ("id", "sender", "created_at")

    def get_sender_name(self, obj):
        if hasattr(obj.sender, "profile"):
            return obj.sender.profile.full_name or obj.sender.username
        return obj.sender.username

    def get_is_user(self, obj):
        # Message is from user if sender is the chat's user (not the counsellor)
        return obj.sender == obj.chat.user


class ChatMessageCreateSerializer(serializers.Serializer):
    text = serializers.CharField(required=True, allow_blank=False)


class ChatHistorySerializer(serializers.ModelSerializer):
    """
    Serializer for chat history with detailed information.
    Used for users to view their past connections and counselors to view user histories.
    """
    user_username = serializers.CharField(source="user.username", read_only=True)
    user_name = serializers.SerializerMethodField()
    counsellor_username = serializers.CharField(source="counsellor.username", read_only=True, allow_null=True)
    counsellor_name = serializers.SerializerMethodField()
    message_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    last_message_time = serializers.SerializerMethodField()
    duration_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Chat
        fields = (
            "id",
            "user",
            "user_username",
            "user_name",
            "counsellor",
            "counsellor_username",
            "counsellor_name",
            "status",
            "initial_message",
            "created_at",
            "started_at",
            "ended_at",
            "duration_minutes",
            "duration_display",
            "billed_amount",
            "message_count",
            "last_message",
            "last_message_time",
        )
        read_only_fields = fields
    
    def get_user_name(self, obj):
        if hasattr(obj.user, "profile"):
            return obj.user.profile.full_name or obj.user.username
        return obj.user.username
    
    def get_counsellor_name(self, obj):
        if obj.counsellor:
            # Try to get full_name from UserProfile first
            if hasattr(obj.counsellor, "profile") and obj.counsellor.profile.full_name:
                return obj.counsellor.profile.full_name
            # Fallback to Django User's get_full_name() or username
            return obj.counsellor.get_full_name() or obj.counsellor.username
        return None
    
    def get_message_count(self, obj):
        return obj.messages.count()
    
    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-created_at').first()
        if last_msg:
            # Truncate message if too long
            text = last_msg.text
            if len(text) > 100:
                text = text[:100] + "..."
            return {
                "text": text,
                "sender_username": last_msg.sender.username,
                "is_user": last_msg.sender == obj.user,
            }
        return None
    
    def get_last_message_time(self, obj):
        last_msg = obj.messages.order_by('-created_at').first()
        if last_msg:
            return last_msg.created_at
        return obj.updated_at
    
    def get_duration_display(self, obj):
        if obj.duration_minutes:
            hours = obj.duration_minutes // 60
            minutes = obj.duration_minutes % 60
            if hours > 0:
                return f"{hours}h {minutes}m"
            return f"{minutes}m"
        return "0m"


class UserChatHistorySummarySerializer(serializers.Serializer):
    """
    Summary serializer for a user's chat history (for counselor view).
    Shows aggregated stats for a specific user.
    """
    user_id = serializers.IntegerField()
    username = serializers.CharField()
    user_name = serializers.CharField()
    total_chats = serializers.IntegerField()
    total_messages = serializers.IntegerField()
    total_duration_minutes = serializers.IntegerField()
    last_chat_date = serializers.DateTimeField()
    chats = ChatHistorySerializer(many=True)


class SendOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        normalized = value.strip().lower()
        if User.objects.filter(email__iexact=normalized).exists():
            raise serializers.ValidationError("Email is already associated with an account.")
        return normalized


class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(min_length=6, max_length=6)

    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        code = attrs["code"].strip()
        qs = EmailOTP.objects.filter(email__iexact=email, purpose=EmailOTP.PURPOSE_REGISTRATION).order_by("-created_at")
        otp = qs.first()
        if not otp:
            raise serializers.ValidationError({"email": "No OTP request found for this email."})
        if otp.is_expired:
            raise serializers.ValidationError({"code": "OTP has expired. Please request a new one."})
        if otp.attempts >= 5:
            raise serializers.ValidationError({"code": "Too many attempts. Please request a new OTP."})
        if otp.code != code:
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            raise serializers.ValidationError({"code": "Incorrect OTP code."})

        attrs["otp"] = otp
        return attrs


class PasswordResetSendOTPSerializer(serializers.Serializer):
    """Serializer for sending password-reset OTPs. Ensures the email exists in the system."""
    email = serializers.EmailField()

    def validate_email(self, value):
        normalized = value.strip().lower()
        if not User.objects.filter(email__iexact=normalized).exists():
            raise serializers.ValidationError("No account found with this email.")
        return normalized


class PasswordResetVerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(min_length=6, max_length=6)

    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        code = attrs["code"].strip()
        qs = EmailOTP.objects.filter(email__iexact=email, purpose=EmailOTP.PURPOSE_PASSWORD_RESET).order_by("-created_at")
        otp = qs.first()
        if not otp:
            raise serializers.ValidationError({"email": "No OTP request found for this email."})
        if otp.is_expired:
            raise serializers.ValidationError({"code": "OTP has expired. Please request a new one."})
        if otp.attempts >= 5:
            raise serializers.ValidationError({"code": "Too many attempts. Please request a new OTP."})
        if otp.code != code:
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            raise serializers.ValidationError({"code": "Incorrect OTP code."})

        attrs["otp"] = otp
        return attrs


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(min_length=8)

    def validate(self, attrs):
        token = attrs.get('token', '').strip()
        if not token:
            raise serializers.ValidationError({"token": "Token is required."})
        otp = EmailOTP.objects.filter(token=token, purpose=EmailOTP.PURPOSE_PASSWORD_RESET).order_by('-created_at').first()
        if not otp:
            raise serializers.ValidationError({"token": "Invalid or expired token."})
        if otp.is_expired:
            raise serializers.ValidationError({"token": "Token has expired. Request a new OTP."})
        attrs['otp'] = otp
        return attrs


class EmailOrUsernameTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Allow users to authenticate with either their username or email address.
    """

    def validate(self, attrs):
        username = attrs.get(self.username_field)
        if username:
            candidate = username.strip()
            if "@" in candidate:
                user_model = get_user_model()
                try:
                    user = user_model.objects.get(email__iexact=candidate)
                    attrs[self.username_field] = user.username
                except user_model.DoesNotExist:
                    pass  # fall back to default behaviour (will raise invalid credentials)

        # Perform normal token obtain validation
        data = super().validate(attrs)

        # Update last_login because SimpleJWT does not call django.contrib.auth.login
        try:
            logger = logging.getLogger(__name__)
            user = getattr(self, "user", None)
            if user is not None:
                user.last_login = timezone.now()
                user.save(update_fields=["last_login"])
                logger.debug(f"Updated last_login for user %s", user.username)
        except Exception as exc:  # pragma: no cover - defensive
            try:
                logger.warning(f"Failed to update last_login for user %s: %s", getattr(user, 'username', None), exc)
            except Exception:
                pass

        return data


class QuickSessionSerializer(serializers.Serializer):
    date = serializers.DateField()
    time = serializers.TimeField()
    title = serializers.CharField(max_length=160, required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)


class GuidanceResourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = GuidanceResource
        fields = (
            "id",
            "resource_type",
            "title",
            "subtitle",
            "summary",
            "category",
            "duration",
            "media_url",
            "thumbnail",
            "is_featured",
        )


class MusicTrackSerializer(serializers.ModelSerializer):
    duration = serializers.SerializerMethodField()

    class Meta:
        model = MusicTrack
        fields = (
            "id",
            "title",
            "description",
            "duration_seconds",
            "duration",
            "audio_url",
            "mood",
            "thumbnail",
        )

    def get_duration(self, obj: MusicTrack) -> str:
        minutes, seconds = divmod(obj.duration_seconds, 60)
        return f"{minutes:02d}:{seconds:02d}"


class MindCareBoosterSerializer(serializers.ModelSerializer):
    class Meta:
        model = MindCareBooster
        fields = (
            "id",
            "title",
            "subtitle",
            "description",
            "category",
            "icon",
            "action_label",
            "prompt",
            "estimated_seconds",
            "resource_url",
        )


class MeditationSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = MeditationSession
        fields = (
            "id",
            "title",
            "subtitle",
            "description",
            "category",
            "duration_minutes",
            "difficulty",
            "audio_url",
            "video_url",
            "is_featured",
            "thumbnail",
        )


class CounsellorProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    full_name = serializers.SerializerMethodField()
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    
    class Meta:
        model = CounsellorProfile
        fields = (
            "id",
            "first_name",
            "last_name",
            "username",
            "email",
            "full_name",
            "specialization",
            "experience_years",
            "languages",
            "rating",
            "is_available",
            "bio",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "rating", "created_at", "updated_at")
    
    def get_full_name(self, obj):
        if hasattr(obj.user, 'profile'):
            return obj.user.profile.full_name or obj.user.username
        return obj.user.username


class CounsellorAppointmentSerializer(serializers.ModelSerializer):
    client_username = serializers.CharField(source='user.username', read_only=True)
    client_name = serializers.SerializerMethodField()
    
    class Meta:
        model = UpcomingSession
        fields = (
            "id",
            "title",
            "session_type",
            "start_time",
            "client_username",
            "client_name",
            "notes",
            "is_confirmed",
            "created_at",
            "updated_at",
        )
    
    def get_client_name(self, obj):
        if hasattr(obj.user, 'profile') and obj.user.profile.full_name:
            return obj.user.profile.full_name
        return obj.user.username


class CounsellorStatsSerializer(serializers.Serializer):
    total_sessions = serializers.IntegerField()
    today_sessions = serializers.IntegerField()
    upcoming_sessions = serializers.IntegerField()
    completed_sessions = serializers.IntegerField()
    average_rating = serializers.DecimalField(max_digits=3, decimal_places=2)
    total_clients = serializers.IntegerField()
    monthly_earnings = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_earnings = serializers.DecimalField(max_digits=10, decimal_places=2)
    queued_chats = serializers.IntegerField(default=0)


# ============================================================================
# ASSESSMENT SERIALIZERS
# ============================================================================

class AssessmentSerializer(serializers.ModelSerializer):
    """Serializer for reading Assessment data."""
    username = serializers.CharField(source="user.username", read_only=True)
    
    class Meta:
        model = Assessment
        fields = (
            "id",
            "username",
            "feeling_response",
            "sleep_quality_response",
            "anxiety_frequency_response",
            "energy_level_response",
            "support_feeling_response",
            "stress_management_response",
            "average_score",
            "mood_score",
            "feedback_message",
            "feedback_tip",
            "notes",
            "created_at",
        )
        read_only_fields = (
            "id",
            "username",
            "average_score",
            "mood_score",
            "feedback_message",
            "feedback_tip",
            "notes",
            "created_at",
        )


# Answer mappings for each question - maps answer text to score
FEELING_OPTIONS = {
    'Very low': 0, 'Low': 1, 'Neutral': 2, 'Positive': 3, 'Very positive': 4
}
SLEEP_OPTIONS = {
    'Poor': 0, 'Fair': 1, 'Average': 2, 'Good': 3, 'Excellent': 4
}
ANXIETY_OPTIONS = {
    'Rarely': 0, 'Sometimes': 1, 'Often': 2, 'Very often': 3, 'Always': 4
}
ENERGY_OPTIONS = {
    'Exhausted': 0, 'Low': 1, 'Moderate': 2, 'Energized': 3, 'Very energized': 4
}
SUPPORT_OPTIONS = {
    'Not at all': 0, 'Rarely': 1, 'Sometimes': 2, 'Often': 3, 'Always': 4
}
STRESS_OPTIONS = {
    'Overwhelmed': 0, 'Struggling': 1, 'Coping': 2, 'Managing well': 3, 'Thriving': 4
}


class AssessmentCreateSerializer(serializers.Serializer):
    """Serializer for creating a new assessment with answer text."""
    # Accept the actual answer text
    feeling_response = serializers.CharField(max_length=50)
    sleep_quality_response = serializers.CharField(max_length=50)
    anxiety_frequency_response = serializers.CharField(max_length=50)
    energy_level_response = serializers.CharField(max_length=50)
    support_feeling_response = serializers.CharField(max_length=50)
    stress_management_response = serializers.CharField(max_length=50)
    
    def validate_feeling_response(self, value):
        if value not in FEELING_OPTIONS:
            raise serializers.ValidationError(f"Invalid answer. Must be one of: {', '.join(FEELING_OPTIONS.keys())}")
        return value
    
    def validate_sleep_quality_response(self, value):
        if value not in SLEEP_OPTIONS:
            raise serializers.ValidationError(f"Invalid answer. Must be one of: {', '.join(SLEEP_OPTIONS.keys())}")
        return value
    
    def validate_anxiety_frequency_response(self, value):
        if value not in ANXIETY_OPTIONS:
            raise serializers.ValidationError(f"Invalid answer. Must be one of: {', '.join(ANXIETY_OPTIONS.keys())}")
        return value
    
    def validate_energy_level_response(self, value):
        if value not in ENERGY_OPTIONS:
            raise serializers.ValidationError(f"Invalid answer. Must be one of: {', '.join(ENERGY_OPTIONS.keys())}")
        return value
    
    def validate_support_feeling_response(self, value):
        if value not in SUPPORT_OPTIONS:
            raise serializers.ValidationError(f"Invalid answer. Must be one of: {', '.join(SUPPORT_OPTIONS.keys())}")
        return value
    
    def validate_stress_management_response(self, value):
        if value not in STRESS_OPTIONS:
            raise serializers.ValidationError(f"Invalid answer. Must be one of: {', '.join(STRESS_OPTIONS.keys())}")
        return value
    
    def validate(self, attrs):
        """Validate and calculate scores from answer text."""
        # Calculate scores from responses (for mood calculation only)
        feeling_score = FEELING_OPTIONS[attrs['feeling_response']]
        sleep_score = SLEEP_OPTIONS[attrs['sleep_quality_response']]
        anxiety_score = ANXIETY_OPTIONS[attrs['anxiety_frequency_response']]
        energy_score = ENERGY_OPTIONS[attrs['energy_level_response']]
        support_score = SUPPORT_OPTIONS[attrs['support_feeling_response']]
        stress_score = STRESS_OPTIONS[attrs['stress_management_response']]
        
        # Calculate average score
        scores = [feeling_score, sleep_score, anxiety_score, energy_score, support_score, stress_score]
        average_score = sum(scores) / len(scores)
        
        # Calculate mood score (0-100)
        mood_score = round((average_score / 4) * 100)
        
        attrs['average_score'] = round(average_score, 2)
        attrs['mood_score'] = mood_score
        
        # Generate feedback and notes based on mood score
        if mood_score == 100:
            attrs['feedback_message'] = '🎉 Wow! You achieved a perfect score! You are in an amazing state of wellbeing!'
            attrs['feedback_tip'] = 'Keep doing what you\'re doing - you\'re truly thriving! Consider sharing your positive energy with others.'
            attrs['notes'] = 'Perfect score achieved! User is experiencing optimal mental wellness across all areas. Excellent sleep, energy, support system, and stress management.'
        elif mood_score >= 90:
            attrs['feedback_message'] = '🌟 Outstanding! You are in an excellent state of mental wellbeing!'
            attrs['feedback_tip'] = 'Your positive habits are clearly working. Keep nurturing your wellbeing and inspire others around you.'
            attrs['notes'] = 'Excellent score. User shows strong mental wellness indicators. All areas performing well.'
        elif mood_score >= 80:
            attrs['feedback_message'] = 'You appear to be in a positive and stable mood. Keep nurturing your wellbeing.'
            attrs['feedback_tip'] = 'Continue your habits that work well—perhaps share your positivity with someone today.'
            attrs['notes'] = 'Good mental health indicators. User is managing well overall.'
        elif mood_score >= 60:
            attrs['feedback_message'] = 'You seem slightly stressed but generally balanced.'
            attrs['feedback_tip'] = 'Try a short mindfulness break or journaling to stay grounded.'
            attrs['notes'] = 'Moderate score. Some areas may need attention. Consider stress reduction techniques.'
        elif mood_score >= 40:
            attrs['feedback_message'] = 'You may be experiencing some stress or low mood right now.'
            attrs['feedback_tip'] = 'Consider reaching out to a friend and practicing deep breathing today.'
            attrs['notes'] = 'Below average score. User may benefit from counseling support and self-care activities.'
        else:
            attrs['feedback_message'] = 'Your responses suggest notable stress or low mood.'
            attrs['feedback_tip'] = 'It might help to speak with someone you trust or a mental health professional.'
            attrs['notes'] = 'Low score. Professional support recommended. User showing signs of significant stress or low mood.'
        
        return attrs
    
    def create(self, validated_data):
        """Create and save the assessment."""
        user = self.context['request'].user
        # Store username directly in the table for easy viewing
        validated_data['username'] = user.username
        return Assessment.objects.create(user=user, **validated_data)