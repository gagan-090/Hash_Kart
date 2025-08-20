# apps/users/serializers.py
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth import authenticate
from phonenumber_field.serializerfields import PhoneNumberField
from .models import User, UserAddress, UserPreference

class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration."""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)
    phone = PhoneNumberField(required=False)
    
    class Meta:
        model = User
        fields = [
            'email', 'first_name', 'last_name', 'phone', 
            'user_type', 'password', 'password_confirm'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match.")
        return attrs
    
    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email already exists.")
        return value
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        
        user = User.objects.create_user(
            password=password,
            **validated_data
        )
        
        # Create user preferences
        UserPreference.objects.create(user=user)
        
        return user

class UserLoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        
        if email and password:
            # Try to authenticate the user
            user = authenticate(
                request=self.context.get('request'),
                username=email,
                password=password
            )
            
            if not user:
                raise serializers.ValidationError('Invalid email or password.')
            
            if not user.is_active:
                raise serializers.ValidationError('User account is disabled.')
            
            attrs['user'] = user
            return attrs
        else:
            raise serializers.ValidationError('Must include email and password.')

class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile."""
    full_name = serializers.CharField(read_only=True)
    phone = PhoneNumberField(required=False)
    
    class Meta:
        model = User
        fields = [
            'id', 'email',  'first_name', 'last_name', 
            'full_name', 'phone', 'date_of_birth', 'profile_image',
            'user_type', 'is_email_verified', 'is_phone_verified',
            'created_at', 'last_active'
        ]
        read_only_fields = [
            'id', 'email', 'user_type', 'is_email_verified', 
            'is_phone_verified', 'created_at', 'last_active'
        ]

class UserAddressSerializer(serializers.ModelSerializer):
    """Serializer for user addresses."""
    phone = PhoneNumberField()
    
    class Meta:
        model = UserAddress
        fields = [
            'id', 'address_type', 'first_name', 'last_name', 'phone',
            'address_line_1', 'address_line_2', 'city', 'state', 
            'postal_code', 'country', 'is_default', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

class UserPreferenceSerializer(serializers.ModelSerializer):
    """Serializer for user preferences."""
    
    class Meta:
        model = UserPreference
        fields = [
            'email_notifications', 'sms_notifications', 'push_notifications',
            'marketing_emails', 'language', 'currency', 'timezone',
            'profile_visibility', 'show_online_status'
        ]

class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password."""
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError("New passwords don't match.")
        return attrs
    
    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect.")
        return value

class PasswordResetRequestSerializer(serializers.Serializer):
    """Serializer for password reset request."""
    email = serializers.EmailField()
    
    def validate_email(self, value):
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email does not exist.")
        return value

class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for password reset confirmation."""
    token = serializers.CharField()
    new_password = serializers.CharField(write_only=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError("Passwords don't match.")
        return attrs