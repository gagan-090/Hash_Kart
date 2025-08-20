# apps/vendors/models.py
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from phonenumber_field.modelfields import PhoneNumberField
import uuid

class Vendor(models.Model):
    """
    Vendor model for multi-vendor marketplace
    """
    BUSINESS_TYPE_CHOICES = [
        ('individual', 'Individual'),
        ('small_business', 'Small Business'),
        ('medium_business', 'Medium Business'),
        ('enterprise', 'Enterprise'),
        ('manufacturer', 'Manufacturer'),
        ('distributor', 'Distributor'),
        ('retailer', 'Retailer'),
    ]
    
    VERIFICATION_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('under_review', 'Under Review'),
        ('verified', 'Verified'),
        ('rejected', 'Rejected'),
        ('suspended', 'Suspended'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField('users.User', on_delete=models.CASCADE, related_name='vendor_profile')
    
    # Business Information
    business_name = models.CharField(max_length=255)
    business_type = models.CharField(max_length=50, choices=BUSINESS_TYPE_CHOICES)
    business_registration_number = models.CharField(max_length=100, blank=True)
    tax_id = models.CharField(max_length=50, blank=True)
    gst_number = models.CharField(max_length=15, blank=True)
    
    # Contact Information
    business_email = models.EmailField()
    business_phone = PhoneNumberField()
    website = models.URLField(blank=True)
    
    # Business Description
    description = models.TextField(max_length=2000, blank=True)
    short_description = models.CharField(max_length=500, blank=True)
    
    # Media
    logo = models.ImageField(upload_to='vendors/logos/', blank=True, null=True)
    banner = models.ImageField(upload_to='vendors/banners/', blank=True, null=True)
    
    # Address
    address_line_1 = models.CharField(max_length=255)
    address_line_2 = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=20)
    country = models.CharField(max_length=100, default='India')
    
    # Verification & Status
    verification_status = models.CharField(
        max_length=20, 
        choices=VERIFICATION_STATUS_CHOICES, 
        default='pending'
    )
    verification_notes = models.TextField(blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    
    # Business Settings
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    commission_rate = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=10.00,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    
    # Ratings & Reviews
    average_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        default=0.00,
        validators=[MinValueValidator(0), MaxValueValidator(5)]
    )
    total_reviews = models.PositiveIntegerField(default=0)
    
    # Business Metrics
    total_sales = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    total_orders = models.PositiveIntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'vendors'
        verbose_name = 'Vendor'
        verbose_name_plural = 'Vendors'
    
    def __str__(self):
        return self.business_name
    
    @property
    def is_verified(self):
        return self.verification_status == 'verified'
    
    @property
    def full_address(self):
        address_parts = [
            self.address_line_1,
            self.address_line_2,
            self.city,
            self.state,
            self.postal_code,
            self.country
        ]
        return ', '.join(filter(None, address_parts))


class VendorDocument(models.Model):
    """
    Vendor verification documents
    """
    DOCUMENT_TYPE_CHOICES = [
        ('business_license', 'Business License'),
        ('tax_certificate', 'Tax Certificate'),
        ('gst_certificate', 'GST Certificate'),
        ('identity_proof', 'Identity Proof'),
        ('address_proof', 'Address Proof'),
        ('bank_statement', 'Bank Statement'),
        ('other', 'Other'),
    ]
    
    VERIFICATION_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vendor = models.ForeignKey(Vendor, on_delete=models.CASCADE, related_name='documents')
    
    document_type = models.CharField(max_length=50, choices=DOCUMENT_TYPE_CHOICES)
    document_name = models.CharField(max_length=255)
    document_file = models.FileField(upload_to='vendors/documents/')
    
    verification_status = models.CharField(
        max_length=20, 
        choices=VERIFICATION_STATUS_CHOICES, 
        default='pending'
    )
    verification_notes = models.TextField(blank=True)
    verified_by = models.ForeignKey(
        'users.User', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='verified_documents'
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'vendor_documents'
        verbose_name = 'Vendor Document'
        verbose_name_plural = 'Vendor Documents'
        unique_together = ['vendor', 'document_type']
    
    def __str__(self):
        return f"{self.vendor.business_name} - {self.document_type}"


class VendorBankAccount(models.Model):
    """
    Vendor bank account information for payments
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vendor = models.ForeignKey(Vendor, on_delete=models.CASCADE, related_name='bank_accounts')
    
    # Bank Details
    account_holder_name = models.CharField(max_length=255)
    bank_name = models.CharField(max_length=255)
    account_number = models.CharField(max_length=50)
    ifsc_code = models.CharField(max_length=20)
    branch_name = models.CharField(max_length=255)
    
    # Account Type
    account_type = models.CharField(
        max_length=20,
        choices=[
            ('savings', 'Savings'),
            ('current', 'Current'),
            ('business', 'Business'),
        ],
        default='savings'
    )
    
    # Verification
    is_verified = models.BooleanField(default=False)
    is_primary = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'vendor_bank_accounts'
        verbose_name = 'Vendor Bank Account'
        verbose_name_plural = 'Vendor Bank Accounts'
    
    def __str__(self):
        return f"{self.vendor.business_name} - {self.bank_name}"
    
    def save(self, *args, **kwargs):
        # Ensure only one primary account per vendor
        if self.is_primary:
            VendorBankAccount.objects.filter(
                vendor=self.vendor, 
                is_primary=True
            ).exclude(id=self.id).update(is_primary=False)
        super().save(*args, **kwargs)


class VendorSetting(models.Model):
    """
    Vendor-specific settings and preferences
    """
    vendor = models.OneToOneField(Vendor, on_delete=models.CASCADE, related_name='settings')
    
    # Store Settings
    store_name = models.CharField(max_length=255, blank=True)
    store_slug = models.SlugField(max_length=255, unique=True, blank=True)
    store_description = models.TextField(blank=True)
    store_policies = models.TextField(blank=True)
    
    # Business Hours
    business_hours = models.JSONField(default=dict, blank=True)
    
    # Shipping Settings
    free_shipping_threshold = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=0.00
    )
    shipping_charge = models.DecimalField(
        max_digits=8, 
        decimal_places=2, 
        default=0.00
    )
    
    # Return & Refund Settings
    return_policy_days = models.PositiveIntegerField(default=7)
    accepts_returns = models.BooleanField(default=True)
    
    # Notification Settings
    order_notifications = models.BooleanField(default=True)
    inventory_alerts = models.BooleanField(default=True)
    promotional_emails = models.BooleanField(default=True)
    
    # SEO Settings
    meta_title = models.CharField(max_length=255, blank=True)
    meta_description = models.TextField(blank=True)
    meta_keywords = models.CharField(max_length=500, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'vendor_settings'
        verbose_name = 'Vendor Setting'
        verbose_name_plural = 'Vendor Settings'
    
    def __str__(self):
        return f"{self.vendor.business_name} - Settings"