# apps/users/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, UserAddress, UserPreference

class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'first_name', 'last_name', 'user_type', 'is_staff', 'is_active')
    list_filter = ('user_type', 'is_staff', 'is_active')
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'user_type', 'phone', 'date_of_birth', 'profile_image')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Verification', {'fields': ('is_email_verified', 'is_phone_verified')}),
        ('Important dates', {'fields': ('last_login', 'created_at', 'updated_at')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'first_name', 'last_name', 'password1', 'password2'),
        }),
    )
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)
    readonly_fields = ('created_at', 'updated_at')

class UserAddressAdmin(admin.ModelAdmin):
    list_display = ('user', 'address_type', 'city', 'state', 'country', 'is_default')
    list_filter = ('address_type', 'city', 'state', 'country')
    search_fields = ('user__email', 'address_line_1', 'city', 'postal_code')
    readonly_fields = ('created_at', 'updated_at')

class UserPreferenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'language', 'currency', 'email_notifications')
    search_fields = ('user__email',)
    readonly_fields = ('created_at', 'updated_at')

admin.site.register(User, CustomUserAdmin)
admin.site.register(UserAddress, UserAddressAdmin)
admin.site.register(UserPreference, UserPreferenceAdmin)