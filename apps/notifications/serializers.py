# apps/notifications/serializers.py
from rest_framework import serializers
from .models import (
    Notification, NotificationTemplate, NotificationPreference,
    PushNotificationDevice, NotificationBatch, EmailCampaign
)

class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for notifications."""
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id', 'title', 'message', 'channel', 'priority', 'status',
            'data', 'created_at', 'read_at', 'time_ago'
        ]
        read_only_fields = ['id', 'created_at', 'read_at']
    
    def get_time_ago(self, obj):
        from django.utils import timezone
        from datetime import timedelta
        
        now = timezone.now()
        diff = now - obj.created_at
        
        if diff.days > 0:
            return f"{diff.days} days ago"
        elif diff.seconds > 3600:
            hours = diff.seconds // 3600
            return f"{hours} hours ago"
        elif diff.seconds > 60:
            minutes = diff.seconds // 60
            return f"{minutes} minutes ago"
        else:
            return "Just now"

class NotificationPreferenceSerializer(serializers.ModelSerializer):
    """Serializer for notification preferences."""
    class Meta:
        model = NotificationPreference
        fields = [
            'email_order_updates', 'email_promotional', 'email_newsletter',
            'email_security_alerts', 'sms_order_updates', 'sms_delivery_updates',
            'sms_security_alerts', 'push_order_updates', 'push_promotional',
            'push_new_features', 'push_security_alerts', 'in_app_order_updates',
            'in_app_promotional', 'in_app_social', 'do_not_disturb_start',
            'do_not_disturb_end', 'timezone'
        ]

class PushDeviceSerializer(serializers.ModelSerializer):
    """Serializer for push notification devices."""
    class Meta:
        model = PushNotificationDevice
        fields = [
            'id', 'device_token', 'platform', 'device_name', 'app_version',
            'is_active', 'last_used', 'created_at'
        ]
        read_only_fields = ['id', 'last_used', 'created_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        
        # Deactivate existing devices with same token
        PushNotificationDevice.objects.filter(
            device_token=validated_data['device_token']
        ).update(is_active=False)
        
        return super().create(validated_data)

class NotificationTemplateSerializer(serializers.ModelSerializer):
    """Serializer for notification templates."""
    class Meta:
        model = NotificationTemplate
        fields = [
            'id', 'name', 'notification_type', 'channel', 'subject',
            'title', 'content', 'html_content', 'variables', 'is_active',
            'send_immediately', 'delay_minutes'
        ]

class BulkNotificationSerializer(serializers.Serializer):
    """Serializer for sending bulk notifications."""
    title = serializers.CharField(max_length=255)
    message = serializers.CharField()
    notification_type = serializers.CharField(max_length=50)
    channels = serializers.ListField(
        child=serializers.ChoiceField(choices=['email', 'sms', 'push', 'in_app'])
    )
    user_filter = serializers.JSONField(required=False)
    scheduled_at = serializers.DateTimeField(required=False)
    
    def validate_user_filter(self, value):
        # Validate user filter criteria
        allowed_filters = ['user_type', 'location', 'registration_date', 'order_count']
        if value:
            for key in value.keys():
                if key not in allowed_filters:
                    raise serializers.ValidationError(f"Invalid filter: {key}")
        return value

