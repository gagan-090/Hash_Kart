# apps/orders/admin.py
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import (
    ShoppingCart, CartItem, Order, OrderItem, OrderStatusHistory,
    Coupon, CouponUsage, ShippingMethod, Return
)

class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0
    readonly_fields = ['total_price']
    fields = ['product', 'variation', 'quantity', 'unit_price', 'total_price']

@admin.register(ShoppingCart)
class ShoppingCartAdmin(admin.ModelAdmin):
    list_display = ['user', 'total_items', 'subtotal', 'created_at', 'updated_at']
    list_filter = ['created_at', 'updated_at']
    search_fields = ['user__email', 'user__first_name', 'user__last_name']
    readonly_fields = ['total_items', 'subtotal', 'total_weight']
    inlines = [CartItemInline]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')

@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ['cart_user', 'product', 'variation', 'quantity', 'unit_price', 'total_price']
    list_filter = ['created_at', 'product__category']
    search_fields = ['cart__user__email', 'product__name']
    readonly_fields = ['total_price']
    raw_id_fields = ['cart', 'product', 'variation']
    
    def cart_user(self, obj):
        return obj.cart.user.email
    cart_user.short_description = 'User'

class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ['total_price']
    fields = [
        'vendor', 'product_name', 'product_sku', 'quantity', 
        'unit_price', 'total_price', 'status'
    ]

class OrderStatusHistoryInline(admin.TabularInline):
    model = OrderStatusHistory
    extra = 0
    readonly_fields = ['created_at']
    fields = ['status', 'notes', 'changed_by', 'created_at']

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = [
        'order_number', 'customer_full_name', 'status', 'payment_status',
        'total_amount', 'total_items', 'created_at'
    ]
    list_filter = [
        'status', 'payment_status', 'payment_method', 'created_at',
        'shipping_country', 'shipping_state'
    ]
    search_fields = [
        'order_number', 'customer_email', 'customer_first_name',
        'customer_last_name', 'tracking_number'
    ]
    readonly_fields = [
        'order_number', 'total_items', 'created_at', 'updated_at',
        'shipped_at', 'delivered_at'
    ]
    raw_id_fields = ['user']
    inlines = [OrderItemInline, OrderStatusHistoryInline]
    
    fieldsets = (
        ('Order Information', {
            'fields': ('order_number', 'user', 'status', 'payment_status', 'payment_method')
        }),
        ('Customer Information', {
            'fields': (
                'customer_email', 'customer_phone', 'customer_first_name', 'customer_last_name'
            )
        }),
        ('Shipping Address', {
            'fields': (
                'shipping_address_line_1', 'shipping_address_line_2', 'shipping_city',
                'shipping_state', 'shipping_postal_code', 'shipping_country'
            )
        }),
        ('Billing Address', {
            'fields': (
                'billing_address_line_1', 'billing_address_line_2', 'billing_city',
                'billing_state', 'billing_postal_code', 'billing_country'
            ),
            'classes': ('collapse',)
        }),
        ('Order Totals', {
            'fields': ('subtotal', 'shipping_cost', 'tax_amount', 'discount_amount', 'total_amount')
        }),
        ('Shipping & Tracking', {
            'fields': ('tracking_number', 'carrier')
        }),
        ('Notes', {
            'fields': ('customer_notes', 'admin_notes'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'shipped_at', 'delivered_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['mark_as_confirmed', 'mark_as_processing', 'mark_as_shipped', 'mark_as_delivered']
    
    def mark_as_confirmed(self, request, queryset):
        updated = queryset.update(status='confirmed')
        self.message_user(request, f'{updated} orders marked as confirmed.')
    mark_as_confirmed.short_description = 'Mark selected orders as confirmed'
    
    def mark_as_processing(self, request, queryset):
        updated = queryset.update(status='processing')
        self.message_user(request, f'{updated} orders marked as processing.')
    mark_as_processing.short_description = 'Mark selected orders as processing'
    
    def mark_as_shipped(self, request, queryset):
        from django.utils import timezone
        updated = queryset.update(status='shipped', shipped_at=timezone.now())
        self.message_user(request, f'{updated} orders marked as shipped.')
    mark_as_shipped.short_description = 'Mark selected orders as shipped'
    
    def mark_as_delivered(self, request, queryset):
        from django.utils import timezone
        updated = queryset.update(status='delivered', delivered_at=timezone.now())
        self.message_user(request, f'{updated} orders marked as delivered.')
    mark_as_delivered.short_description = 'Mark selected orders as delivered'

@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = [
        'order_number', 'vendor', 'product_name', 'quantity',
        'unit_price', 'total_price', 'status'
    ]
    list_filter = ['status', 'vendor', 'created_at']
    search_fields = [
        'order__order_number', 'product_name', 'product_sku',
        'vendor__business_name'
    ]
    readonly_fields = ['total_price']
    raw_id_fields = ['order', 'vendor', 'product', 'variation']
    
    def order_number(self, obj):
        return obj.order.order_number
    order_number.short_description = 'Order'

@admin.register(OrderStatusHistory)
class OrderStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ['order', 'status', 'changed_by', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['order__order_number', 'notes']
    readonly_fields = ['created_at']
    raw_id_fields = ['order', 'changed_by']

@admin.register(Coupon)
class CouponAdmin(admin.ModelAdmin):
    list_display = [
        'code', 'name', 'discount_type', 'discount_value',
        'is_active', 'used_count', 'usage_limit', 'start_date', 'end_date'
    ]
    list_filter = [
        'discount_type', 'is_active', 'start_date', 'end_date', 'created_at'
    ]
    search_fields = ['code', 'name', 'description']
    readonly_fields = ['used_count']
    filter_horizontal = ['applicable_products', 'applicable_categories', 'exclude_products']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('code', 'name', 'description')
        }),
        ('Discount Settings', {
            'fields': ('discount_type', 'discount_value', 'maximum_discount_amount')
        }),
        ('Usage Limits', {
            'fields': ('minimum_order_amount', 'usage_limit', 'usage_limit_per_user', 'used_count')
        }),
        ('Validity', {
            'fields': ('is_active', 'start_date', 'end_date')
        }),
        ('Applicable Products', {
            'fields': ('applicable_products', 'applicable_categories', 'exclude_products'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['activate_coupons', 'deactivate_coupons']
    
    def activate_coupons(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} coupons activated.')
    activate_coupons.short_description = 'Activate selected coupons'
    
    def deactivate_coupons(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} coupons deactivated.')
    deactivate_coupons.short_description = 'Deactivate selected coupons'

@admin.register(CouponUsage)
class CouponUsageAdmin(admin.ModelAdmin):
    list_display = ['coupon', 'user', 'order', 'discount_amount', 'created_at']
    list_filter = ['created_at']
    search_fields = ['coupon__code', 'user__email', 'order__order_number']
    readonly_fields = ['created_at']
    raw_id_fields = ['coupon', 'user', 'order']

@admin.register(ShippingMethod)
class ShippingMethodAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'base_cost', 'cost_per_kg', 'min_delivery_days',
        'max_delivery_days', 'is_active'
    ]
    list_filter = ['is_active', 'min_delivery_days', 'max_delivery_days']
    search_fields = ['name', 'description']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'is_active')
        }),
        ('Pricing', {
            'fields': ('base_cost', 'cost_per_kg', 'free_shipping_threshold')
        }),
        ('Delivery Time', {
            'fields': ('min_delivery_days', 'max_delivery_days')
        }),
        ('Restrictions', {
            'fields': (
                'available_countries', 'max_weight', 'max_length',
                'max_width', 'max_height'
            ),
            'classes': ('collapse',)
        }),
    )

@admin.register(Return)
class ReturnAdmin(admin.ModelAdmin):
    list_display = [
        'return_number', 'order', 'customer_name', 'reason',
        'status', 'refund_amount', 'created_at'
    ]
    list_filter = ['status', 'reason', 'created_at']
    search_fields = [
        'return_number', 'order__order_number', 'user__email',
        'order_item__product_name'
    ]
    readonly_fields = ['return_number', 'created_at', 'updated_at']
    raw_id_fields = ['order', 'order_item', 'user', 'processed_by']
    
    fieldsets = (
        ('Return Information', {
            'fields': ('return_number', 'order', 'order_item', 'user')
        }),
        ('Return Details', {
            'fields': ('reason', 'detailed_reason', 'quantity', 'images')
        }),
        ('Processing', {
            'fields': ('status', 'refund_amount', 'admin_notes', 'processed_by')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'processed_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['approve_returns', 'reject_returns']
    
    def approve_returns(self, request, queryset):
        updated = queryset.update(status='approved')
        self.message_user(request, f'{updated} returns approved.')
    approve_returns.short_description = 'Approve selected returns'
    
    def reject_returns(self, request, queryset):
        updated = queryset.update(status='rejected')
        self.message_user(request, f'{updated} returns rejected.')
    reject_returns.short_description = 'Reject selected returns'
    
    def customer_name(self, obj):
        return obj.user.full_name
    customer_name.short_description = 'Customer'