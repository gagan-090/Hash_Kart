# apps/orders/models.py
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.contrib.auth import get_user_model
from decimal import Decimal
import uuid

User = get_user_model()

class ShoppingCart(models.Model):
    """Shopping cart for users."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='shopping_cart')
    session_key = models.CharField(max_length=40, blank=True, null=True)  # For anonymous users
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'shopping_carts'
        verbose_name = 'Shopping Cart'
        verbose_name_plural = 'Shopping Carts'
    
    def __str__(self):
        return f"Cart for {self.user.email if self.user else self.session_key}"
    
    @property
    def total_items(self):
        return self.items.aggregate(total=models.Sum('quantity'))['total'] or 0
    
    @property
    def subtotal(self):
        total = Decimal('0.00')
        for item in self.items.all():
            total += item.total_price
        return total
    
    @property
    def total_weight(self):
        weight = Decimal('0.00')
        for item in self.items.all():
            if item.product.weight:
                weight += item.product.weight * item.quantity
        return weight

class CartItem(models.Model):
    """Items in shopping cart."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cart = models.ForeignKey(ShoppingCart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE)
    variation = models.ForeignKey('products.ProductVariation', on_delete=models.CASCADE, null=True, blank=True)
    quantity = models.PositiveIntegerField(default=1, validators=[MinValueValidator(1)])
    
    # Store price at time of adding to cart
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'cart_items'
        unique_together = ['cart', 'product', 'variation']
        verbose_name = 'Cart Item'
        verbose_name_plural = 'Cart Items'
    
    def __str__(self):
        return f"{self.product.name} x {self.quantity}"
    
    @property
    def total_price(self):
        return self.unit_price * self.quantity
    
    def save(self, *args, **kwargs):
        # Set unit price from product or variation
        if self.variation:
            self.unit_price = self.variation.price
        else:
            self.unit_price = self.product.price
        super().save(*args, **kwargs)

class Order(models.Model):
    """Customer orders."""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('processing', 'Processing'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=20, unique=True, blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    
    # Order status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='pending')
    
    # Customer information (stored at time of order)
    customer_email = models.EmailField()
    customer_phone = models.CharField(max_length=20, blank=True)
    customer_first_name = models.CharField(max_length=100)
    customer_last_name = models.CharField(max_length=100)
    
    # Shipping address
    shipping_address_line_1 = models.CharField(max_length=255)
    shipping_address_line_2 = models.CharField(max_length=255, blank=True)
    shipping_city = models.CharField(max_length=100)
    shipping_state = models.CharField(max_length=100)
    shipping_postal_code = models.CharField(max_length=20)
    shipping_country = models.CharField(max_length=100)
    
    # Billing address (can be same as shipping)
    billing_address_line_1 = models.CharField(max_length=255)
    billing_address_line_2 = models.CharField(max_length=255, blank=True)
    billing_city = models.CharField(max_length=100)
    billing_state = models.CharField(max_length=100)
    billing_postal_code = models.CharField(max_length=20)
    billing_country = models.CharField(max_length=100)
    
    # Order totals
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    shipping_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    # Payment information
    payment_method = models.CharField(max_length=50, blank=True)
    payment_transaction_id = models.CharField(max_length=100, blank=True)
    
    # Order notes
    customer_notes = models.TextField(blank=True)
    admin_notes = models.TextField(blank=True)
    
    # Tracking
    tracking_number = models.CharField(max_length=100, blank=True)
    carrier = models.CharField(max_length=100, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    shipped_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'orders'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['order_number']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Order {self.order_number}"
    
    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = self.generate_order_number()
        super().save(*args, **kwargs)
    
    def generate_order_number(self):
        import random
        import string
        while True:
            number = 'ORD' + ''.join(random.choices(string.digits, k=8))
            if not Order.objects.filter(order_number=number).exists():
                return number
    
    @property
    def customer_full_name(self):
        return f"{self.customer_first_name} {self.customer_last_name}"
    
    @property
    def shipping_address(self):
        address_parts = [
            self.shipping_address_line_1,
            self.shipping_address_line_2,
            self.shipping_city,
            self.shipping_state,
            self.shipping_postal_code,
            self.shipping_country
        ]
        return ', '.join(filter(None, address_parts))
    
    @property
    def total_items(self):
        return self.items.aggregate(total=models.Sum('quantity'))['total'] or 0

class OrderItem(models.Model):
    """Items in an order."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    vendor = models.ForeignKey('vendors.Vendor', on_delete=models.CASCADE, related_name='order_items')
    
    # Product information (stored at time of order)
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE)
    product_name = models.CharField(max_length=255)
    product_sku = models.CharField(max_length=100)
    product_image = models.URLField(blank=True)
    
    # Variation information
    variation = models.ForeignKey('products.ProductVariation', on_delete=models.SET_NULL, null=True, blank=True)
    variation_details = models.JSONField(default=dict, blank=True)  # Store variation attributes
    
    # Pricing and quantity
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Item status
    status = models.CharField(
        max_length=20,
        choices=Order.STATUS_CHOICES,
        default='pending'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'order_items'
        verbose_name = 'Order Item'
        verbose_name_plural = 'Order Items'
    
    def __str__(self):
        return f"{self.product_name} x {self.quantity} - {self.order.order_number}"
    
    def save(self, *args, **kwargs):
        # Calculate total price
        self.total_price = self.unit_price * self.quantity
        super().save(*args, **kwargs)

class OrderStatusHistory(models.Model):
    """Track order status changes."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='status_history')
    status = models.CharField(max_length=20, choices=Order.STATUS_CHOICES)
    notes = models.TextField(blank=True)
    changed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'order_status_history'
        ordering = ['-created_at']
        verbose_name = 'Order Status History'
        verbose_name_plural = 'Order Status Histories'
    
    def __str__(self):
        return f"{self.order.order_number} - {self.status}"

class Coupon(models.Model):
    """Discount coupons."""
    DISCOUNT_TYPE_CHOICES = [
        ('percentage', 'Percentage'),
        ('fixed', 'Fixed Amount'),
        ('free_shipping', 'Free Shipping'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    
    # Discount settings
    discount_type = models.CharField(max_length=20, choices=DISCOUNT_TYPE_CHOICES)
    discount_value = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Usage limits
    minimum_order_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    maximum_discount_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    usage_limit = models.PositiveIntegerField(null=True, blank=True)  # Total usage limit
    usage_limit_per_user = models.PositiveIntegerField(default=1)
    used_count = models.PositiveIntegerField(default=0)
    
    # Validity
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    
    # Applicable products/categories
    applicable_products = models.ManyToManyField('products.Product', blank=True)
    applicable_categories = models.ManyToManyField('products.Category', blank=True)
    exclude_products = models.ManyToManyField(
        'products.Product', 
        blank=True, 
        related_name='excluded_from_coupons'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'coupons'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.code} - {self.name}"
    
    def is_valid(self, user=None, cart_total=Decimal('0.00')):
        """Check if coupon is valid for use."""
        from django.utils import timezone
        
        # Check if active
        if not self.is_active:
            return False, "Coupon is not active"
        
        # Check date validity
        now = timezone.now()
        if now < self.start_date:
            return False, "Coupon is not yet valid"
        if now > self.end_date:
            return False, "Coupon has expired"
        
        # Check minimum order amount
        if cart_total < self.minimum_order_amount:
            return False, f"Minimum order amount is {self.minimum_order_amount}"
        
        # Check usage limits
        if self.usage_limit and self.used_count >= self.usage_limit:
            return False, "Coupon usage limit reached"
        
        # Check per-user usage limit
        if user and self.usage_limit_per_user:
            user_usage = CouponUsage.objects.filter(coupon=self, user=user).count()
            if user_usage >= self.usage_limit_per_user:
                return False, "You have reached the usage limit for this coupon"
        
        return True, "Coupon is valid"
    
    def calculate_discount(self, cart_total):
        """Calculate discount amount for given cart total."""
        if self.discount_type == 'percentage':
            discount = cart_total * (self.discount_value / 100)
        elif self.discount_type == 'fixed':
            discount = min(self.discount_value, cart_total)
        else:  # free_shipping
            discount = Decimal('0.00')  # Shipping discount handled separately
        
        # Apply maximum discount limit
        if self.maximum_discount_amount:
            discount = min(discount, self.maximum_discount_amount)
        
        return discount

class CouponUsage(models.Model):
    """Track coupon usage by users."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coupon = models.ForeignKey(Coupon, on_delete=models.CASCADE, related_name='usages')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='coupon_usages')
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='coupon_usages')
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'coupon_usages'
        unique_together = ['coupon', 'order']
        verbose_name = 'Coupon Usage'
        verbose_name_plural = 'Coupon Usages'
    
    def __str__(self):
        return f"{self.coupon.code} used by {self.user.email}"

class ShippingMethod(models.Model):
    """Available shipping methods."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    
    # Pricing
    base_cost = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    cost_per_kg = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    free_shipping_threshold = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Delivery time
    min_delivery_days = models.PositiveIntegerField(default=1)
    max_delivery_days = models.PositiveIntegerField(default=7)
    
    # Availability
    is_active = models.BooleanField(default=True)
    available_countries = models.JSONField(default=list, blank=True)
    
    # Weight and size limits
    max_weight = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    max_length = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    max_width = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    max_height = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'shipping_methods'
        ordering = ['base_cost']
    
    def __str__(self):
        return self.name
    
    def calculate_cost(self, weight=Decimal('0.00'), order_total=Decimal('0.00')):
        """Calculate shipping cost based on weight and order total."""
        # Check for free shipping threshold
        if self.free_shipping_threshold and order_total >= self.free_shipping_threshold:
            return Decimal('0.00')
        
        # Calculate cost
        cost = self.base_cost + (weight * self.cost_per_kg)
        return cost
    
    def is_available_for_country(self, country):
        """Check if shipping method is available for given country."""
        if not self.available_countries:
            return True  # Available for all countries if none specified
        return country in self.available_countries

class Return(models.Model):
    """Product returns and refunds."""
    RETURN_STATUS_CHOICES = [
        ('requested', 'Return Requested'),
        ('approved', 'Return Approved'),
        ('rejected', 'Return Rejected'),
        ('received', 'Item Received'),
        ('refunded', 'Refunded'),
        ('completed', 'Completed'),
    ]
    
    RETURN_REASON_CHOICES = [
        ('defective', 'Defective Product'),
        ('wrong_item', 'Wrong Item Received'),
        ('not_as_described', 'Not as Described'),
        ('changed_mind', 'Changed Mind'),
        ('size_issue', 'Size Issue'),
        ('quality_issue', 'Quality Issue'),
        ('other', 'Other'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    return_number = models.CharField(max_length=20, unique=True, blank=True)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='returns')
    order_item = models.ForeignKey(OrderItem, on_delete=models.CASCADE, related_name='returns')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='returns')
    
    # Return details
    reason = models.CharField(max_length=20, choices=RETURN_REASON_CHOICES)
    detailed_reason = models.TextField()
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    
    # Status and processing
    status = models.CharField(max_length=20, choices=RETURN_STATUS_CHOICES, default='requested')
    refund_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    # Images for return evidence
    images = models.JSONField(default=list, blank=True)
    
    # Admin notes
    admin_notes = models.TextField(blank=True)
    processed_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='processed_returns'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    processed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'returns'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Return {self.return_number}"
    
    def save(self, *args, **kwargs):
        if not self.return_number:
            self.return_number = self.generate_return_number()
        super().save(*args, **kwargs)
    
    def generate_return_number(self):
        import random
        import string
        while True:
            number = 'RET' + ''.join(random.choices(string.digits, k=8))
            if not Return.objects.filter(return_number=number).exists():
                return number