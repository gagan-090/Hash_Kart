# apps/notifications/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
import uuid

User = get_user_model()

class NotificationTemplate(models.Model):
    """Templates for different types of notifications."""
    NOTIFICATION_TYPE_CHOICES = [
        ('order_created', 'Order Created'),
        ('order_confirmed', 'Order Confirmed'),
        ('order_shipped', 'Order Shipped'),
        ('order_delivered', 'Order Delivered'),
        ('order_cancelled', 'Order Cancelled'),
        ('payment_successful', 'Payment Successful'),
        ('payment_failed', 'Payment Failed'),
        ('return_requested', 'Return Requested'),
        ('return_approved', 'Return Approved'),
        ('return_rejected', 'Return Rejected'),
        ('product_back_in_stock', 'Product Back in Stock'),
        ('vendor_new_order', 'Vendor New Order'),
        ('vendor_payment_received', 'Vendor Payment Received'),
        ('user_registered', 'User Registered'),
        ('password_reset', 'Password Reset'),
        ('promotional', 'Promotional'),
        ('system_maintenance', 'System Maintenance'),
    ]
    
    CHANNEL_CHOICES = [
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('push', 'Push Notification'),
        ('in_app', 'In-App Notification'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPE_CHOICES)
    channel = models.CharField(max_length=20, choices=CHANNEL_CHOICES)
    
    # Template content
    subject = models.CharField(max_length=255, blank=True)  # For email/push
    title = models.CharField(max_length=255, blank=True)    # For push/in-app
    content = models.TextField()
    html_content = models.TextField(blank=True)  # For email
    
    # Template variables (JSON format)
    variables = models.JSONField(default=list, blank=True)
    
    # Settings
    is_active = models.BooleanField(default=True)
    is_default = models.BooleanField(default=False)
    
    # Scheduling
    send_immediately = models.BooleanField(default=True)
    delay_minutes = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notification_templates'
        unique_together = ['notification_type', 'channel', 'is_default']
        ordering = ['notification_type', 'channel']
    
    def __str__(self):
        return f"{self.name} ({self.channel})"
    
    def render_content(self, context):
        """Render template content with context variables."""
        import re
        
        # Simple template variable substitution
        content = self.content
        html_content = self.html_content
        subject = self.subject
        title = self.title
        
        for key, value in context.items():
            placeholder = f"{{{{{key}}}}}"
            content = content.replace(placeholder, str(value))
            html_content = html_content.replace(placeholder, str(value))
            subject = subject.replace(placeholder, str(value))
            title = title.replace(placeholder, str(value))
        
        return {
            'content': content,
            'html_content': html_content,
            'subject': subject,
            'title': title
        }

class Notification(models.Model):
    """Individual notifications sent to users."""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('read', 'Read'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    template = models.ForeignKey(NotificationTemplate, on_delete=models.SET_NULL, null=True, blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    
    # Notification content
    title = models.CharField(max_length=255)
    message = models.TextField()
    channel = models.CharField(max_length=20, choices=NotificationTemplate.CHANNEL_CHOICES)
    
    # Related object (generic foreign key)
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, null=True, blank=True)
    object_id = models.UUIDField(null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Metadata
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='normal')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Delivery tracking
    sent_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    # Additional data
    data = models.JSONField(default=dict, blank=True)  # Extra data for frontend
    error_message = models.TextField(blank=True)
    retry_count = models.PositiveIntegerField(default=0)
    max_retries = models.PositiveIntegerField(default=3)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['channel', 'status']),
            models.Index(fields=['created_at']),
            models.Index(fields=['priority', 'status']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.user.email}"
    
    def mark_as_read(self):
        """Mark notification as read."""
        if self.status != 'read':
            self.status = 'read'
            self.read_at = timezone.now()
            self.save(update_fields=['status', 'read_at'])
    
    def mark_as_sent(self):
        """Mark notification as sent."""
        from django.utils import timezone
        self.status = 'sent'
        self.sent_at = timezone.now()
        self.save(update_fields=['status', 'sent_at'])
    
    def mark_as_delivered(self):
        """Mark notification as delivered."""
        from django.utils import timezone
        self.status = 'delivered'
        self.delivered_at = timezone.now()
        self.save(update_fields=['status', 'delivered_at'])
    
    def mark_as_failed(self, error_message):
        """Mark notification as failed."""
        self.status = 'failed'
        self.error_message = error_message
        self.retry_count += 1
        self.save(update_fields=['status', 'error_message', 'retry_count'])
    
    @property
    def can_retry(self):
        return self.retry_count < self.max_retries and self.status == 'failed'

class NotificationPreference(models.Model):
    """User notification preferences."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')
    
    # Email preferences
    email_order_updates = models.BooleanField(default=True)
    email_promotional = models.BooleanField(default=False)
    email_newsletter = models.BooleanField(default=False)
    email_security_alerts = models.BooleanField(default=True)
    
    # SMS preferences
    sms_order_updates = models.BooleanField(default=False)
    sms_delivery_updates = models.BooleanField(default=False)
    sms_security_alerts = models.BooleanField(default=False)
    
    # Push notification preferences
    push_order_updates = models.BooleanField(default=True)
    push_promotional = models.BooleanField(default=False)
    push_new_features = models.BooleanField(default=True)
    push_security_alerts = models.BooleanField(default=True)
    
    # In-app notification preferences
    in_app_order_updates = models.BooleanField(default=True)
    in_app_promotional = models.BooleanField(default=True)
    in_app_social = models.BooleanField(default=True)
    
    # Global settings
    do_not_disturb_start = models.TimeField(null=True, blank=True)  # e.g., 22:00
    do_not_disturb_end = models.TimeField(null=True, blank=True)    # e.g., 08:00
    timezone = models.CharField(max_length=50, default='Asia/Kolkata')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notification_preferences'
    
    def __str__(self):
        return f"Notification preferences for {self.user.email}"
    
    def is_channel_enabled(self, channel, notification_type):
        """Check if a specific channel is enabled for notification type."""
        if channel == 'email':
            if 'order' in notification_type:
                return self.email_order_updates
            elif 'promotional' in notification_type:
                return self.email_promotional
            elif 'security' in notification_type:
                return self.email_security_alerts
            return True
        
        elif channel == 'sms':
            if 'order' in notification_type:
                return self.sms_order_updates
            elif 'delivery' in notification_type:
                return self.sms_delivery_updates
            elif 'security' in notification_type:
                return self.sms_security_alerts
            return False
        
        elif channel == 'push':
            if 'order' in notification_type:
                return self.push_order_updates
            elif 'promotional' in notification_type:
                return self.push_promotional
            elif 'security' in notification_type:
                return self.push_security_alerts
            return self.push_new_features
        
        elif channel == 'in_app':
            if 'order' in notification_type:
                return self.in_app_order_updates
            elif 'promotional' in notification_type:
                return self.in_app_promotional
            return self.in_app_social
        
        return True

class PushNotificationDevice(models.Model):
    """User devices for push notifications."""
    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
        ('web', 'Web'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='push_devices')
    
    # Device information
    device_token = models.TextField(unique=True)
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES)
    device_id = models.CharField(max_length=255, blank=True)
    device_name = models.CharField(max_length=255, blank=True)
    app_version = models.CharField(max_length=50, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(auto_now=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'push_notification_devices'
        unique_together = ['user', 'device_token']
        ordering = ['-last_used']
    
    def __str__(self):
        return f"{self.user.email} - {self.platform} - {self.device_name}"

class NotificationBatch(models.Model):
    """Batch notifications for bulk sending."""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    template = models.ForeignKey(NotificationTemplate, on_delete=models.CASCADE)
    
    # Target users
    user_filter = models.JSONField(default=dict, blank=True)  # Filter criteria
    total_recipients = models.PositiveIntegerField(default=0)
    
    # Execution
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    scheduled_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Results
    sent_count = models.PositiveIntegerField(default=0)
    failed_count = models.PositiveIntegerField(default=0)
    error_details = models.JSONField(default=dict, blank=True)
    
    # Settings
    context_data = models.JSONField(default=dict, blank=True)  # Template context
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notification_batches'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.status}"

class NotificationAnalytics(models.Model):
    """Daily analytics for notifications."""
    date = models.DateField(unique=True)
    
    # Send statistics
    total_sent = models.PositiveIntegerField(default=0)
    email_sent = models.PositiveIntegerField(default=0)
    sms_sent = models.PositiveIntegerField(default=0)
    push_sent = models.PositiveIntegerField(default=0)
    in_app_sent = models.PositiveIntegerField(default=0)
    
    # Delivery statistics
    total_delivered = models.PositiveIntegerField(default=0)
    email_delivered = models.PositiveIntegerField(default=0)
    sms_delivered = models.PositiveIntegerField(default=0)
    push_delivered = models.PositiveIntegerField(default=0)
    
    # Engagement statistics
    total_opened = models.PositiveIntegerField(default=0)
    email_opened = models.PositiveIntegerField(default=0)
    push_opened = models.PositiveIntegerField(default=0)
    in_app_opened = models.PositiveIntegerField(default=0)
    
    # Failure statistics
    total_failed = models.PositiveIntegerField(default=0)
    email_failed = models.PositiveIntegerField(default=0)
    sms_failed = models.PositiveIntegerField(default=0)
    push_failed = models.PositiveIntegerField(default=0)
    
    # Type breakdown
    order_notifications = models.PositiveIntegerField(default=0)
    promotional_notifications = models.PositiveIntegerField(default=0)
    security_notifications = models.PositiveIntegerField(default=0)
    system_notifications = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notification_analytics'
        ordering = ['-date']
    
    def __str__(self):
        return f"Notification analytics for {self.date}"
    
    @property
    def delivery_rate(self):
        if self.total_sent > 0:
            return (self.total_delivered / self.total_sent) * 100
        return 0.0
    
    @property
    def open_rate(self):
        if self.total_delivered > 0:
            return (self.total_opened / self.total_delivered) * 100
        return 0.0

class EmailCampaign(models.Model):
    """Email marketing campaigns."""
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('scheduled', 'Scheduled'),
        ('sending', 'Sending'),
        ('sent', 'Sent'),
        ('paused', 'Paused'),
        ('cancelled', 'Cancelled'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    subject = models.CharField(max_length=255)
    
    # Content
    html_content = models.TextField()
    text_content = models.TextField(blank=True)
    
    # Targeting
    target_users = models.ManyToManyField(User, blank=True, related_name='targeted_email_campaigns')
    user_filter = models.JSONField(default=dict, blank=True)
    
    # Scheduling
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    scheduled_at = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    
    # Results
    total_recipients = models.PositiveIntegerField(default=0)
    sent_count = models.PositiveIntegerField(default=0)
    delivered_count = models.PositiveIntegerField(default=0)
    opened_count = models.PositiveIntegerField(default=0)
    clicked_count = models.PositiveIntegerField(default=0)
    unsubscribed_count = models.PositiveIntegerField(default=0)
    
    # Settings
    track_opens = models.BooleanField(default=True)
    track_clicks = models.BooleanField(default=True)
    
    # Metadata
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='created_email_campaigns')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'email_campaigns'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.status}"