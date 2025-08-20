# apps/users/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator
from phonenumber_field.modelfields import PhoneNumberField
import uuid
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from .managers import CustomUserManager  # You'll define this


class User(AbstractBaseUser, PermissionsMixin):
    USER_TYPE_CHOICES = [
        ('customer', 'Customer'),
        ('vendor', 'Vendor'),
        ('admin', 'Admin'),
    ]

    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    
    user_type = models.CharField(max_length=20, choices=USER_TYPE_CHOICES, default='customer')
    phone = PhoneNumberField(blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    profile_image = models.ImageField(upload_to='profiles/', blank=True, null=True)
    is_email_verified = models.BooleanField(default=False)
    is_phone_verified = models.BooleanField(default=False)
    
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_active = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    objects = CustomUserManager()

    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'

    def __str__(self):
        return self.email

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip()


class UserAddress(models.Model):
    """
    User address model for shipping and billing
    """
    ADDRESS_TYPE_CHOICES = [
        ('home', 'Home'),
        ('work', 'Work'),
        ('other', 'Other'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    address_type = models.CharField(max_length=20, choices=ADDRESS_TYPE_CHOICES, default='home')
    
    # Address fields
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    phone = PhoneNumberField()
    address_line_1 = models.CharField(max_length=255)
    address_line_2 = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=20)
    country = models.CharField(max_length=100, default='India')
    
    # Flags
    is_default = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_addresses'
        verbose_name = 'User Address'
        verbose_name_plural = 'User Addresses'
        unique_together = ['user', 'address_type', 'is_default']
    
    def __str__(self):
        return f"{self.user.email} - {self.address_type} - {self.city}"
    
    def save(self, *args, **kwargs):
        # Ensure only one default address per user
        if self.is_default:
            UserAddress.objects.filter(
                user=self.user, 
                is_default=True
            ).exclude(id=self.id).update(is_default=False)
        super().save(*args, **kwargs)


class UserPreference(models.Model):
    """
    User preferences and settings
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='preferences')
    
    # Notification preferences
    email_notifications = models.BooleanField(default=True)
    sms_notifications = models.BooleanField(default=False)
    push_notifications = models.BooleanField(default=True)
    marketing_emails = models.BooleanField(default=False)
    
    # App preferences
    language = models.CharField(max_length=10, default='en')
    currency = models.CharField(max_length=3, default='INR')
    timezone = models.CharField(max_length=50, default='Asia/Kolkata')
    
    # Privacy settings
    profile_visibility = models.BooleanField(default=True)
    show_online_status = models.BooleanField(default=True)
    
    # Shopping preferences
    default_shipping_address = models.ForeignKey(
        UserAddress, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='default_shipping_users'
    )
    default_billing_address = models.ForeignKey(
        UserAddress, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='default_billing_users'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_preferences'
        verbose_name = 'User Preference'
        verbose_name_plural = 'User Preferences'
    
    def __str__(self):
        return f"{self.user.email} - Preferences"