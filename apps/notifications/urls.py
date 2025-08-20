# apps/notifications/urls.py
from django.urls import path
from . import views

app_name = 'notifications'

urlpatterns = [
    # User notifications
    path('', views.UserNotificationListView.as_view(), name='notification_list'),
    path('summary/', views.notification_summary, name='notification_summary'),
    path('<uuid:notification_id>/read/', views.mark_notification_read, name='mark_notification_read'),
    path('mark-all-read/', views.mark_all_notifications_read, name='mark_all_read'),
    
    # Notification preferences
    path('preferences/', views.NotificationPreferenceView.as_view(), name='notification_preferences'),
    
    # Push notification devices
    path('devices/', views.PushDeviceListCreateView.as_view(), name='push_devices'),
    path('devices/<uuid:device_id>/unregister/', views.unregister_push_device, name='unregister_device'),
    
    # Admin notification management
    path('admin/bulk-send/', views.send_bulk_notification, name='send_bulk_notification'),
    path('admin/analytics/', views.notification_analytics, name='notification_analytics'),
]

