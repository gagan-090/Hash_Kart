# apps/products/serializers.py
from rest_framework import serializers
from django.db import transaction
from .models import (
    Category, Brand, Product, ProductAttribute, ProductAttributeValue,
    ProductVariation, ProductVariationAttribute, ProductImage, ProductReview,
    ProductTag, ProductTagAssignment, Wishlist
)

class CategorySerializer(serializers.ModelSerializer):
    """Serializer for product categories."""
    children = serializers.SerializerMethodField()
    product_count = serializers.SerializerMethodField()
    full_path = serializers.CharField(read_only=True)
    
    class Meta:
        model = Category
        fields = [
            'id', 'name', 'slug', 'description', 'image', 'icon',
            'parent', 'children', 'is_active', 'is_featured',
            'sort_order', 'product_count', 'full_path', 'created_at'
        ]
        read_only_fields = ['id', 'slug', 'created_at']
    
    def get_children(self, obj):
        if obj.children.exists():
            return CategorySerializer(obj.children.filter(is_active=True), many=True).data
        return []
    
    def get_product_count(self, obj):
        return obj.products.filter(status='published').count()

class CategoryListSerializer(serializers.ModelSerializer):
    """Simplified category serializer for lists."""
    product_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'image', 'icon', 'product_count']
    
    def get_product_count(self, obj):
        return obj.products.filter(status='published').count()

class BrandSerializer(serializers.ModelSerializer):
    """Serializer for product brands."""
    product_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Brand
        fields = [
            'id', 'name', 'slug', 'description', 'logo', 'website',
            'is_active', 'is_featured', 'product_count', 'created_at'
        ]
        read_only_fields = ['id', 'slug', 'created_at']
    
    def get_product_count(self, obj):
        return obj.products.filter(status='published').count()

class ProductImageSerializer(serializers.ModelSerializer):
    """Serializer for product images."""
    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'alt_text', 'is_primary', 'sort_order']
        read_only_fields = ['id']

class ProductTagSerializer(serializers.ModelSerializer):
    """Serializer for product tags."""
    class Meta:
        model = ProductTag
        fields = ['id', 'name', 'slug', 'color']
        read_only_fields = ['id', 'slug']

class ProductAttributeValueSerializer(serializers.ModelSerializer):
    """Serializer for product attribute values."""
    attribute_name = serializers.CharField(source='attribute.name', read_only=True)
    
    class Meta:
        model = ProductAttributeValue
        fields = ['id', 'attribute', 'attribute_name', 'value', 'color_code', 'image', 'sort_order']

class ProductVariationAttributeSerializer(serializers.ModelSerializer):
    """Serializer for product variation attributes."""
    attribute_name = serializers.CharField(source='attribute.name', read_only=True)
    value_name = serializers.CharField(source='value.value', read_only=True)
    color_code = serializers.CharField(source='value.color_code', read_only=True)
    
    class Meta:
        model = ProductVariationAttribute
        fields = ['attribute', 'attribute_name', 'value', 'value_name', 'color_code']

class ProductVariationSerializer(serializers.ModelSerializer):
    """Serializer for product variations."""
    attributes = ProductVariationAttributeSerializer(many=True, read_only=True)
    is_in_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = ProductVariation
        fields = [
            'id', 'sku', 'price', 'compare_price', 'stock_quantity',
            'weight', 'length', 'width', 'height', 'is_active',
            'is_default', 'image', 'attributes', 'is_in_stock'
        ]
        read_only_fields = ['id', 'sku']

class ProductReviewSerializer(serializers.ModelSerializer):
    """Serializer for product reviews."""
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    user_avatar = serializers.ImageField(source='user.profile_image', read_only=True)
    
    class Meta:
        model = ProductReview
        fields = [
            'id', 'user', 'user_name', 'user_avatar', 'rating', 'title',
            'comment', 'helpful_count', 'not_helpful_count',
            'is_verified_purchase', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'helpful_count', 'not_helpful_count', 'is_verified_purchase']

class ProductListSerializer(serializers.ModelSerializer):
    """Serializer for product list view."""
    images = ProductImageSerializer(many=True, read_only=True)
    category_detail = CategorySerializer(source='category', read_only=True)
    brand_detail = BrandSerializer(source='brand', read_only=True)
    discount_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    is_in_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'vendor', 'name', 'slug', 'sku', 'barcode', 'category', 'brand',
            'product_type', 'short_description', 'description', 'specifications',
            'price', 'compare_price', 'cost_price', 'stock_quantity',
            'low_stock_threshold', 'manage_stock', 'stock_status',
            'weight', 'length', 'width', 'height', 'requires_shipping',
            'shipping_class', 'status', 'is_featured', 'is_digital',
            'meta_title', 'meta_description', 'meta_keywords',
            'view_count', 'sales_count', 'average_rating', 'review_count',
            'created_at', 'updated_at', 'published_at',
            'images', 'category_detail', 'brand_detail', 'discount_percentage', 'is_in_stock'
        ]

class ProductDetailSerializer(serializers.ModelSerializer):
    """Serializer for product detail view."""
    images = ProductImageSerializer(many=True, read_only=True)
    variations = ProductVariationSerializer(many=True, read_only=True)
    reviews = ProductReviewSerializer(many=True, read_only=True)
    tags = serializers.SerializerMethodField()
    category = CategorySerializer(read_only=True)
    brand = BrandSerializer(read_only=True)
    vendor_name = serializers.CharField(source='vendor.business_name', read_only=True)
    vendor_id = serializers.UUIDField(source='vendor.id', read_only=True)
    discount_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    is_in_stock = serializers.BooleanField(read_only=True)
    is_low_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'slug', 'sku', 'barcode', 'category', 'brand',
            'product_type', 'short_description', 'description', 'specifications',
            'price', 'compare_price', 'discount_percentage', 'stock_quantity',
            'low_stock_threshold', 'stock_status', 'is_in_stock', 'is_low_stock',
            'weight', 'length', 'width', 'height', 'requires_shipping',
            'shipping_class', 'status', 'is_featured', 'is_digital',
            'average_rating', 'review_count', 'view_count', 'sales_count',
            'vendor_name', 'vendor_id', 'images', 'variations', 'reviews',
            'tags', 'created_at', 'updated_at', 'published_at'
        ]
    
    def get_tags(self, obj):
        tags = ProductTag.objects.filter(product_assignments__product=obj)
        return ProductTagSerializer(tags, many=True).data

class ProductCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating and updating products."""
    images = ProductImageSerializer(many=True, required=False)
    tags = serializers.ListField(child=serializers.CharField(), required=False)
    
    class Meta:
        model = Product
        fields = [
            'name', 'category', 'brand', 'product_type', 'short_description',
            'description', 'specifications', 'price', 'compare_price',
            'cost_price', 'stock_quantity', 'low_stock_threshold',
            'manage_stock', 'weight', 'length', 'width', 'height',
            'requires_shipping', 'shipping_class', 'is_featured',
            'is_digital', 'meta_title', 'meta_description', 'meta_keywords',
            'images', 'tags'
        ]
    
    def create(self, validated_data):
        images_data = validated_data.pop('images', [])
        tags_data = validated_data.pop('tags', [])
        
        # Set vendor from context
        validated_data['vendor'] = self.context['vendor']
        
        with transaction.atomic():
            product = Product.objects.create(**validated_data)
            
            # Create images
            for i, image_data in enumerate(images_data):
                ProductImage.objects.create(
                    product=product,
                    sort_order=i,
                    is_primary=(i == 0),
                    **image_data
                )
            
            # Create tags
            for tag_name in tags_data:
                tag, created = ProductTag.objects.get_or_create(name=tag_name)
                ProductTagAssignment.objects.create(product=product, tag=tag)
            
            return product
    
    def update(self, instance, validated_data):
        images_data = validated_data.pop('images', None)
        tags_data = validated_data.pop('tags', None)
        
        with transaction.atomic():
            # Update product fields
            for attr, value in validated_data.items():
                setattr(instance, attr, value)
            instance.save()
            
            # Update images if provided
            if images_data is not None:
                instance.images.all().delete()
                for i, image_data in enumerate(images_data):
                    ProductImage.objects.create(
                        product=instance,
                        sort_order=i,
                        is_primary=(i == 0),
                        **image_data
                    )
            
            # Update tags if provided
            if tags_data is not None:
                instance.tag_assignments.all().delete()
                for tag_name in tags_data:
                    tag, created = ProductTag.objects.get_or_create(name=tag_name)
                    ProductTagAssignment.objects.create(product=instance, tag=tag)
            
            return instance

class ProductVariationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating product variations."""
    attributes = serializers.DictField(child=serializers.CharField())
    
    class Meta:
        model = ProductVariation
        fields = [
            'price', 'compare_price', 'cost_price', 'stock_quantity',
            'weight', 'length', 'width', 'height', 'is_active',
            'is_default', 'image', 'attributes'
        ]
    
    def create(self, validated_data):
        attributes_data = validated_data.pop('attributes')
        product = self.context['product']
        
        with transaction.atomic():
            variation = ProductVariation.objects.create(product=product, **validated_data)
            
            # Create variation attributes
            for attr_name, value_name in attributes_data.items():
                try:
                    attribute = ProductAttribute.objects.get(name=attr_name)
                    value, created = ProductAttributeValue.objects.get_or_create(
                        attribute=attribute,
                        value=value_name
                    )
                    ProductVariationAttribute.objects.create(
                        variation=variation,
                        attribute=attribute,
                        value=value
                    )
                except ProductAttribute.DoesNotExist:
                    raise serializers.ValidationError(f"Attribute '{attr_name}' does not exist")
            
            return variation

class ProductAttributeSerializer(serializers.ModelSerializer):
    """Serializer for product attributes."""
    values = ProductAttributeValueSerializer(many=True, read_only=True)
    
    class Meta:
        model = ProductAttribute
        fields = ['id', 'name', 'slug', 'type', 'is_variation', 'is_visible', 'values']
        read_only_fields = ['id', 'slug']

class WishlistSerializer(serializers.ModelSerializer):
    """Serializer for user wishlist."""
    product = ProductListSerializer(read_only=True)
    
    class Meta:
        model = Wishlist
        fields = ['id', 'product', 'created_at']
        read_only_fields = ['id', 'created_at']

class WishlistCreateSerializer(serializers.ModelSerializer):
    """Serializer for adding items to wishlist."""
    class Meta:
        model = Wishlist
        fields = ['product']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
    
    def validate_product(self, value):
        # Check if product is already in user's wishlist
        user = self.context['request'].user
        if Wishlist.objects.filter(user=user, product=value).exists():
            raise serializers.ValidationError("Product is already in your wishlist")
        return value

class ProductSearchSerializer(serializers.Serializer):
    """Serializer for product search parameters."""
    q = serializers.CharField(required=False, help_text="Search query")
    category = serializers.UUIDField(required=False, help_text="Category ID")
    brand = serializers.UUIDField(required=False, help_text="Brand ID")
    vendor = serializers.UUIDField(required=False, help_text="Vendor ID")
    min_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    max_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    min_rating = serializers.DecimalField(max_digits=3, decimal_places=2, required=False)
    in_stock = serializers.BooleanField(required=False, default=True)
    is_featured = serializers.BooleanField(required=False)
    tags = serializers.CharField(required=False, help_text="Comma-separated tag names")
    sort_by = serializers.ChoiceField(
        choices=[
            'name', '-name', 'price', '-price', 'created_at', '-created_at',
            'average_rating', '-average_rating', 'sales_count', '-sales_count'
        ],
        required=False,
        default='-created_at'
    )

class ProductBulkUpdateSerializer(serializers.Serializer):
    """Serializer for bulk product operations."""
    product_ids = serializers.ListField(child=serializers.UUIDField())
    action = serializers.ChoiceField(choices=[
        'publish', 'unpublish', 'feature', 'unfeature', 'delete'
    ])
    
    def validate_product_ids(self, value):
        if len(value) == 0:
            raise serializers.ValidationError("At least one product ID is required")
        if len(value) > 100:
            raise serializers.ValidationError("Cannot process more than 100 products at once")
        return value

class ProductStatsSerializer(serializers.Serializer):
    """Serializer for product statistics."""
    total_products = serializers.IntegerField()
    published_products = serializers.IntegerField()
    draft_products = serializers.IntegerField()
    out_of_stock_products = serializers.IntegerField()
    low_stock_products = serializers.IntegerField()
    featured_products = serializers.IntegerField()
    total_views = serializers.IntegerField()
    total_sales = serializers.IntegerField()
    average_rating = serializers.DecimalField(max_digits=3, decimal_places=2)

class CategoryTreeSerializer(serializers.ModelSerializer):
    """Serializer for category tree structure."""
    children = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'icon', 'children']
    
    def get_children(self, obj):
        children = obj.children.filter(is_active=True).order_by('sort_order', 'name')
        return CategoryTreeSerializer(children, many=True).data