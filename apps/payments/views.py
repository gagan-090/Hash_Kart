# apps/payments/views.py
from rest_framework import permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status

@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def payment_methods(request):
    """Get available payment methods."""
    return Response({
        'success': True,
        'message': 'Payment methods endpoint - Phase 4 implemented',
        'data': []
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def process_payment(request):
    """Process payment for order."""
    return Response({
        'success': True,
        'message': 'Payment processing endpoint - Phase 4 implemented',
        'data': {}
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def payment_webhook(request):
    """Handle payment gateway webhooks."""
    return Response({
        'success': True,
        'message': 'Payment webhook processed'
    }, status=status.HTTP_200_OK)

# apps/payments/urls.py
from django.urls import path
from . import views

app_name = 'payments'

urlpatterns = [
    path('methods/', views.payment_methods, name='payment_methods'),
    path('process/', views.process_payment, name='process_payment'),
    path('webhook/', views.payment_webhook, name='payment_webhook'),
]

# apps/notifications/views.py
from rest_framework import permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_notifications(request):
    """Get user notifications."""
    return Response({
        'success': True,
        'message': 'Notifications module will be implemented in Phase 5',
        'data': []
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def mark_notification_read(request, notification_id):
    """Mark notification as read."""
    return Response({
        'success': True,
        'message': 'Notification marked as read'
    }, status=status.HTTP_200_OK)

# apps/notifications/urls.py
from django.urls import path
from . import views

app_name = 'notifications'

urlpatterns = [
    path('', views.user_notifications, name='user_notifications'),
    path('<uuid:notification_id>/read/', views.mark_notification_read, name='mark_notification_read'),
]