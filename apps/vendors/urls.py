# apps/vendors/urls.py
from django.urls import path
from . import views

app_name = 'vendors'

urlpatterns = [
    # Vendor registration and profile
    path('register/', views.VendorRegistrationView.as_view(), name='vendor_register'),
    path('profile/', views.VendorProfileView.as_view(), name='vendor_profile'),
    path('dashboard/', views.vendor_dashboard, name='vendor_dashboard'),
    
    # Public vendor listings
    path('', views.VendorListView.as_view(), name='vendor_list'),
    path('<uuid:pk>/', views.VendorDetailView.as_view(), name='vendor_detail'),
    
    # Vendor documents
    path('documents/', views.VendorDocumentListCreateView.as_view(), name='vendor_documents'),
    path('documents/<uuid:pk>/', views.VendorDocumentDetailView.as_view(), name='vendor_document_detail'),
    path('upload-document/', views.upload_vendor_document, name='upload_document'),
    
    # Vendor bank accounts
    path('bank-accounts/', views.VendorBankAccountListCreateView.as_view(), name='bank_accounts'),
    path('bank-accounts/<uuid:pk>/', views.VendorBankAccountDetailView.as_view(), name='bank_account_detail'),
    path('bank-accounts/<uuid:account_id>/set-primary/', views.set_primary_bank_account, name='set_primary_account'),
    
    # Vendor settings
    path('settings/', views.VendorSettingView.as_view(), name='vendor_settings'),
    
    # Admin endpoints for vendor management
    path('admin/pending/', views.pending_vendors, name='pending_vendors'),
    path('admin/<uuid:vendor_id>/verify/', views.verify_vendor, name='verify_vendor'),
    path('admin/<uuid:vendor_id>/documents/', views.vendor_documents, name='admin_vendor_documents'),
    path('admin/documents/<uuid:document_id>/verify/', views.verify_vendor_document, name='verify_document'),
]