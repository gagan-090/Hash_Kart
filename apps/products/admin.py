# apps/products/admin.py
from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Category, Brand, Product, ProductAttribute, ProductAttributeValue,
    ProductVariation, ProductVariationAttribute, ProductImage, ProductReview,
    ProductTag, ProductTagAssignment, Wishlist
)

class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 1
    fields = ['image', 'alt_text', 'is_primary', 'sort_order']

class ProductTagAssignmentInline(admin.TabularInline):
    model = ProductTagAssignment
    extra = 1

class ProductVariationInline(admin.TabularInline):
    model = ProductVariation
    extra = 0
    fields = ['sku', 'price', 'stock_quantity', 'is_active', 'is_default']
    readonly_fields = ['sku']

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'parent', 'is_active', 'is_featured', 'sort_order', 'product_count']
    list_filter = ['is_active', 'is_featured', 'parent']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}
    ordering = ['sort_order', 'name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'description', 'parent')
        }),
        ('Media', {
            'fields': ('image', 'icon')
        }),
        ('Settings', {
            'fields': ('is_active', 'is_featured', 'sort_order')
        }),
        ('SEO', {
            'fields': ('meta_title', 'meta_description', 'meta_keywords'),
            'classes': ('collapse',)
        }),
    )
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'

@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'is_featured', 'product_count', 'created_at']
    list_filter = ['is_active', 'is_featured', 'created_at']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'vendor', 'category', 'brand', 'price', 'stock_quantity',
        'status', 'is_featured', 'average_rating', 'created_at'
    ]
    list_filter = [
        'status', 'is_featured', 'product_type', 'category', 'brand',
        'vendor', 'created_at', 'stock_status'
    ]
    search_fields = ['name', 'sku', 'description', 'vendor__business_name']
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ['sku', 'view_count', 'sales_count', 'average_rating', 'review_count']
    raw_id_fields = ['vendor', 'category', 'brand']
    inlines = [ProductImageInline, ProductTagAssignmentInline, ProductVariationInline]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'sku', 'barcode', 'vendor')
        }),
        ('Classification', {
            'fields': ('category', 'brand', 'product_type')
        }),
        ('Description', {
            'fields': ('short_description', 'description', 'specifications')
        }),
        ('Pricing', {
            'fields': ('price', 'compare_price', 'cost_price')
        }),
        ('Inventory', {
            'fields': ('stock_quantity', 'low_stock_threshold', 'manage_stock', 'stock_status')
        }),
        ('Physical Attributes', {
            'fields': ('weight', 'length', 'width', 'height'),
            'classes': ('collapse',)
        }),
        ('Shipping', {
            'fields': ('requires_shipping', 'shipping_class'),
            'classes': ('collapse',)
        }),
        ('Status & Visibility', {
            'fields': ('status', 'is_featured', 'is_digital')
        }),
        ('Analytics', {
            'fields': ('view_count', 'sales_count', 'average_rating', 'review_count'),
            'classes': ('collapse',)
        }),
        ('SEO', {
            'fields': ('meta_title', 'meta_description', 'meta_keywords'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['make_published', 'make_draft', 'make_featured', 'remove_featured']
    
    def make_published(self, request, queryset):
        updated = queryset.update(status='published')
        self.message_user(request, f'{updated} products marked as published.')
    make_published.short_description = 'Mark selected products as published'
    
    def make_draft(self, request, queryset):
        updated = queryset.update(status='draft')
        self.message_user(request, f'{updated} products marked as draft.')
    make_draft.short_description = 'Mark selected products as draft'
    
    def make_featured(self, request, queryset):
        updated = queryset.update(is_featured=True)
        self.message_user(request, f'{updated} products marked as featured.')
    make_featured.short_description = 'Mark selected products as featured'
    
    def remove_featured(self, request, queryset):
        updated = queryset.update(is_featured=False)
        self.message_user(request, f'{updated} products removed from featured.')
    remove_featured.short_description = 'Remove featured from selected products'

@admin.register(ProductAttribute)
class ProductAttributeAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'is_variation', 'is_visible', 'value_count']
    list_filter = ['type', 'is_variation', 'is_visible']
    search_fields = ['name']
    prepopulated_fields = {'slug': ('name',)}
    
    def value_count(self, obj):
        return obj.values.count()
    value_count.short_description = 'Values'

@admin.register(ProductAttributeValue)
class ProductAttributeValueAdmin(admin.ModelAdmin):
    list_display = ['attribute', 'value', 'color_code', 'sort_order']
    list_filter = ['attribute']
    search_fields = ['value', 'attribute__name']
    ordering = ['attribute', 'sort_order', 'value']

@admin.register(ProductVariation)
class ProductVariationAdmin(admin.ModelAdmin):
    list_display = ['product', 'sku', 'price', 'stock_quantity', 'is_active', 'is_default']
    list_filter = ['is_active', 'is_default', 'product__vendor']
    search_fields = ['sku', 'product__name']
    readonly_fields = ['sku']
    raw_id_fields = ['product']

@admin.register(ProductVariationAttribute)
class ProductVariationAttributeAdmin(admin.ModelAdmin):
    list_display = ['variation', 'attribute', 'value']
    list_filter = ['attribute']
    raw_id_fields = ['variation', 'attribute', 'value']

@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ['product', 'image_preview', 'alt_text', 'is_primary', 'sort_order']
    list_filter = ['is_primary', 'product__vendor']
    search_fields = ['product__name', 'alt_text']
    raw_id_fields = ['product']
    
    def image_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" width="50" height="50" style="object-fit: cover;" />',
                obj.image.url
            )
        return 'No Image'
    image_preview.short_description = 'Preview'

@admin.register(ProductReview)
class ProductReviewAdmin(admin.ModelAdmin):
    list_display = [
        'product', 'user', 'rating', 'title', 'is_verified_purchase',
        'is_approved', 'helpful_count', 'created_at'
    ]
    list_filter = [
        'rating', 'is_verified_purchase', 'is_approved', 'created_at'
    ]
    search_fields = ['product__name', 'user__email', 'title', 'comment']
    readonly_fields = ['helpful_count', 'not_helpful_count']
    raw_id_fields = ['product', 'user']
    
    actions = ['approve_reviews', 'disapprove_reviews']
    
    def approve_reviews(self, request, queryset):
        updated = queryset.update(is_approved=True)
        self.message_user(request, f'{updated} reviews approved.')
    approve_reviews.short_description = 'Approve selected reviews'
    
    def disapprove_reviews(self, request, queryset):
        updated = queryset.update(is_approved=False)
        self.message_user(request, f'{updated} reviews disapproved.')
    disapprove_reviews.short_description = 'Disapprove selected reviews'

@admin.register(ProductTag)
class ProductTagAdmin(admin.ModelAdmin):
    list_display = ['name', 'color', 'product_count', 'created_at']
    search_fields = ['name']
    prepopulated_fields = {'slug': ('name',)}
    
    def product_count(self, obj):
        return obj.product_assignments.count()
    product_count.short_description = 'Products'

@admin.register(ProductTagAssignment)
class ProductTagAssignmentAdmin(admin.ModelAdmin):
    list_display = ['product', 'tag', 'created_at']
    list_filter = ['tag', 'created_at']
    search_fields = ['product__name', 'tag__name']
    raw_id_fields = ['product', 'tag']

@admin.register(Wishlist)
class WishlistAdmin(admin.ModelAdmin):
    list_display = ['user', 'product', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__email', 'product__name']
    raw_id_fields = ['user', 'product']