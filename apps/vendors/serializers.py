# apps/vendors/serializers.py
from rest_framework import serializers
from phonenumber_field.serializerfields import PhoneNumberField
from .models import Vendor, VendorDocument, VendorBankAccount, VendorSetting
from apps.users.serializers import UserProfileSerializer

class VendorRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for vendor registration."""
    business_phone = PhoneNumberField()
    
    class Meta:
        model = Vendor
        fields = [
            'business_name', 'business_type', 'business_email', 'business_phone',
            'description', 'address_line_1', 'address_line_2', 'city', 
            'state', 'postal_code', 'country', 'website'
        ]
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

class VendorProfileSerializer(serializers.ModelSerializer):
    """Serializer for vendor profile."""
    user = UserProfileSerializer(read_only=True)
    full_address = serializers.CharField(read_only=True)
    is_verified = serializers.BooleanField(read_only=True)
    business_phone = PhoneNumberField()
    
    class Meta:
        model = Vendor
        fields = [
            'id', 'user', 'business_name', 'business_type', 'business_registration_number',
            'tax_id', 'gst_number', 'business_email', 'business_phone', 'website',
            'description', 'short_description', 'logo', 'banner', 'address_line_1',
            'address_line_2', 'city', 'state', 'postal_code', 'country', 'full_address',
            'verification_status', 'is_verified', 'verified_at', 'is_active', 'is_featured',
            'commission_rate', 'average_rating', 'total_reviews', 'total_sales',
            'total_orders', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'user', 'verification_status', 'verified_at', 'is_active',
            'is_featured', 'commission_rate', 'average_rating', 'total_reviews',
            'total_sales', 'total_orders', 'created_at', 'updated_at'
        ]

class VendorListSerializer(serializers.ModelSerializer):
    """Serializer for vendor list view."""
    is_verified = serializers.BooleanField(read_only=True)
    business_phone = PhoneNumberField()
    
    class Meta:
        model = Vendor
        fields = [
            'id', 'business_name', 'business_type', 'business_email', 'business_phone',
            'short_description', 'logo', 'city', 'state', 'country', 'verification_status',
            'is_verified', 'is_active', 'is_featured', 'average_rating', 'total_reviews',
            'created_at'
        ]

class VendorDocumentSerializer(serializers.ModelSerializer):
    """Serializer for vendor documents."""
    
    class Meta:
        model = VendorDocument
        fields = [
            'id', 'document_type', 'document_name', 'document_file',
            'verification_status', 'verification_notes', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'verification_status', 'verification_notes', 'created_at', 'updated_at'
        ]
    
    def create(self, validated_data):
        validated_data['vendor'] = self.context['vendor']
        return super().create(validated_data)

class VendorBankAccountSerializer(serializers.ModelSerializer):
    """Serializer for vendor bank accounts."""
    
    class Meta:
        model = VendorBankAccount
        fields = [
            'id', 'account_holder_name', 'bank_name', 'account_number',
            'ifsc_code', 'branch_name', 'account_type', 'is_verified',
            'is_primary', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'is_verified', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['vendor'] = self.context['vendor']
        return super().create(validated_data)

class VendorSettingSerializer(serializers.ModelSerializer):
    """Serializer for vendor settings."""
    
    class Meta:
        model = VendorSetting
        fields = [
            'store_name', 'store_slug', 'store_description', 'store_policies',
            'business_hours', 'free_shipping_threshold', 'shipping_charge',
            'return_policy_days', 'accepts_returns', 'order_notifications',
            'inventory_alerts', 'promotional_emails', 'meta_title',
            'meta_description', 'meta_keywords'
        ]

class VendorDashboardSerializer(serializers.ModelSerializer):
    """Serializer for vendor dashboard overview."""
    user = UserProfileSerializer(read_only=True)
    is_verified = serializers.BooleanField(read_only=True)
    business_phone = PhoneNumberField()
    
    # Additional dashboard fields
    pending_orders_count = serializers.SerializerMethodField()
    total_products_count = serializers.SerializerMethodField()
    monthly_sales = serializers.SerializerMethodField()
    
    class Meta:
        model = Vendor
        fields = [
            'id', 'user', 'business_name', 'logo', 'verification_status', 'is_verified',
            'total_sales', 'total_orders', 'average_rating', 'total_reviews',
            'pending_orders_count', 'total_products_count', 'monthly_sales'
        ]
    
    def get_pending_orders_count(self, obj):
        # This will be implemented when we create the orders app
        return 0
    
    def get_total_products_count(self, obj):
        # This will be implemented when we create the products app
        return 0
    
    def get_monthly_sales(self, obj):
        # This will be implemented with proper date filtering
        return obj.total_sales

class VendorVerificationSerializer(serializers.Serializer):
    """Serializer for vendor verification by admin."""
    verification_status = serializers.ChoiceField(choices=Vendor.VERIFICATION_STATUS_CHOICES)
    verification_notes = serializers.CharField(required=False, allow_blank=True)