# apps/users/views.py
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model

from .models import UserAddress, UserPreference
from .serializers import (
    UserProfileSerializer, UserAddressSerializer, UserPreferenceSerializer,
    ChangePasswordSerializer
)
from core.permissions import IsOwnerOrReadOnly

User = get_user_model()

class UserProfileView(generics.RetrieveUpdateAPIView):
    """Get and update user profile."""
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def change_password(request):
    """Change user password."""
    serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
    
    if serializer.is_valid():
        user = request.user
        new_password = serializer.validated_data['new_password']
        
        # Set new password
        user.set_password(new_password)
        user.save()
        
        return Response({
            'success': True,
            'message': 'Password changed successfully'
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Password change failed',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

class UserAddressListCreateView(generics.ListCreateAPIView):
    """List and create user addresses."""
    serializer_class = UserAddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserAddress.objects.filter(user=self.request.user, is_active=True)

class UserAddressDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete user address."""
    serializer_class = UserAddressSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]
    
    def get_queryset(self):
        return UserAddress.objects.filter(user=self.request.user)
    
    def perform_destroy(self, instance):
        # Soft delete
        instance.is_active = False
        instance.save()

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def set_default_address(request, address_id):
    """Set default address for user."""
    address = get_object_or_404(UserAddress, id=address_id, user=request.user)
    
    # Remove default from other addresses
    UserAddress.objects.filter(user=request.user, is_default=True).update(is_default=False)
    
    # Set this address as default
    address.is_default = True
    address.save()
    
    return Response({
        'success': True,
        'message': 'Default address updated successfully'
    }, status=status.HTTP_200_OK)

class UserPreferenceView(generics.RetrieveUpdateAPIView):
    """Get and update user preferences."""
    serializer_class = UserPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        preference, created = UserPreference.objects.get_or_create(user=self.request.user)
        return preference

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_dashboard(request):
    """Get user dashboard data."""
    user = request.user
    
    # Get basic user stats
    total_addresses = UserAddress.objects.filter(user=user, is_active=True).count()
    
    # Additional dashboard data will be added when we implement other modules
    dashboard_data = {
        'user': UserProfileSerializer(user).data,
        'stats': {
            'total_addresses': total_addresses,
            'total_orders': 0,  # Will be implemented in orders module
            'total_wishlist_items': 0,  # Will be implemented in products module
            'account_created': user.created_at,
            'last_login': user.last_login,
        },
        'recent_activity': [],  # Will be implemented later
    }
    
    return Response({
        'success': True,
        'data': dashboard_data
    }, status=status.HTTP_200_OK)

@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def delete_account(request):
    """Delete user account (soft delete)."""
    user = request.user
    
    # Confirm password before deletion
    password = request.data.get('password')
    if not password or not user.check_password(password):
        return Response({
            'success': False,
            'message': 'Invalid password'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Soft delete user
    user.is_active = False
    user.save()
    
    return Response({
        'success': True,
        'message': 'Account deleted successfully'
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def upload_profile_image(request):
    """Upload user profile image."""
    if 'profile_image' not in request.FILES:
        return Response({
            'success': False,
            'message': 'No image file provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    profile_image = request.FILES['profile_image']
    
    # Validate image file
    from core.utils import validate_image_file
    is_valid, message = validate_image_file(profile_image)
    
    if not is_valid:
        return Response({
            'success': False,
            'message': message
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Update user profile image
    user = request.user
    user.profile_image = profile_image
    user.save()
    
    return Response({
        'success': True,
        'message': 'Profile image uploaded successfully',
        'data': {
            'profile_image_url': user.profile_image.url if user.profile_image else None
        }
    }, status=status.HTTP_200_OK)