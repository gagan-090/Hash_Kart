# apps/notifications/views.py
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Count, Q
from django.utils import timezone
from datetime import timedelta

from .models import (
    Notification, NotificationPreference, PushNotificationDevice,
    NotificationTemplate, NotificationAnalytics
)
from .serializers import (
    NotificationSerializer, NotificationPreferenceSerializer,
    PushDeviceSerializer, BulkNotificationSerializer
)
from .services import NotificationService, AnalyticsService
from core.permissions import IsAdminOnly

class UserNotificationListView(generics.ListAPIView):
    """List user's notifications."""
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = Notification.objects.filter(user=user)
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by channel
        channel = self.request.query_params.get('channel')
        if channel:
            queryset = queryset.filter(channel=channel)
        
        # Filter by priority
        priority = self.request.query_params.get('priority')
        if priority:
            queryset = queryset.filter(priority=priority)
        
        return queryset.order_by('-created_at')

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def mark_notification_read(request, notification_id):
    """Mark notification as read."""
    try:
        notification = Notification.objects.get(
            id=notification_id,
            user=request.user
        )
        notification.mark_as_read()
        
        # Track analytics
        AnalyticsService.track_notification_opened(notification.channel)
        
        return Response({
            'success': True,
            'message': 'Notification marked as read'
        })
    except Notification.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Notification not found'
        }, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def mark_all_notifications_read(request):
    """Mark all notifications as read."""
    updated_count = Notification.objects.filter(
        user=request.user,
        status__in=['sent', 'delivered']
    ).update(
        status='read',
        read_at=timezone.now()
    )
    
    return Response({
        'success': True,
        'message': f'{updated_count} notifications marked as read'
    })

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def notification_summary(request):
    """Get notification summary for user."""
    user = request.user
    
    # Get counts by status
    notifications = Notification.objects.filter(user=user)
    
    summary = {
        'total': notifications.count(),
        'unread': notifications.filter(status__in=['sent', 'delivered']).count(),
        'read': notifications.filter(status='read').count(),
        'by_channel': dict(
            notifications.values('channel').annotate(count=Count('id'))
            .values_list('channel', 'count')
        ),
        'by_priority': dict(
            notifications.values('priority').annotate(count=Count('id'))
            .values_list('priority', 'count')
        ),
        'recent_notifications': NotificationSerializer(
            notifications.order_by('-created_at')[:5], many=True
        ).data
    }
    
    return Response({
        'success': True,
        'data': summary
    })

class NotificationPreferenceView(generics.RetrieveUpdateAPIView):
    """Get and update notification preferences."""
    serializer_class = NotificationPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        preference, created = NotificationPreference.objects.get_or_create(
            user=self.request.user
        )
        return preference

class PushDeviceListCreateView(generics.ListCreateAPIView):
    """List and register push notification devices."""
    serializer_class = PushDeviceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return PushNotificationDevice.objects.filter(
            user=self.request.user,
            is_active=True
        )

@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def unregister_push_device(request, device_id):
    """Unregister push notification device."""
    try:
        device = PushNotificationDevice.objects.get(
            id=device_id,
            user=request.user
        )
        device.is_active = False
        device.save()
        
        return Response({
            'success': True,
            'message': 'Device unregistered successfully'
        })
    except PushNotificationDevice.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Device not found'
        }, status=status.HTTP_404_NOT_FOUND)

# Admin notification management
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def send_bulk_notification(request):
    """Send bulk notification to users."""
    serializer = BulkNotificationSerializer(data=request.data)
    
    if serializer.is_valid():
        data = serializer.validated_data
        
        # Get target users based on filter
        from django.contrib.auth import get_user_model
        User = get_user_model()
        
        users = User.objects.filter(is_active=True)
        
        # Apply filters
        user_filter = data.get('user_filter', {})
        if user_filter.get('user_type'):
            users = users.filter(user_type=user_filter['user_type'])
        
        if user_filter.get('location'):
            # Filter by user location if available
            pass
        
        # Create notifications for each user
        notification_count = 0
        for user in users:
            notification = NotificationService.create_notification(
                user=user,
                notification_type=data['notification_type'],
                title=data['title'],
                message=data['message'],
                priority='normal'
            )
            if notification:
                notification_count += 1
        
        return Response({
            'success': True,
            'message': f'Bulk notification sent to {notification_count} users'
        })
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def notification_analytics(request):
    """Get notification analytics."""
    # Get date range
    days = int(request.query_params.get('days', 30))
    end_date = timezone.now().date()
    start_date = end_date - timedelta(days=days)
    
    # Get analytics data
    analytics = NotificationAnalytics.objects.filter(
        date__range=[start_date, end_date]
    ).order_by('date')
    
    # Aggregate data
    total_sent = sum(a.total_sent for a in analytics)
    total_delivered = sum(a.total_delivered for a in analytics)
    total_opened = sum(a.total_opened for a in analytics)
    
    delivery_rate = (total_delivered / total_sent * 100) if total_sent > 0 else 0
    open_rate = (total_opened / total_delivered * 100) if total_delivered > 0 else 0
    
    # Channel breakdown
    channel_stats = {
        'email': {
            'sent': sum(a.email_sent for a in analytics),
            'delivered': sum(a.email_delivered for a in analytics),
            'opened': sum(a.email_opened for a in analytics),
        },
        'sms': {
            'sent': sum(a.sms_sent for a in analytics),
            'delivered': sum(a.sms_delivered for a in analytics),
        },
        'push': {
            'sent': sum(a.push_sent for a in analytics),
            'delivered': sum(a.push_delivered for a in analytics),
            'opened': sum(a.push_opened for a in analytics),
        },
        'in_app': {
            'sent': sum(a.in_app_sent for a in analytics),
            'opened': sum(a.in_app_opened for a in analytics),
        }
    }
    
    # Daily trends
    daily_trends = [
        {
            'date': a.date.isoformat(),
            'sent': a.total_sent,
            'delivered': a.total_delivered,
            'opened': a.total_opened,
            'delivery_rate': a.delivery_rate,
            'open_rate': a.open_rate
        }
        for a in analytics
    ]
    
    return Response({
        'success': True,
        'data': {
            'summary': {
                'total_sent': total_sent,
                'total_delivered': total_delivered,
                'total_opened': total_opened,
                'delivery_rate': round(delivery_rate, 2),
                'open_rate': round(open_rate, 2)
            },
            'channel_stats': channel_stats,
            'daily_trends': daily_trends
        }
    })

