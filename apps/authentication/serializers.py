# apps/authentication/serializers.py
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .models import EmailVerificationToken, PasswordResetToken, OTPVerification
from apps.users.serializers import UserProfileSerializer

User = get_user_model()

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Custom JWT token serializer with additional user data."""
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Add user data to the response
        data['user'] = UserProfileSerializer(self.user).data
        
        # Add vendor data if user is a vendor
        if self.user.user_type == 'vendor' and hasattr(self.user, 'vendor_profile'):
            from apps.vendors.serializers import VendorProfileSerializer
            data['vendor'] = VendorProfileSerializer(self.user.vendor_profile).data
        
        return data
    
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        
        # Add custom claims
        token['user_id'] = str(user.id)
        token['email'] = user.email
        token['user_type'] = user.user_type
        token['full_name'] = user.full_name
        
        return token

class EmailVerificationSerializer(serializers.Serializer):
    """Serializer for email verification."""
    token = serializers.CharField()
    
    def validate_token(self, value):
        try:
            token = EmailVerificationToken.objects.get(token=value)
            if not token.is_valid:
                if token.is_expired:
                    raise serializers.ValidationError("Verification token has expired.")
                else:
                    raise serializers.ValidationError("Verification token has already been used.")
            return value
        except EmailVerificationToken.DoesNotExist:
            raise serializers.ValidationError("Invalid verification token.")

class ResendEmailVerificationSerializer(serializers.Serializer):
    """Serializer for resending email verification."""
    email = serializers.EmailField()
    
    def validate_email(self, value):
        try:
            user = User.objects.get(email=value)
            if user.is_email_verified:
                raise serializers.ValidationError("Email is already verified.")
            return value
        except User.DoesNotExist:
            raise serializers.ValidationError("User with this email does not exist.")

class OTPVerificationSerializer(serializers.Serializer):
    """Serializer for OTP verification."""
    otp_code = serializers.CharField(max_length=6, min_length=6)
    otp_type = serializers.ChoiceField(choices=OTPVerification.OTP_TYPE_CHOICES)
    
    def validate_otp_code(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("OTP must contain only digits.")
        return value

class OTPRequestSerializer(serializers.Serializer):
    """Serializer for OTP request."""
    otp_type = serializers.ChoiceField(choices=OTPVerification.OTP_TYPE_CHOICES)
    phone_number = serializers.CharField(required=False)
    email = serializers.EmailField(required=False)
    
    def validate(self, attrs):
        otp_type = attrs.get('otp_type')
        
        if otp_type == 'phone_verification':
            if not attrs.get('phone_number'):
                raise serializers.ValidationError("Phone number is required for phone verification.")
        
        return attrs

class RefreshTokenSerializer(serializers.Serializer):
    """Serializer for token refresh."""
    refresh = serializers.CharField()
    
    def validate(self, attrs):
        refresh = self.context['request'].data.get('refresh')
        try:
            token = RefreshToken(refresh)
            data = {
                'access': str(token.access_token),
                'refresh': str(token)
            }
            return data
        except Exception:
            raise serializers.ValidationError("Invalid refresh token.")

class LogoutSerializer(serializers.Serializer):
    """Serializer for logout."""
    refresh = serializers.CharField()
    
    def validate(self, attrs):
        self.token = attrs['refresh']
        return attrs
    
    def save(self, **kwargs):
        try:
            RefreshToken(self.token).blacklist()
        except Exception:
            raise serializers.ValidationError("Invalid refresh token.")

class UserSessionSerializer(serializers.Serializer):
    """Serializer for user session information."""
    session_id = serializers.CharField(read_only=True)
    device_type = serializers.CharField(read_only=True)
    device_name = serializers.CharField(read_only=True)
    os_name = serializers.CharField(read_only=True)
    browser_name = serializers.CharField(read_only=True)
    ip_address = serializers.IPAddressField(read_only=True)
    country = serializers.CharField(read_only=True)
    city = serializers.CharField(read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    last_activity = serializers.DateTimeField(read_only=True)
    created_at = serializers.DateTimeField(read_only=True)

class SocialAuthSerializer(serializers.Serializer):
    """Serializer for social authentication."""
    provider = serializers.ChoiceField(choices=['google', 'facebook', 'apple'])
    access_token = serializers.CharField()
    id_token = serializers.CharField(required=False)  # For Apple Sign In
    
    def validate(self, attrs):
        provider = attrs.get('provider')
        access_token = attrs.get('access_token')
        
        # Here you would implement the actual social auth validation
        # For now, we'll just validate the required fields
        if not access_token:
            raise serializers.ValidationError("Access token is required.")
        
        return attrs