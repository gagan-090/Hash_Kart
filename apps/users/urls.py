# apps/users/urls.py
from django.urls import path
from . import views

app_name = 'users'

urlpatterns = [
    # User profile
    path('profile/', views.UserProfileView.as_view(), name='profile'),
    path('change-password/', views.change_password, name='change_password'),
    path('upload-profile-image/', views.upload_profile_image, name='upload_profile_image'),
    path('dashboard/', views.user_dashboard, name='dashboard'),
    path('delete-account/', views.delete_account, name='delete_account'),
    
    # User addresses
    path('addresses/', views.UserAddressListCreateView.as_view(), name='address_list'),
    path('addresses/<uuid:pk>/', views.UserAddressDetailView.as_view(), name='address_detail'),
    path('addresses/<uuid:address_id>/set-default/', views.set_default_address, name='set_default_address'),
    
    # User preferences
    path('preferences/', views.UserPreferenceView.as_view(), name='preferences'),
]