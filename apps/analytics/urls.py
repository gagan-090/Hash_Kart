# apps/analytics/urls.py
from django.urls import path
from . import views

app_name = 'analytics'

urlpatterns = [
    # Dashboard analytics
    path('dashboard/admin/', views.admin_dashboard_analytics, name='admin_dashboard'),
    path('dashboard/vendor/', views.vendor_dashboard_analytics, name='vendor_dashboard'),
    
    # User activity
    path('user-activity/', views.user_activity_analytics, name='user_activity'),
    path('track-activity/', views.track_user_activity, name='track_activity'),
    
    # Reports
    path('reports/generate/', views.generate_report, name='generate_report'),
    
    # System metrics
    path('system/health/', views.system_health_metrics, name='system_health'),
    
    # Search analytics
    path('search/', views.search_analytics, name='search_analytics'),
]
