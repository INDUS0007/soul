from django.contrib.auth import get_user_model
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import serializers

from .models import (
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

        profile_fields = {
            "full_name": validated_data.pop("full_name", ""),
            "nickname": validated_data.pop("nickname", ""),
            "phone": validated_data.pop("phone", ""),
            "age": validated_data.pop("age", None),
            "gender": validated_data.pop("gender", ""),
        }
        validated_data.pop("otp_token", None)
        normalized_email = validated_data.get("email")
        if normalized_email:
            normalized_email = normalized_email.strip().lower()

        user = User.objects.create_user(
            username=validated_data["username"],
            email=normalized_email,
            password=validated_data["password"],
        )
        profile, _ = UserProfile.objects.get_or_create(user=user)
        for attr, value in profile_fields.items():
            if value not in (None, "", []):
                setattr(profile, attr, value)
        profile.save()

        otp_instance.delete()
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)
    email = serializers.CharField(source="user.email", read_only=True)

    class Meta:
        model = UserProfile
        fields = (
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
        return local_dt.strftime("%d %b %Y • %I:%M %p")


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
        return super().validate(attrs)


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
    
    class Meta:
        model = CounsellorProfile
        fields = (
            "id",
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

