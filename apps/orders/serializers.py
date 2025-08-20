# apps/orders/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model
from decimal import Decimal
from .models import (
    ShoppingCart, CartItem, Order, OrderItem, OrderStatusHistory,
    Coupon, CouponUsage, ShippingMethod, Return
)
from apps.products.serializers import ProductListSerializer

User = get_user_model()

class CartItemSerializer(serializers.ModelSerializer):
    """Serializer for cart items."""
    product = ProductListSerializer(read_only=True)
    variation_details = serializers.SerializerMethodField()
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = CartItem
        fields = [
            'id', 'product', 'variation', 'variation_details', 'quantity',
            'unit_price', 'total_price', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'unit_price', 'created_at', 'updated_at']
    
    def get_variation_details(self, obj):
        if obj.variation:
            return {
                'id': str(obj.variation.id),
                'sku': obj.variation.sku,
                'attributes': [
                    {
                        'attribute': attr.attribute.name,
                        'value': attr.value.value,
                        'color_code': attr.value.color_code
                    }
                    for attr in obj.variation.attributes.all()
                ]
            }
        return None

class ShoppingCartSerializer(serializers.ModelSerializer):
    """Serializer for shopping cart."""
    items = CartItemSerializer(many=True, read_only=True)
    total_items = serializers.IntegerField(read_only=True)
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_weight = serializers.DecimalField(max_digits=8, decimal_places=2, read_only=True)
    
    class Meta:
        model = ShoppingCart
        fields = [
            'id', 'items', 'total_items', 'subtotal', 'total_weight',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

class AddToCartSerializer(serializers.Serializer):
    """Serializer for adding items to cart."""
    product = serializers.UUIDField()
    variation = serializers.UUIDField(required=False)
    quantity = serializers.IntegerField(min_value=1, default=1)
    
    def validate(self, attrs):
        from apps.products.models import Product, ProductVariation
        
        try:
            product = Product.objects.get(id=attrs['product'], status='published')
            attrs['product_obj'] = product
        except Product.DoesNotExist:
            raise serializers.ValidationError("Product not found or not available")
        
        # Validate variation if provided
        if attrs.get('variation'):
            try:
                variation = ProductVariation.objects.get(
                    id=attrs['variation'],
                    product=product,
                    is_active=True
                )
                attrs['variation_obj'] = variation
                
                # Check stock for variation
                if variation.stock_quantity < attrs['quantity']:
                    raise serializers.ValidationError("Insufficient stock for this variation")
            except ProductVariation.DoesNotExist:
                raise serializers.ValidationError("Product variation not found")
        else:
            # Check stock for simple product
            if product.manage_stock and product.stock_quantity < attrs['quantity']:
                raise serializers.ValidationError("Insufficient stock")
        
        return attrs

class UpdateCartItemSerializer(serializers.Serializer):
    """Serializer for updating cart item quantity."""
    quantity = serializers.IntegerField(min_value=0)
    
    def validate_quantity(self, value):
        cart_item = self.context.get('cart_item')
        if cart_item:
            # Check stock availability
            if cart_item.variation:
                available_stock = cart_item.variation.stock_quantity
            else:
                available_stock = cart_item.product.stock_quantity if cart_item.product.manage_stock else 999999
            
            if value > available_stock:
                raise serializers.ValidationError(f"Only {available_stock} items available in stock")
        
        return value

class ShippingMethodSerializer(serializers.ModelSerializer):
    """Serializer for shipping methods."""
    estimated_cost = serializers.SerializerMethodField()
    delivery_time = serializers.SerializerMethodField()
    
    class Meta:
        model = ShippingMethod
        fields = [
            'id', 'name', 'description', 'base_cost', 'estimated_cost',
            'delivery_time', 'min_delivery_days', 'max_delivery_days'
        ]
    
    def get_estimated_cost(self, obj):
        # Get cart total and weight from context
        cart_total = self.context.get('cart_total', Decimal('0.00'))
        cart_weight = self.context.get('cart_weight', Decimal('0.00'))
        return obj.calculate_cost(weight=cart_weight, order_total=cart_total)
    
    def get_delivery_time(self, obj):
        if obj.min_delivery_days == obj.max_delivery_days:
            return f"{obj.min_delivery_days} days"
        return f"{obj.min_delivery_days}-{obj.max_delivery_days} days"

class CouponSerializer(serializers.ModelSerializer):
    """Serializer for coupons."""
    discount_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Coupon
        fields = [
            'id', 'code', 'name', 'description', 'discount_type',
            'discount_value', 'discount_display', 'minimum_order_amount',
            'start_date', 'end_date'
        ]
    
    def get_discount_display(self, obj):
        if obj.discount_type == 'percentage':
            return f"{obj.discount_value}% off"
        elif obj.discount_type == 'fixed':
            return f"₹{obj.discount_value} off"
        else:
            return "Free shipping"

class ApplyCouponSerializer(serializers.Serializer):
    """Serializer for applying coupon to cart."""
    coupon_code = serializers.CharField(max_length=50)
    
    def validate_coupon_code(self, value):
        try:
            coupon = Coupon.objects.get(code=value.upper())
            self.coupon = coupon
            return value.upper()
        except Coupon.DoesNotExist:
            raise serializers.ValidationError("Invalid coupon code")

class OrderItemSerializer(serializers.ModelSerializer):
    """Serializer for order items."""
    variation_details = serializers.JSONField(read_only=True)
    vendor_name = serializers.CharField(source='vendor.business_name', read_only=True)
    
    class Meta:
        model = OrderItem
        fields = [
            'id', 'product_name', 'product_sku', 'product_image',
            'variation_details', 'quantity', 'unit_price', 'total_price',
            'vendor_name', 'status'
        ]

class OrderSerializer(serializers.ModelSerializer):
    """Serializer for orders."""
    items = OrderItemSerializer(many=True, read_only=True)
    customer_full_name = serializers.CharField(read_only=True)
    shipping_address = serializers.CharField(read_only=True)
    total_items = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'status', 'payment_status', 'customer_full_name',
            'customer_email', 'customer_phone', 'shipping_address', 'subtotal',
            'shipping_cost', 'tax_amount', 'discount_amount', 'total_amount',
            'payment_method', 'tracking_number', 'carrier', 'customer_notes',
            'total_items', 'items', 'created_at', 'updated_at', 'shipped_at',
            'delivered_at'
        ]
        read_only_fields = [
            'id', 'order_number', 'created_at', 'updated_at', 'shipped_at', 'delivered_at'
        ]

class OrderCreateSerializer(serializers.Serializer):
    """Serializer for creating orders."""
    # Shipping address
    shipping_address_line_1 = serializers.CharField(max_length=255)
    shipping_address_line_2 = serializers.CharField(max_length=255, required=False, allow_blank=True)
    shipping_city = serializers.CharField(max_length=100)
    shipping_state = serializers.CharField(max_length=100)
    shipping_postal_code = serializers.CharField(max_length=20)
    shipping_country = serializers.CharField(max_length=100, default='India')
    
    # Billing address (optional, defaults to shipping if not provided)
    billing_same_as_shipping = serializers.BooleanField(default=True)
    billing_address_line_1 = serializers.CharField(max_length=255, required=False)
    billing_address_line_2 = serializers.CharField(max_length=255, required=False, allow_blank=True)
    billing_city = serializers.CharField(max_length=100, required=False)
    billing_state = serializers.CharField(max_length=100, required=False)
    billing_postal_code = serializers.CharField(max_length=20, required=False)
    billing_country = serializers.CharField(max_length=100, required=False)
    
    # Order details
    shipping_method = serializers.UUIDField()
    payment_method = serializers.CharField(max_length=50)
    coupon_code = serializers.CharField(max_length=50, required=False, allow_blank=True)
    customer_notes = serializers.CharField(required=False, allow_blank=True)
    
    def validate(self, attrs):
        # Validate billing address if not same as shipping
        if not attrs.get('billing_same_as_shipping', True):
            required_billing_fields = [
                'billing_address_line_1', 'billing_city', 'billing_state',
                'billing_postal_code', 'billing_country'
            ]
            for field in required_billing_fields:
                if not attrs.get(field):
                    raise serializers.ValidationError(f"{field} is required when billing address is different from shipping")
        
        # Validate shipping method
        try:
            shipping_method = ShippingMethod.objects.get(id=attrs['shipping_method'], is_active=True)
            attrs['shipping_method_obj'] = shipping_method
        except ShippingMethod.DoesNotExist:
            raise serializers.ValidationError("Invalid shipping method")
        
        # Validate coupon if provided
        if attrs.get('coupon_code'):
            try:
                coupon = Coupon.objects.get(code=attrs['coupon_code'].upper())
                attrs['coupon_obj'] = coupon
            except Coupon.DoesNotExist:
                raise serializers.ValidationError("Invalid coupon code")
        
        return attrs

class OrderStatusHistorySerializer(serializers.ModelSerializer):
    """Serializer for order status history."""
    changed_by_name = serializers.CharField(source='changed_by.full_name', read_only=True)
    
    class Meta:
        model = OrderStatusHistory
        fields = ['id', 'status', 'notes', 'changed_by_name', 'created_at']

class OrderDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single order."""
    items = OrderItemSerializer(many=True, read_only=True)
    status_history = OrderStatusHistorySerializer(many=True, read_only=True)
    customer_full_name = serializers.CharField(read_only=True)
    shipping_address = serializers.CharField(read_only=True)
    total_items = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'status', 'payment_status', 'customer_email',
            'customer_phone', 'customer_first_name', 'customer_last_name',
            'customer_full_name', 'shipping_address_line_1', 'shipping_address_line_2',
            'shipping_city', 'shipping_state', 'shipping_postal_code', 'shipping_country',
            'billing_address_line_1', 'billing_address_line_2', 'billing_city',
            'billing_state', 'billing_postal_code', 'billing_country', 'subtotal',
            'shipping_cost', 'tax_amount', 'discount_amount', 'total_amount',
            'payment_method', 'payment_transaction_id', 'tracking_number', 'carrier',
            'customer_notes', 'admin_notes', 'total_items', 'items', 'status_history',
            'created_at', 'updated_at', 'shipped_at', 'delivered_at'
        ]

class UpdateOrderStatusSerializer(serializers.Serializer):
    """Serializer for updating order status."""
    status = serializers.ChoiceField(choices=Order.STATUS_CHOICES)
    notes = serializers.CharField(required=False, allow_blank=True)
    tracking_number = serializers.CharField(required=False, allow_blank=True)
    carrier = serializers.CharField(required=False, allow_blank=True)

class ReturnSerializer(serializers.ModelSerializer):
    """Serializer for returns."""
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    product_name = serializers.CharField(source='order_item.product_name', read_only=True)
    customer_name = serializers.CharField(source='user.full_name', read_only=True)
    
    class Meta:
        model = Return
        fields = [
            'id', 'return_number', 'order_number', 'product_name', 'customer_name',
            'reason', 'detailed_reason', 'quantity', 'status', 'refund_amount',
            'images', 'admin_notes', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'return_number', 'refund_amount', 'admin_notes', 'created_at', 'updated_at'
        ]

class CreateReturnSerializer(serializers.Serializer):
    """Serializer for creating returns."""
    order_item = serializers.UUIDField()
    reason = serializers.ChoiceField(choices=Return.RETURN_REASON_CHOICES)
    detailed_reason = serializers.CharField()
    quantity = serializers.IntegerField(min_value=1)
    images = serializers.ListField(
        child=serializers.ImageField(),
        required=False,
        max_length=5
    )
    
    def validate_order_item(self, value):
        try:
            order_item = OrderItem.objects.get(id=value)
            
            # Check if order item belongs to the requesting user
            user = self.context['request'].user
            if order_item.order.user != user:
                raise serializers.ValidationError("Order item not found")
            
            # Check if order is eligible for return (e.g., delivered, within return period)
            if order_item.order.status not in ['delivered']:
                raise serializers.ValidationError("Order must be delivered to request a return")
            
            # Check if return window is still open (example: 30 days)
            from django.utils import timezone
            from datetime import timedelta
            
            if order_item.order.delivered_at:
                return_deadline = order_item.order.delivered_at + timedelta(days=30)
                if timezone.now() > return_deadline:
                    raise serializers.ValidationError("Return period has expired")
            
            self.order_item = order_item
            return value
            
        except OrderItem.DoesNotExist:
            raise serializers.ValidationError("Order item not found")
    
    def validate_quantity(self, value):
        if hasattr(self, 'order_item'):
            if value > self.order_item.quantity:
                raise serializers.ValidationError("Cannot return more items than purchased")
        return value

class VendorOrderItemSerializer(serializers.ModelSerializer):
    """Serializer for vendor order items."""
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    customer_name = serializers.CharField(source='order.customer_full_name', read_only=True)
    order_date = serializers.DateTimeField(source='order.created_at', read_only=True)
    order_status = serializers.CharField(source='order.status', read_only=True)
    shipping_address = serializers.CharField(source='order.shipping_address', read_only=True)
    
    class Meta:
        model = OrderItem
        fields = [
            'id', 'order_number', 'customer_name', 'order_date', 'order_status',
            'product_name', 'product_sku', 'variation_details', 'quantity',
            'unit_price', 'total_price', 'status', 'shipping_address'
        ]

class VendorOrderStatsSerializer(serializers.Serializer):
    """Serializer for vendor order statistics."""
    total_orders = serializers.IntegerField()
    pending_orders = serializers.IntegerField()
    processing_orders = serializers.IntegerField()
    shipped_orders = serializers.IntegerField()
    delivered_orders = serializers.IntegerField()
    cancelled_orders = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_items_sold = serializers.IntegerField()
    average_order_value = serializers.DecimalField(max_digits=10, decimal_places=2)

class CheckoutSummarySerializer(serializers.Serializer):
    """Serializer for checkout summary."""
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2)
    shipping_cost = serializers.DecimalField(max_digits=10, decimal_places=2)
    tax_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    discount_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_items = serializers.IntegerField()
    applied_coupon = CouponSerializer(required=False, allow_null=True)
    shipping_method = ShippingMethodSerializer(required=False, allow_null=True)