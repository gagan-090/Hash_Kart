# Create new file: apps/analytics/__init__.py
# Create new file: apps/analytics/models.py

from django.db import models
from django.contrib.auth import get_user_model
from decimal import Decimal
import uuid

User = get_user_model()

class BusinessAnalytics(models.Model):
    """Daily business analytics summary."""
    date = models.DateField(unique=True)
    
    # Revenue metrics
    total_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    net_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    commission_earned = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    refunded_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    
    # Order metrics
    total_orders = models.PositiveIntegerField(default=0)
    completed_orders = models.PositiveIntegerField(default=0)
    cancelled_orders = models.PositiveIntegerField(default=0)
    pending_orders = models.PositiveIntegerField(default=0)
    
    # Customer metrics
    new_customers = models.PositiveIntegerField(default=0)
    returning_customers = models.PositiveIntegerField(default=0)
    active_customers = models.PositiveIntegerField(default=0)
    
    # Product metrics
    products_sold = models.PositiveIntegerField(default=0)
    new_products_added = models.PositiveIntegerField(default=0)
    out_of_stock_products = models.PositiveIntegerField(default=0)
    
    # Vendor metrics
    active_vendors = models.PositiveIntegerField(default=0)
    new_vendors = models.PositiveIntegerField(default=0)
    vendor_sales_volume = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    
    # Traffic metrics
    website_visits = models.PositiveIntegerField(default=0)
    unique_visitors = models.PositiveIntegerField(default=0)
    page_views = models.PositiveIntegerField(default=0)
    conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    
    # Additional metrics
    average_order_value = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    customer_acquisition_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    customer_lifetime_value = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'business_analytics'
        ordering = ['-date']
    
    def __str__(self):
        return f"Business Analytics - {self.date}"

class VendorAnalytics(models.Model):
    """Daily vendor performance analytics."""
    vendor = models.ForeignKey('vendors.Vendor', on_delete=models.CASCADE, related_name='analytics')
    date = models.DateField()
    
    # Sales metrics
    total_sales = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    total_orders = models.PositiveIntegerField(default=0)
    items_sold = models.PositiveIntegerField(default=0)
    average_order_value = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    # Product metrics
    total_products = models.PositiveIntegerField(default=0)
    active_products = models.PositiveIntegerField(default=0)
    out_of_stock_products = models.PositiveIntegerField(default=0)
    products_added = models.PositiveIntegerField(default=0)
    
    # Customer metrics
    unique_customers = models.PositiveIntegerField(default=0)
    new_customers = models.PositiveIntegerField(default=0)
    returning_customers = models.PositiveIntegerField(default=0)
    
    # Performance metrics
    order_fulfillment_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    average_shipping_time = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    return_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    customer_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    
    # Revenue breakdown
    commission_paid = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    net_earnings = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    refunded_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'vendor_analytics'
        unique_together = ['vendor', 'date']
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.vendor.business_name} - {self.date}"

class ProductAnalytics(models.Model):
    """Product performance analytics."""
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE, related_name='analytics')
    date = models.DateField()
    
    # Sales metrics
    units_sold = models.PositiveIntegerField(default=0)
    revenue_generated = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    orders_count = models.PositiveIntegerField(default=0)
    
    # Engagement metrics
    views = models.PositiveIntegerField(default=0)
    unique_views = models.PositiveIntegerField(default=0)
    add_to_cart = models.PositiveIntegerField(default=0)
    add_to_wishlist = models.PositiveIntegerField(default=0)
    
    # Conversion metrics
    view_to_cart_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    cart_to_purchase_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    overall_conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    
    # Inventory metrics
    stock_level = models.PositiveIntegerField(default=0)
    stock_turnover = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    
    # Customer feedback
    reviews_count = models.PositiveIntegerField(default=0)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    return_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'product_analytics'
        unique_together = ['product', 'date']
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.product.name} - {self.date}"

class CustomerAnalytics(models.Model):
    """Customer behavior analytics."""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='analytics')
    date = models.DateField()
    
    # Purchase behavior
    orders_placed = models.PositiveIntegerField(default=0)
    total_spent = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    items_purchased = models.PositiveIntegerField(default=0)
    average_order_value = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    # Engagement metrics
    sessions = models.PositiveIntegerField(default=0)
    page_views = models.PositiveIntegerField(default=0)
    time_spent = models.PositiveIntegerField(default=0)  # in minutes
    products_viewed = models.PositiveIntegerField(default=0)
    
    # Shopping behavior
    cart_additions = models.PositiveIntegerField(default=0)
    wishlist_additions = models.PositiveIntegerField(default=0)
    searches_performed = models.PositiveIntegerField(default=0)
    reviews_written = models.PositiveIntegerField(default=0)
    
    # Customer journey
    first_visit = models.BooleanField(default=False)
    returning_visit = models.BooleanField(default=False)
    days_since_last_order = models.PositiveIntegerField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'customer_analytics'
        unique_together = ['user', 'date']
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.user.email} - {self.date}"

class CategoryAnalytics(models.Model):
    """Category performance analytics."""
    category = models.ForeignKey('products.Category', on_delete=models.CASCADE, related_name='analytics')
    date = models.DateField()
    
    # Sales metrics
    total_sales = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    units_sold = models.PositiveIntegerField(default=0)
    orders_count = models.PositiveIntegerField(default=0)
    
    # Product metrics
    total_products = models.PositiveIntegerField(default=0)
    active_products = models.PositiveIntegerField(default=0)
    out_of_stock_products = models.PositiveIntegerField(default=0)
    
    # Engagement metrics
    category_views = models.PositiveIntegerField(default=0)
    unique_visitors = models.PositiveIntegerField(default=0)
    bounce_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    
    # Performance metrics
    average_product_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    return_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'category_analytics'
        unique_together = ['category', 'date']
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.category.name} - {self.date}"

class SearchAnalytics(models.Model):
    """Search behavior analytics."""
    date = models.DateField()
    search_term = models.CharField(max_length=255)
    
    # Search metrics
    search_count = models.PositiveIntegerField(default=0)
    unique_searches = models.PositiveIntegerField(default=0)
    results_count = models.PositiveIntegerField(default=0)
    
    # Engagement metrics
    clicks = models.PositiveIntegerField(default=0)
    conversions = models.PositiveIntegerField(default=0)
    click_through_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    
    # No results tracking
    no_results = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'search_analytics'
        unique_together = ['date', 'search_term']
        ordering = ['-date', '-search_count']
    
    def __str__(self):
        return f"'{self.search_term}' - {self.date}"

class RevenueForecast(models.Model):
    """Revenue forecasting model."""
    FORECAST_TYPE_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('yearly', 'Yearly'),
    ]
    
    date = models.DateField()
    forecast_type = models.CharField(max_length=20, choices=FORECAST_TYPE_CHOICES)
    
    # Forecast data
    predicted_revenue = models.DecimalField(max_digits=12, decimal_places=2)
    predicted_orders = models.PositiveIntegerField()
    confidence_score = models.DecimalField(max_digits=5, decimal_places=2)  # 0-100
    
    # Actual vs predicted (filled after the period)
    actual_revenue = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    actual_orders = models.PositiveIntegerField(null=True, blank=True)
    accuracy_score = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    
    # Model metadata
    model_version = models.CharField(max_length=50, default='v1.0')
    training_data_period = models.CharField(max_length=100, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'revenue_forecasts'
        unique_together = ['date', 'forecast_type']
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.forecast_type.title()} forecast for {self.date}"

class UserActivityLog(models.Model):
    """Track user activities for analytics."""
    ACTION_CHOICES = [
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('view_product', 'View Product'),
        ('add_to_cart', 'Add to Cart'),
        ('remove_from_cart', 'Remove from Cart'),
        ('add_to_wishlist', 'Add to Wishlist'),
        ('place_order', 'Place Order'),
        ('cancel_order', 'Cancel Order'),
        ('write_review', 'Write Review'),
        ('search', 'Search'),
        ('view_category', 'View Category'),
        ('update_profile', 'Update Profile'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activity_logs', null=True, blank=True)
    session_id = models.CharField(max_length=50, blank=True)
    
    # Activity details
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    object_type = models.CharField(max_length=50, blank=True)  # product, category, order, etc.
    object_id = models.UUIDField(null=True, blank=True)
    
    # Context data
    metadata = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    referrer = models.URLField(blank=True)
    
    # Location data
    country = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=100, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'user_activity_logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'action']),
            models.Index(fields=['session_id']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        user_display = self.user.email if self.user else f"Anonymous ({self.session_id})"
        return f"{user_display} - {self.action}"

class ABTestExperiment(models.Model):
    """A/B testing experiments."""
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('running', 'Running'),
        ('paused', 'Paused'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    description = models.TextField()
    
    # Experiment setup
    hypothesis = models.TextField()
    success_metric = models.CharField(max_length=100)
    target_page = models.CharField(max_length=255, blank=True)
    
    # Traffic allocation
    traffic_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=50.00)
    
    # Status and timing
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    
    # Results
    variant_a_conversions = models.PositiveIntegerField(default=0)
    variant_b_conversions = models.PositiveIntegerField(default=0)
    variant_a_visitors = models.PositiveIntegerField(default=0)
    variant_b_visitors = models.PositiveIntegerField(default=0)
    
    statistical_significance = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    confidence_level = models.DecimalField(max_digits=5, decimal_places=2, default=95.00)
    
    # Configuration
    experiment_config = models.JSONField(default=dict, blank=True)
    
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'ab_test_experiments'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.status}"
    
    @property
    def variant_a_conversion_rate(self):
        if self.variant_a_visitors > 0:
            return (self.variant_a_conversions / self.variant_a_visitors) * 100
        return 0.0
    
    @property
    def variant_b_conversion_rate(self):
        if self.variant_b_visitors > 0:
            return (self.variant_b_conversions / self.variant_b_visitors) * 100
        return 0.0

class AnalyticsReport(models.Model):
    """Scheduled analytics reports."""
    REPORT_TYPE_CHOICES = [
        ('sales', 'Sales Report'),
        ('customers', 'Customer Report'),
        ('products', 'Product Report'),
        ('vendors', 'Vendor Report'),
        ('marketing', 'Marketing Report'),
        ('inventory', 'Inventory Report'),
        ('financial', 'Financial Report'),
    ]
    
    FREQUENCY_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    report_type = models.CharField(max_length=50, choices=REPORT_TYPE_CHOICES)
    
    # Report configuration
    frequency = models.CharField(max_length=20, choices=FREQUENCY_CHOICES)
    filters = models.JSONField(default=dict, blank=True)
    metrics = models.JSONField(default=list, blank=True)
    
    # Recipients
    email_recipients = models.JSONField(default=list, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    last_generated = models.DateTimeField(null=True, blank=True)
    next_generation = models.DateTimeField(null=True, blank=True)
    
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'analytics_reports'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.frequency}"

class SystemMetrics(models.Model):
    """System performance metrics."""
    timestamp = models.DateTimeField(auto_now_add=True)
    
    # Performance metrics
    response_time_avg = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)  # ms
    response_time_95th = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)  # ms
    error_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)  # percentage
    
    # Usage metrics
    active_users = models.PositiveIntegerField(default=0)
    concurrent_sessions = models.PositiveIntegerField(default=0)
    api_requests_per_minute = models.PositiveIntegerField(default=0)
    
    # Resource utilization
    cpu_usage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)  # percentage
    memory_usage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)  # percentage
    disk_usage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)  # percentage
    
    # Database metrics
    db_connections = models.PositiveIntegerField(default=0)
    db_query_time_avg = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)  # ms
    
    # Business metrics snapshot
    daily_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    daily_orders = models.PositiveIntegerField(default=0)
    
    class Meta:
        db_table = 'system_metrics'
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"System metrics - {self.timestamp}"