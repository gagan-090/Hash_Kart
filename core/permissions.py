# core/permissions.py
from rest_framework import permissions

class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object to edit it.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed for any request,
        # so we'll always allow GET, HEAD or OPTIONS requests.
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions are only allowed to the owner of the object.
        return obj.user == request.user


class IsVendorOrReadOnly(permissions.BasePermission):
    """
    Custom permission for vendor-specific actions.
    """
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        
        return (
            request.user.is_authenticated and 
            request.user.user_type in ['vendor', 'admin']
        )
    
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Admin can edit any vendor
        if request.user.user_type == 'admin':
            return True
        
        # Vendor can only edit their own profile
        return hasattr(obj, 'user') and obj.user == request.user


class IsCustomerOnly(permissions.BasePermission):
    """
    Permission for customer-only actions.
    """
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and 
            request.user.user_type == 'customer'
        )


class IsVendorOnly(permissions.BasePermission):
    """
    Permission for vendor-only actions.
    """
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and 
            request.user.user_type == 'vendor'
        )


class IsAdminOnly(permissions.BasePermission):
    """
    Permission for admin-only actions.
    """
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and 
            request.user.user_type == 'admin'
        )


class IsVerifiedVendor(permissions.BasePermission):
    """
    Permission for verified vendors only.
    """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        if request.user.user_type != 'vendor':
            return False
        
        if not hasattr(request.user, 'vendor_profile'):
            return False
        
        return request.user.vendor_profile.is_verified


