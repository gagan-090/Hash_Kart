# apps/products/filters.py
import django_filters
from django.db import models
from .models import Product, Category, Brand

class ProductFilter(django_filters.FilterSet):
    """Advanced filters for product listing."""
    
    # Price range filters
    min_price = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    max_price = django_filters.NumberFilter(field_name='price', lookup_expr='lte')
    
    # Rating filter
    min_rating = django_filters.NumberFilter(field_name='average_rating', lookup_expr='gte')
    
    # Category filters
    category = django_filters.ModelChoiceFilter(queryset=Category.objects.filter(is_active=True))
    category_slug = django_filters.CharFilter(field_name='category__slug')
    
    # Brand filters
    brand = django_filters.ModelChoiceFilter(queryset=Brand.objects.filter(is_active=True))
    brand_slug = django_filters.CharFilter(field_name='brand__slug')
    
    # Vendor filter
    vendor = django_filters.UUIDFilter(field_name='vendor__id')
    vendor_name = django_filters.CharFilter(field_name='vendor__business_name', lookup_expr='icontains')
    
    # Stock filters
    in_stock = django_filters.BooleanFilter(method='filter_in_stock')
    stock_status = django_filters.ChoiceFilter(choices=Product._meta.get_field('stock_status').choices)
    
    # Feature filter
    is_featured = django_filters.BooleanFilter()
    
    # Product type filter
    product_type = django_filters.ChoiceFilter(choices=Product._meta.get_field('product_type').choices)
    
    # Date filters
    created_after = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='gte')
    created_before = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='lte')
    
    # Search in multiple fields
    search = django_filters.CharFilter(method='filter_search')
    
    # Tag filter
    tags = django_filters.CharFilter(method='filter_tags')
    
    # Weight range filters
    min_weight = django_filters.NumberFilter(field_name='weight', lookup_expr='gte')
    max_weight = django_filters.NumberFilter(field_name='weight', lookup_expr='lte')
    
    class Meta:
        model = Product
        fields = {
            'name': ['exact', 'icontains'],
            'sku': ['exact', 'icontains'],
            'status': ['exact'],
            'is_digital': ['exact'],
            'requires_shipping': ['exact'],
        }
    
    def filter_in_stock(self, queryset, name, value):
        """Filter products based on stock availability."""
        if value:
            return queryset.filter(stock_quantity__gt=0)
        return queryset.filter(stock_quantity=0)
    
    def filter_search(self, queryset, name, value):
        """Search in product name, description, and SKU."""
        if value:
            return queryset.filter(
                models.Q(name__icontains=value) |
                models.Q(description__icontains=value) |
                models.Q(short_description__icontains=value) |
                models.Q(sku__icontains=value)
            )
        return queryset
    
    def filter_tags(self, queryset, name, value):
        """Filter products by tags."""
        if value:
            tag_names = [tag.strip() for tag in value.split(',')]
            return queryset.filter(
                tag_assignments__tag__name__in=tag_names
            ).distinct()
        return queryset