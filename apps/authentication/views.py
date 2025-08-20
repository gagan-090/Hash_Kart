# apps/authentication/views.py
from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.shortcuts import get_object_or_404

from .models import EmailVerificationToken, PasswordResetToken, OTPVerification, UserSession, LoginAttempt
from .serializers import (
    CustomTokenObtainPairSerializer, EmailVerificationSerializer,
    ResendEmailVerificationSerializer, OTPVerificationSerializer,
    OTPRequestSerializer, LogoutSerializer, SocialAuthSerializer
)
from apps.users.serializers import (
    UserRegistrationSerializer, PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer
)
from core.utils import (
    send_verification_email, send_password_reset_email,
    get_client_ip, get_user_agent_info
)

User = get_user_model()

class CustomTokenObtainPairView(TokenObtainPairView):
    """Custom login view with JWT tokens."""
    serializer_class = CustomTokenObtainPairSerializer
    
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        
        if response.status_code == 200:
            # Log successful login attempt
            email = request.data.get('email')
            user = User.objects.filter(email=email).first()
            
            LoginAttempt.objects.create(
                email=email,
                user=user,
                status='success',
                ip_address=get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')
            )
            
            # Create user session
            if user:
                refresh_token = response.data.get('refresh')
                user_agent_info = get_user_agent_info(request)
                
                # Generate a unique session key
                import uuid
                session_key = str(uuid.uuid4())
                
                # Create user session
                UserSession.objects.create(
                    user=user,
                    session_key=session_key,
                    refresh_token=refresh_token,
                    device_type=user_agent_info.get('device_type', ''),
                    ip_address=get_client_ip(request),
                    expires_at=timezone.now() + timezone.timedelta(days=7)
                )
                
                # Update last active
                user.last_active = timezone.now()
                user.save(update_fields=['last_active'])
        
        else:
            # Log failed login attempt
            email = request.data.get('email')
            LoginAttempt.objects.create(
                email=email or '',
                status='failed',
                failure_reason='Invalid credentials',
                ip_address=get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')
            )
        
        return response

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register_user(request):
    """Register a new user."""
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        
        # Create email verification token
        verification_token = EmailVerificationToken.objects.create(user=user)
        
        # Send verification email
        send_verification_email(user, verification_token)
        
        return Response({
            'success': True,
            'message': 'User registered successfully. Please check your email for verification.',
            'data': {
                'user_id': str(user.id),
                'email': user.email,
                'user_type': user.user_type
            }
        }, status=status.HTTP_201_CREATED)
    
    return Response({
        'success': False,
        'message': 'Registration failed',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def verify_email(request):
    """Verify user email address."""
    serializer = EmailVerificationSerializer(data=request.data)
    
    if serializer.is_valid():
        token_value = serializer.validated_data['token']
        
        try:
            token = EmailVerificationToken.objects.get(token=token_value)
            
            if token.is_valid:
                # Mark token as used
                token.is_used = True
                token.save()
                
                # Mark user email as verified
                user = token.user
                user.is_email_verified = True
                user.save()
                
                return Response({
                    'success': True,
                    'message': 'Email verified successfully',
                    'data': {
                        'user_id': str(user.id),
                        'email': user.email,
                        'is_verified': True
                    }
                }, status=status.HTTP_200_OK)
            
            else:
                return Response({
                    'success': False,
                    'message': 'Invalid or expired verification token'
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except EmailVerificationToken.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Invalid verification token'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def resend_verification_email(request):
    """Resend email verification."""
    serializer = ResendEmailVerificationSerializer(data=request.data)
    
    if serializer.is_valid():
        email = serializer.validated_data['email']
        user = User.objects.get(email=email)
        
        # Invalidate old tokens
        EmailVerificationToken.objects.filter(user=user, is_used=False).update(is_used=True)
        
        # Create new verification token
        verification_token = EmailVerificationToken.objects.create(user=user)
        
        # Send verification email
        send_verification_email(user, verification_token)
        
        return Response({
            'success': True,
            'message': 'Verification email sent successfully'
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def request_password_reset(request):
    """Request password reset."""
    serializer = PasswordResetRequestSerializer(data=request.data)
    
    if serializer.is_valid():
        email = serializer.validated_data['email']
        user = User.objects.get(email=email)
        
        # Invalidate old tokens
        PasswordResetToken.objects.filter(user=user, is_used=False).update(is_used=True)
        
        # Create new reset token
        reset_token = PasswordResetToken.objects.create(user=user)
        
        # Send reset email
        send_password_reset_email(user, reset_token)
        
        return Response({
            'success': True,
            'message': 'Password reset email sent successfully'
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def confirm_password_reset(request):
    """Confirm password reset."""
    serializer = PasswordResetConfirmSerializer(data=request.data)
    
    if serializer.is_valid():
        token_value = serializer.validated_data['token']
        new_password = serializer.validated_data['new_password']
        
        try:
            token = PasswordResetToken.objects.get(token=token_value)
            
            if token.is_valid:
                # Reset password
                user = token.user
                user.set_password(new_password)
                user.save()
                
                # Mark token as used
                token.is_used = True
                token.save()
                
                # Invalidate all user sessions
                UserSession.objects.filter(user=user).update(is_active=False)
                
                return Response({
                    'success': True,
                    'message': 'Password reset successfully'
                }, status=status.HTTP_200_OK)
            
            else:
                return Response({
                    'success': False,
                    'message': 'Invalid or expired reset token'
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except PasswordResetToken.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Invalid reset token'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def request_otp(request):
    """Request OTP for verification."""
    serializer = OTPRequestSerializer(data=request.data)
    
    if serializer.is_valid():
        otp_type = serializer.validated_data['otp_type']
        
        # Invalidate existing OTPs
        OTPVerification.objects.filter(
            user=request.user,
            otp_type=otp_type,
            is_verified=False
        ).update(is_expired=True)
        
        # Create new OTP
        otp = OTPVerification.objects.create(
            user=request.user,
            otp_type=otp_type,
            phone_number=serializer.validated_data.get('phone_number', ''),
            email=serializer.validated_data.get('email', request.user.email)
        )
        
        # Here you would send the OTP via SMS or email
        # For now, we'll just return success
        
        return Response({
            'success': True,
            'message': 'OTP sent successfully',
            'data': {
                'otp_id': str(otp.id),
                'expires_at': otp.expires_at
            }
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def verify_otp(request):
    """Verify OTP."""
    serializer = OTPVerificationSerializer(data=request.data)
    
    if serializer.is_valid():
        otp_code = serializer.validated_data['otp_code']
        otp_type = serializer.validated_data['otp_type']
        
        try:
            otp = OTPVerification.objects.get(
                user=request.user,
                otp_type=otp_type,
                is_verified=False,
                is_expired=False
            )
            
            is_valid, message = otp.verify_otp(otp_code)
            
            if is_valid:
                # Update user verification status if needed
                if otp_type == 'phone_verification':
                    request.user.is_phone_verified = True
                    request.user.save()
                
                return Response({
                    'success': True,
                    'message': message
                }, status=status.HTTP_200_OK)
            
            else:
                return Response({
                    'success': False,
                    'message': message
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except OTPVerification.DoesNotExist:
            return Response({
                'success': False,
                'message': 'No valid OTP found'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_user(request):
    """Logout user."""
    serializer = LogoutSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            serializer.save()
            
            # Deactivate user session
            refresh_token = request.data.get('refresh')
            UserSession.objects.filter(
                user=request.user,
                refresh_token=refresh_token
            ).update(is_active=False)
            
            return Response({
                'success': True,
                'message': 'Logged out successfully'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Logout failed'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_all_devices(request):
    """Logout from all devices."""
    try:
        # Get all refresh tokens for the user and blacklist them
        sessions = UserSession.objects.filter(user=request.user, is_active=True)
        
        for session in sessions:
            try:
                token = RefreshToken(session.refresh_token)
                token.blacklist()
            except:
                pass  # Token might already be expired or invalid
        
        # Deactivate all user sessions
        sessions.update(is_active=False)
        
        return Response({
            'success': True,
            'message': 'Logged out from all devices successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Logout failed'
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_user_sessions(request):
    """Get user active sessions."""
    sessions = UserSession.objects.filter(user=request.user, is_active=True)
    
    session_data = []
    for session in sessions:
        session_data.append({
            'id': str(session.id),
            'device_type': session.device_type,
            'device_name': session.device_name,
            'ip_address': session.ip_address,
            'country': session.country,
            'city': session.city,
            'last_activity': session.last_activity,
            'created_at': session.created_at,
            'is_current': session.refresh_token in str(request.auth)
        })
    
    return Response({
        'success': True,
        'data': session_data
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def social_auth(request):
    """Social authentication (Google, Facebook, Apple)."""
    serializer = SocialAuthSerializer(data=request.data)
    
    if serializer.is_valid():
        provider = serializer.validated_data['provider']
        access_token = serializer.validated_data['access_token']
        
        # Here you would implement the actual social auth logic
        # For now, we'll return a placeholder response
        
        return Response({
            'success': True,
            'message': f'{provider.title()} authentication successful',
            'data': {
                'message': 'Social auth implementation needed'
            }
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)