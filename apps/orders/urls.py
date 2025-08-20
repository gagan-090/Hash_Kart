# apps/orders/urls.py
from django.urls import path
from . import views

app_name = 'orders'

urlpatterns = [
    # Shopping Cart
    path('cart/', views.get_cart, name='get_cart'),
    path('cart/add/', views.add_to_cart, name='add_to_cart'),
    path('cart/items/<uuid:item_id>/update/', views.update_cart_item, name='update_cart_item'),
    path('cart/items/<uuid:item_id>/remove/', views.remove_from_cart, name='remove_from_cart'),
    path('cart/clear/', views.clear_cart, name='clear_cart'),
    
    # Shipping
    path('shipping-methods/', views.get_shipping_methods, name='shipping_methods'),
    
    # Coupons
    path('coupons/apply/', views.apply_coupon, name='apply_coupon'),
    path('coupons/remove/', views.remove_coupon, name='remove_coupon'),
    
    # Checkout
    path('checkout/summary/', views.checkout_summary, name='checkout_summary'),
    path('checkout/create/', views.create_order, name='create_order'),
    
    # User Orders
    path('', views.UserOrderListView.as_view(), name='user_order_list'),
    path('<uuid:pk>/', views.UserOrderDetailView.as_view(), name='user_order_detail'),
    path('<uuid:order_id>/cancel/', views.cancel_order, name='cancel_order'),
    path('analytics/', views.user_order_analytics, name='user_order_analytics'),
    
    # Vendor Order Management
    path('vendor/items/', views.VendorOrderItemListView.as_view(), name='vendor_order_items'),
    path('vendor/items/<uuid:item_id>/status/', views.update_order_item_status, name='update_order_item_status'),
    path('vendor/stats/', views.vendor_order_stats, name='vendor_order_stats'),
    
    # Returns
    path('returns/', views.ReturnListView.as_view(), name='return_list'),
    path('returns/create/', views.create_return, name='create_return'),
    path('returns/<uuid:pk>/', views.ReturnDetailView.as_view(), name='return_detail'),
    
    # Vendor Return Management
    path('vendor/returns/', views.vendor_returns, name='vendor_returns'),
    path('vendor/returns/<uuid:return_id>/process/', views.process_return, name='process_return'),
]