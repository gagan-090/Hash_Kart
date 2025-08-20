# apps/authentication/urls.py
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

app_name = 'authentication'

urlpatterns = [
    # Authentication endpoints
    path('register/', views.register_user, name='register'),
    path('login/', views.CustomTokenObtainPairView.as_view(), name='login'),
    path('logout/', views.logout_user, name='logout'),
    path('logout-all/', views.logout_all_devices, name='logout_all'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Email verification
    path('verify-email/', views.verify_email, name='verify_email'),
    path('resend-verification/', views.resend_verification_email, name='resend_verification'),
    
    # Password reset
    path('password-reset/', views.request_password_reset, name='password_reset'),
    path('password-reset-confirm/', views.confirm_password_reset, name='password_reset_confirm'),
    
    # OTP verification
    path('otp/request/', views.request_otp, name='request_otp'),
    path('otp/verify/', views.verify_otp, name='verify_otp'),
    
    # Session management
    path('sessions/', views.get_user_sessions, name='user_sessions'),
    
    # Social authentication
    path('social/', views.social_auth, name='social_auth'),
]