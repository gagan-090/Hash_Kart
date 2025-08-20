# apps/products/urls.py
from django.urls import path
from . import views

app_name = 'products'

urlpatterns = [
    # Categories
    path('categories/', views.CategoryListView.as_view(), name='category_list'),
    path('categories/tree/', views.category_tree, name='category_tree'),
    path('categories/<slug:slug>/', views.CategoryDetailView.as_view(), name='category_detail'),
    
    # Brands
    path('brands/', views.BrandListView.as_view(), name='brand_list'),
    path('brands/<slug:slug>/', views.BrandDetailView.as_view(), name='brand_detail'),
    
    # Products - Public
    path('', views.ProductListView.as_view(), name='product_list'),
    path('<slug:slug>/', views.ProductDetailView.as_view(), name='product_detail'),
    path('search/', views.search_products, name='product_search'),
    
    # Products - Vendor Management
    path('vendor/products/', views.VendorProductListView.as_view(), name='vendor_product_list'),
    path('vendor/products/<uuid:pk>/', views.VendorProductDetailView.as_view(), name='vendor_product_detail'),
    path('vendor/products/<uuid:product_id>/images/', views.upload_product_images, name='upload_product_images'),
    path('vendor/products/bulk-update/', views.bulk_product_update, name='bulk_product_update'),
    path('vendor/products/stats/', views.vendor_product_stats, name='vendor_product_stats'),
    
    # Product Variations
    path('vendor/products/<uuid:product_id>/variations/', views.ProductVariationListView.as_view(), name='product_variation_list'),
    path('vendor/products/<uuid:product_id>/variations/<uuid:pk>/', views.ProductVariationDetailView.as_view(), name='product_variation_detail'),
    
    # Product Attributes
    path('attributes/', views.ProductAttributeListView.as_view(), name='attribute_list'),
    path('attributes/<uuid:pk>/', views.ProductAttributeDetailView.as_view(), name='attribute_detail'),
    
    # Product Reviews
    path('<uuid:product_id>/reviews/', views.ProductReviewListView.as_view(), name='product_review_list'),
    path('reviews/<uuid:review_id>/helpful/', views.mark_review_helpful, name='mark_review_helpful'),
    
    # Wishlist
    path('wishlist/', views.WishlistView.as_view(), name='wishlist'),
    path('wishlist/<uuid:product_id>/remove/', views.remove_from_wishlist, name='remove_from_wishlist'),
]