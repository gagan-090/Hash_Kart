# apps/authentication/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import uuid
import secrets
import string

User = get_user_model()

class EmailVerificationToken(models.Model):
    """
    Email verification tokens for user registration
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='email_tokens')
    token = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'email_verification_tokens'
        verbose_name = 'Email Verification Token'
        verbose_name_plural = 'Email Verification Tokens'
    
    def save(self, *args, **kwargs):
        if not self.token:
            self.token = self.generate_token()
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(hours=24)
        super().save(*args, **kwargs)
    
    def generate_token(self):
        return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(64))
    
    @property
    def is_expired(self):
        return timezone.now() > self.expires_at
    
    @property
    def is_valid(self):
        return not self.is_used and not self.is_expired
    
    def __str__(self):
        return f"Email verification for {self.user.email}"


class PasswordResetToken(models.Model):
    """
    Password reset tokens
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='password_reset_tokens')
    token = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'password_reset_tokens'
        verbose_name = 'Password Reset Token'
        verbose_name_plural = 'Password Reset Tokens'
    
    def save(self, *args, **kwargs):
        if not self.token:
            self.token = self.generate_token()
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(hours=1)  # 1 hour expiry
        super().save(*args, **kwargs)
    
    def generate_token(self):
        return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(64))
    
    @property
    def is_expired(self):
        return timezone.now() > self.expires_at
    
    @property
    def is_valid(self):
        return not self.is_used and not self.is_expired
    
    def __str__(self):
        return f"Password reset for {self.user.email}"


class OTPVerification(models.Model):
    """
    OTP verification for phone numbers and additional security
    """
    OTP_TYPE_CHOICES = [
        ('phone_verification', 'Phone Verification'),
        ('password_reset', 'Password Reset'),
        ('login_verification', 'Login Verification'),
        ('transaction_verification', 'Transaction Verification'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='otp_verifications')
    otp_type = models.CharField(max_length=50, choices=OTP_TYPE_CHOICES)
    otp_code = models.CharField(max_length=6)
    phone_number = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    
    # Verification tracking
    attempts = models.PositiveIntegerField(default=0)
    max_attempts = models.PositiveIntegerField(default=3)
    is_verified = models.BooleanField(default=False)
    is_expired = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    verified_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'otp_verifications'
        verbose_name = 'OTP Verification'
        verbose_name_plural = 'OTP Verifications'
    
    def save(self, *args, **kwargs):
        if not self.otp_code:
            self.otp_code = self.generate_otp()
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(minutes=10)  # 10 minutes expiry
        super().save(*args, **kwargs)
    
    def generate_otp(self):
        return ''.join(secrets.choice(string.digits) for _ in range(6))
    
    @property
    def is_valid(self):
        return (
            not self.is_verified and 
            not self.is_expired and 
            timezone.now() <= self.expires_at and
            self.attempts < self.max_attempts
        )
    
    def verify_otp(self, provided_otp):
        self.attempts += 1
        
        if self.attempts >= self.max_attempts:
            self.is_expired = True
            self.save()
            return False, "Maximum attempts exceeded"
        
        if timezone.now() > self.expires_at:
            self.is_expired = True
            self.save()
            return False, "OTP has expired"
        
        if self.otp_code == provided_otp:
            self.is_verified = True
            self.verified_at = timezone.now()
            self.save()
            return True, "OTP verified successfully"
        else:
            self.save()
            remaining_attempts = self.max_attempts - self.attempts
            return False, f"Invalid OTP. {remaining_attempts} attempts remaining"
    
    def __str__(self):
        return f"OTP for {self.user.email} - {self.otp_type}"


class UserSession(models.Model):
    """
    Track user sessions and devices
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sessions')
    
    # Session information
    session_key = models.CharField(max_length=40, unique=True)
    refresh_token = models.TextField()
    
    # Device information
    device_type = models.CharField(max_length=50, blank=True)  # mobile, desktop, tablet
    device_name = models.CharField(max_length=255, blank=True)
    os_name = models.CharField(max_length=100, blank=True)
    browser_name = models.CharField(max_length=100, blank=True)
    
    # Location information
    ip_address = models.GenericIPAddressField()
    country = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=100, blank=True)
    
    # Session tracking
    is_active = models.BooleanField(default=True)
    last_activity = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        db_table = 'user_sessions'
        verbose_name = 'User Session'
        verbose_name_plural = 'User Sessions'
        ordering = ['-last_activity']
    
    def __str__(self):
        return f"{self.user.email} - {self.device_type} - {self.created_at}"
    
    @property
    def is_expired(self):
        return timezone.now() > self.expires_at


class LoginAttempt(models.Model):
    """
    Track login attempts for security monitoring
    """
    STATUS_CHOICES = [
        ('success', 'Success'),
        ('failed', 'Failed'),
        ('blocked', 'Blocked'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField()
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Attempt details
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    failure_reason = models.CharField(max_length=255, blank=True)
    
    # Device and location
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField(blank=True)
    device_fingerprint = models.CharField(max_length=255, blank=True)
    
    # Timestamps
    attempted_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'login_attempts'
        verbose_name = 'Login Attempt'
        verbose_name_plural = 'Login Attempts'
        ordering = ['-attempted_at']
    
    def __str__(self):
        return f"{self.email} - {self.status} - {self.attempted_at}"