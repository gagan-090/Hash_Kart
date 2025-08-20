# apps/vendors/views.py
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .models import Vendor, VendorDocument, VendorBankAccount, VendorSetting
from .serializers import (
    VendorRegistrationSerializer, VendorProfileSerializer, VendorListSerializer,
    VendorDocumentSerializer, VendorBankAccountSerializer, VendorSettingSerializer,
    VendorDashboardSerializer, VendorVerificationSerializer
)
from core.permissions import IsVendorOnly, IsAdminOnly, IsVendorOrReadOnly
from core.utils import send_vendor_approval_email

class VendorRegistrationView(generics.CreateAPIView):
    """Register as a vendor."""
    serializer_class = VendorRegistrationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        # Check if user is already a vendor
        if hasattr(self.request.user, 'vendor_profile'):
            return Response({
                'success': False,
                'message': 'User is already registered as a vendor'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Update user type to vendor
        user = self.request.user
        user.user_type = 'vendor'
        user.save()
        
        # Create vendor profile
        vendor = serializer.save()
        
        # Create vendor settings
        VendorSetting.objects.create(vendor=vendor)
        
        return Response({
            'success': True,
            'message': 'Vendor registration successful. Your account is under review.',
            'data': VendorProfileSerializer(vendor).data
        }, status=status.HTTP_201_CREATED)

class VendorProfileView(generics.RetrieveUpdateAPIView):
    """Get and update vendor profile."""
    serializer_class = VendorProfileSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_object(self):
        return get_object_or_404(Vendor, user=self.request.user)

class VendorListView(generics.ListAPIView):
    """List all verified vendors."""
    serializer_class = VendorListSerializer
    permission_classes = [permissions.AllowAny]
    
    def get_queryset(self):
        queryset = Vendor.objects.filter(is_active=True, verification_status='verified')
        
        # Filter by location
        city = self.request.query_params.get('city')
        state = self.request.query_params.get('state')
        
        if city:
            queryset = queryset.filter(city__icontains=city)
        if state:
            queryset = queryset.filter(state__icontains=state)
        
        # Filter by business type
        business_type = self.request.query_params.get('business_type')
        if business_type:
            queryset = queryset.filter(business_type=business_type)
        
        # Search by business name
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(business_name__icontains=search)
        
        return queryset.order_by('-average_rating', '-created_at')

class VendorDetailView(generics.RetrieveAPIView):
    """Get vendor details by ID."""
    serializer_class = VendorProfileSerializer
    permission_classes = [permissions.AllowAny]
    queryset = Vendor.objects.filter(is_active=True, verification_status='verified')

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def vendor_dashboard(request):
    """Get vendor dashboard data."""
    vendor = get_object_or_404(Vendor, user=request.user)
    
    dashboard_data = VendorDashboardSerializer(vendor).data
    
    return Response({
        'success': True,
        'data': dashboard_data
    }, status=status.HTTP_200_OK)

class VendorDocumentListCreateView(generics.ListCreateAPIView):
    """List and upload vendor documents."""
    serializer_class = VendorDocumentSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        vendor = get_object_or_404(Vendor, user=self.request.user)
        return VendorDocument.objects.filter(vendor=vendor)
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        vendor = get_object_or_404(Vendor, user=self.request.user)
        context['vendor'] = vendor
        return context

class VendorDocumentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete vendor document."""
    serializer_class = VendorDocumentSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        vendor = get_object_or_404(Vendor, user=self.request.user)
        return VendorDocument.objects.filter(vendor=vendor)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def upload_vendor_document(request):
    """Upload vendor verification document."""
    if 'document_file' not in request.FILES:
        return Response({
            'success': False,
            'message': 'No document file provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate document file
    from core.utils import validate_document_file
    document_file = request.FILES['document_file']
    is_valid, message = validate_document_file(document_file)
    
    if not is_valid:
        return Response({
            'success': False,
            'message': message
        }, status=status.HTTP_400_BAD_REQUEST)
    
    vendor = get_object_or_404(Vendor, user=request.user)
    
    # Create document entry
    document_data = {
        'document_type': request.data.get('document_type'),
        'document_name': request.data.get('document_name'),
        'document_file': document_file
    }
    
    serializer = VendorDocumentSerializer(data=document_data, context={'vendor': vendor})
    
    if serializer.is_valid():
        serializer.save()
        return Response({
            'success': True,
            'message': 'Document uploaded successfully',
            'data': serializer.data
        }, status=status.HTTP_201_CREATED)
    
    return Response({
        'success': False,
        'message': 'Document upload failed',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

class VendorBankAccountListCreateView(generics.ListCreateAPIView):
    """List and create vendor bank accounts."""
    serializer_class = VendorBankAccountSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        vendor = get_object_or_404(Vendor, user=self.request.user)
        return VendorBankAccount.objects.filter(vendor=vendor)
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        vendor = get_object_or_404(Vendor, user=self.request.user)
        context['vendor'] = vendor
        return context

class VendorBankAccountDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete vendor bank account."""
    serializer_class = VendorBankAccountSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        vendor = get_object_or_404(Vendor, user=self.request.user)
        return VendorBankAccount.objects.filter(vendor=vendor)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def set_primary_bank_account(request, account_id):
    """Set primary bank account."""
    vendor = get_object_or_404(Vendor, user=request.user)
    account = get_object_or_404(VendorBankAccount, id=account_id, vendor=vendor)
    
    # Remove primary flag from other accounts
    VendorBankAccount.objects.filter(vendor=vendor, is_primary=True).update(is_primary=False)
    
    # Set this account as primary
    account.is_primary = True
    account.save()
    
    return Response({
        'success': True,
        'message': 'Primary bank account updated successfully'
    }, status=status.HTTP_200_OK)

class VendorSettingView(generics.RetrieveUpdateAPIView):
    """Get and update vendor settings."""
    serializer_class = VendorSettingSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_object(self):
        vendor = get_object_or_404(Vendor, user=self.request.user)
        setting, created = VendorSetting.objects.get_or_create(vendor=vendor)
        return setting

# Admin views for vendor management
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def pending_vendors(request):
    """Get list of pending vendor verifications."""
    vendors = Vendor.objects.filter(verification_status='pending').order_by('-created_at')
    serializer = VendorListSerializer(vendors, many=True)
    
    return Response({
        'success': True,
        'data': serializer.data
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def verify_vendor(request, vendor_id):
    """Verify or reject vendor."""
    vendor = get_object_or_404(Vendor, id=vendor_id)
    serializer = VendorVerificationSerializer(data=request.data)
    
    if serializer.is_valid():
        verification_status = serializer.validated_data['verification_status']
        verification_notes = serializer.validated_data.get('verification_notes', '')
        
        vendor.verification_status = verification_status
        vendor.verification_notes = verification_notes
        
        if verification_status == 'verified':
            vendor.verified_at = timezone.now()
            # Send approval email
            send_vendor_approval_email(vendor)
        
        vendor.save()
        
        return Response({
            'success': True,
            'message': f'Vendor {verification_status} successfully',
            'data': VendorProfileSerializer(vendor).data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Invalid data',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def vendor_documents(request, vendor_id):
    """Get vendor documents for verification."""
    vendor = get_object_or_404(Vendor, id=vendor_id)
    documents = VendorDocument.objects.filter(vendor=vendor)
    serializer = VendorDocumentSerializer(documents, many=True)
    
    return Response({
        'success': True,
        'data': serializer.data
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def verify_vendor_document(request, document_id):
    """Verify or reject vendor document."""
    document = get_object_or_404(VendorDocument, id=document_id)
    
    verification_status = request.data.get('verification_status')
    verification_notes = request.data.get('verification_notes', '')
    
    if verification_status not in ['approved', 'rejected']:
        return Response({
            'success': False,
            'message': 'Invalid verification status'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    document.verification_status = verification_status
    document.verification_notes = verification_notes
    document.verified_by = request.user
    document.verified_at = timezone.now()
    document.save()
    
    return Response({
        'success': True,
        'message': f'Document {verification_status} successfully'
    }, status=status.HTTP_200_OK)