# apps/products/views.py
from rest_framework import generics, permissions, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Q, Count, Avg, Sum
from django.db import transaction
from django_filters.rest_framework import DjangoFilterBackend

from .models import (
    Category, Brand, Product, ProductAttribute, ProductAttributeValue,
    ProductVariation, ProductImage, ProductReview, ProductTag, Wishlist
)
from .serializers import (
    CategorySerializer, CategoryListSerializer, CategoryTreeSerializer,
    BrandSerializer, ProductListSerializer, ProductDetailSerializer,
    ProductCreateUpdateSerializer, ProductVariationSerializer,
    ProductVariationCreateSerializer, ProductAttributeSerializer,
    ProductReviewSerializer, WishlistSerializer, WishlistCreateSerializer,
    ProductSearchSerializer, ProductBulkUpdateSerializer, ProductStatsSerializer
)
from .filters import ProductFilter
from core.permissions import IsVendorOnly, IsVerifiedVendor, IsOwnerOrReadOnly

# Category Views
class CategoryListView(generics.ListCreateAPIView):
    """List and create categories."""
    queryset = Category.objects.filter(is_active=True, parent__isnull=True)
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    ordering = ['sort_order', 'name']
    
    def get_serializer_class(self):
        if self.request.method == 'GET':
            return CategoryListSerializer
        return CategorySerializer

class CategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete category."""
    queryset = Category.objects.filter(is_active=True)
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'slug'

@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def category_tree(request):
    """Get complete category tree structure."""
    categories = Category.objects.filter(is_active=True, parent__isnull=True)
    serializer = CategoryTreeSerializer(categories, many=True)
    return Response({
        'success': True,
        'data': serializer.data
    })

# Brand Views
class BrandListView(generics.ListCreateAPIView):
    """List and create brands."""
    queryset = Brand.objects.filter(is_active=True)
    serializer_class = BrandSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']

class BrandDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete brand."""
    queryset = Brand.objects.filter(is_active=True)
    serializer_class = BrandSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'slug'

# Product Views
class ProductListView(generics.ListAPIView):
    """List products with filtering and search."""
    serializer_class = ProductListSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = ProductFilter
    search_fields = ['name', 'description', 'short_description']
    ordering_fields = ['name', 'price', 'created_at', 'average_rating', 'sales_count']
    ordering = ['-created_at']
    
    def get_queryset(self):
        queryset = Product.objects.filter(status='published').select_related(
            'category', 'brand', 'vendor'
        ).prefetch_related('images', 'tag_assignments__tag')
        
        # Add additional filters from query params
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        min_rating = self.request.query_params.get('min_rating')
        in_stock = self.request.query_params.get('in_stock')
        tags = self.request.query_params.get('tags')
        
        if min_price:
            queryset = queryset.filter(price__gte=min_price)
        if max_price:
            queryset = queryset.filter(price__lte=max_price)
        if min_rating:
            queryset = queryset.filter(average_rating__gte=min_rating)
        if in_stock == 'true':
            queryset = queryset.filter(stock_quantity__gt=0)
        if tags:
            tag_list = tags.split(',')
            queryset = queryset.filter(tag_assignments__tag__name__in=tag_list).distinct()
        
        return queryset

class ProductDetailView(generics.RetrieveAPIView):
    """Get product details."""
    queryset = Product.objects.filter(status='published')
    serializer_class = ProductDetailSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Increment view count
        Product.objects.filter(id=instance.id).update(view_count=instance.view_count + 1)
        
        serializer = self.get_serializer(instance)
        return Response({
            'success': True,
            'data': serializer.data
        })

class VendorProductListView(generics.ListCreateAPIView):
    """List and create products for vendors."""
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
        return Product.objects.filter(vendor=vendor).select_related('category', 'brand')
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ProductCreateUpdateSerializer
        return ProductListSerializer
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        if self.request.method == 'POST':
            vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
            context['vendor'] = vendor
        return context

class VendorProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete vendor products."""
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
        return Product.objects.filter(vendor=vendor)
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return ProductCreateUpdateSerializer
        return ProductDetailSerializer
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        if self.request.method in ['PUT', 'PATCH']:
            vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
            context['vendor'] = vendor
        return context

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def upload_product_images(request, product_id):
    """Upload multiple images for a product."""
    vendor = get_object_or_404('vendors.Vendor', user=request.user)
    product = get_object_or_404(Product, id=product_id, vendor=vendor)
    
    if 'images' not in request.FILES:
        return Response({
            'success': False,
            'message': 'No image files provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    images = request.FILES.getlist('images')
    
    if len(images) > 10:
        return Response({
            'success': False,
            'message': 'Maximum 10 images allowed per product'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    uploaded_images = []
    
    for i, image in enumerate(images):
        # Validate image
        from core.utils import validate_image_file
        is_valid, message = validate_image_file(image)
        
        if not is_valid:
            return Response({
                'success': False,
                'message': f'Image {i+1}: {message}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create product image
        product_image = ProductImage.objects.create(
            product=product,
            image=image,
            sort_order=i,
            is_primary=(i == 0 and not product.images.exists())
        )
        uploaded_images.append({
            'id': str(product_image.id),
            'image_url': request.build_absolute_uri(product_image.image.url),
            'is_primary': product_image.is_primary
        })
    
    return Response({
        'success': True,
        'message': f'{len(images)} images uploaded successfully',
        'data': uploaded_images
    }, status=status.HTTP_201_CREATED)

# Product Variation Views
class ProductVariationListView(generics.ListCreateAPIView):
    """List and create product variations."""
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        product_id = self.kwargs['product_id']
        vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
        product = get_object_or_404(Product, id=product_id, vendor=vendor)
        return ProductVariation.objects.filter(product=product)
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ProductVariationCreateSerializer
        return ProductVariationSerializer
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        if self.request.method == 'POST':
            product_id = self.kwargs['product_id']
            vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
            product = get_object_or_404(Product, id=product_id, vendor=vendor)
            context['product'] = product
        return context

class ProductVariationDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete product variation."""
    serializer_class = ProductVariationSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        product_id = self.kwargs['product_id']
        vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
        product = get_object_or_404(Product, id=product_id, vendor=vendor)
        return ProductVariation.objects.filter(product=product)

# Product Attribute Views
class ProductAttributeListView(generics.ListCreateAPIView):
    """List and create product attributes."""
    queryset = ProductAttribute.objects.all()
    serializer_class = ProductAttributeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    ordering = ['name']

class ProductAttributeDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete product attribute."""
    queryset = ProductAttribute.objects.all()
    serializer_class = ProductAttributeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

# Product Review Views
class ProductReviewListView(generics.ListCreateAPIView):
    """List and create product reviews."""
    serializer_class = ProductReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        product_id = self.kwargs['product_id']
        product = get_object_or_404(Product, id=product_id, status='published')
        return ProductReview.objects.filter(product=product, is_approved=True)
    
    def perform_create(self, serializer):
        product_id = self.kwargs['product_id']
        product = get_object_or_404(Product, id=product_id, status='published')
        
        # Check if user already reviewed this product
        if ProductReview.objects.filter(product=product, user=self.request.user).exists():
            return Response({
                'success': False,
                'message': 'You have already reviewed this product'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        review = serializer.save(user=self.request.user, product=product)
        
        # Update product rating
        self.update_product_rating(product)
        
        return Response({
            'success': True,
            'message': 'Review added successfully',
            'data': ProductReviewSerializer(review).data
        }, status=status.HTTP_201_CREATED)
    
    def update_product_rating(self, product):
        """Update product average rating and review count."""
        reviews = ProductReview.objects.filter(product=product, is_approved=True)
        if reviews.exists():
            avg_rating = reviews.aggregate(avg=Avg('rating'))['avg']
            review_count = reviews.count()
            
            product.average_rating = round(avg_rating, 2)
            product.review_count = review_count
            product.save(update_fields=['average_rating', 'review_count'])

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def mark_review_helpful(request, review_id):
    """Mark a review as helpful or not helpful."""
    review = get_object_or_404(ProductReview, id=review_id)
    action = request.data.get('action')  # 'helpful' or 'not_helpful'
    
    if action == 'helpful':
        review.helpful_count += 1
    elif action == 'not_helpful':
        review.not_helpful_count += 1
    else:
        return Response({
            'success': False,
            'message': 'Invalid action. Use "helpful" or "not_helpful"'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    review.save()
    
    return Response({
        'success': True,
        'message': 'Review feedback recorded'
    })

# Wishlist Views
class WishlistView(generics.ListCreateAPIView):
    """List and manage user wishlist."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Wishlist.objects.filter(user=self.request.user).select_related('product')
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return WishlistCreateSerializer
        return WishlistSerializer

@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def remove_from_wishlist(request, product_id):
    """Remove product from wishlist."""
    try:
        wishlist_item = Wishlist.objects.get(user=request.user, product_id=product_id)
        wishlist_item.delete()
        return Response({
            'success': True,
            'message': 'Product removed from wishlist'
        })
    except Wishlist.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found in wishlist'
        }, status=status.HTTP_404_NOT_FOUND)

# Search and Filter Views
@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def search_products(request):
    """Advanced product search."""
    serializer = ProductSearchSerializer(data=request.query_params)
    
    if serializer.is_valid():
        filters = serializer.validated_data
        queryset = Product.objects.filter(status='published')
        
        # Apply filters
        if filters.get('q'):
            query = filters['q']
            queryset = queryset.filter(
                Q(name__icontains=query) |
                Q(description__icontains=query) |
                Q(short_description__icontains=query)
            )
        
        if filters.get('category'):
            queryset = queryset.filter(category=filters['category'])
        
        if filters.get('brand'):
            queryset = queryset.filter(brand=filters['brand'])
        
        if filters.get('vendor'):
            queryset = queryset.filter(vendor=filters['vendor'])
        
        if filters.get('min_price'):
            queryset = queryset.filter(price__gte=filters['min_price'])
        
        if filters.get('max_price'):
            queryset = queryset.filter(price__lte=filters['max_price'])
        
        if filters.get('min_rating'):
            queryset = queryset.filter(average_rating__gte=filters['min_rating'])
        
        if filters.get('in_stock'):
            queryset = queryset.filter(stock_quantity__gt=0)
        
        if filters.get('is_featured'):
            queryset = queryset.filter(is_featured=True)
        
        if filters.get('tags'):
            tag_names = filters['tags'].split(',')
            queryset = queryset.filter(tag_assignments__tag__name__in=tag_names).distinct()
        
        # Apply sorting
        sort_by = filters.get('sort_by', '-created_at')
        queryset = queryset.order_by(sort_by)
        
        # Paginate results
        page = request.query_params.get('page', 1)
        page_size = min(int(request.query_params.get('page_size', 20)), 100)
        
        from django.core.paginator import Paginator
        paginator = Paginator(queryset, page_size)
        
        try:
            products = paginator.page(page)
        except:
            products = paginator.page(1)
        
        serializer = ProductListSerializer(products, many=True, context={'request': request})
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
                'pagination': {
                    'current_page': products.number,
                    'total_pages': paginator.num_pages,
                    'total_items': paginator.count,
                    'has_next': products.has_next(),
                    'has_previous': products.has_previous(),
                }
            }
        })
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

# Bulk Operations
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def bulk_product_update(request):
    """Bulk update products."""
    serializer = ProductBulkUpdateSerializer(data=request.data)
    
    if serializer.is_valid():
        product_ids = serializer.validated_data['product_ids']
        action = serializer.validated_data['action']
        
        vendor = get_object_or_404('vendors.Vendor', user=request.user)
        products = Product.objects.filter(id__in=product_ids, vendor=vendor)
        
        if products.count() != len(product_ids):
            return Response({
                'success': False,
                'message': 'Some products not found or not owned by you'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        with transaction.atomic():
            if action == 'publish':
                products.update(status='published')
            elif action == 'unpublish':
                products.update(status='draft')
            elif action == 'feature':
                products.update(is_featured=True)
            elif action == 'unfeature':
                products.update(is_featured=False)
            elif action == 'delete':
                products.delete()
        
        return Response({
            'success': True,
            'message': f'{action.title()} applied to {products.count()} products'
        })
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

# Analytics and Stats
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def vendor_product_stats(request):
    """Get vendor product statistics."""
    vendor = get_object_or_404('vendors.Vendor', user=request.user)
    products = Product.objects.filter(vendor=vendor)
    
    stats = {
        'total_products': products.count(),
        'published_products': products.filter(status='published').count(),
        'draft_products': products.filter(status='draft').count(),
        'out_of_stock_products': products.filter(stock_quantity=0).count(),
        'low_stock_products': products.filter(
            stock_quantity__gt=0,
            stock_quantity__lte=models.F('low_stock_threshold')
        ).count(),
        'featured_products': products.filter(is_featured=True).count(),
        'total_views': products.aggregate(Sum('view_count'))['view_count__sum'] or 0,
        'total_sales': products.aggregate(Sum('sales_count'))['sales_count__sum'] or 0,
        'average_rating': products.aggregate(Avg('average_rating'))['average_rating__avg'] or 0.0,
    }
    
    serializer = ProductStatsSerializer(stats)
    
    return Response({
        'success': True,
        'data': serializer.data
    })