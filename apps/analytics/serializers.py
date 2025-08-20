# apps/analytics/serializers.py
from rest_framework import serializers
from .models import (
    Notification, NotificationTemplate, NotificationPreference,
    PushNotificationDevice, NotificationBatch, EmailCampaign
)

class BusinessAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for business analytics."""
    growth_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = BusinessAnalytics
        fields = [
            'date', 'total_revenue', 'net_revenue', 'commission_earned',
            'refunded_amount', 'total_orders', 'completed_orders',
            'cancelled_orders', 'new_customers', 'returning_customers',
            'active_customers', 'products_sold', 'new_products_added',
            'out_of_stock_products', 'active_vendors', 'new_vendors',
            'average_order_value', 'conversion_rate', 'growth_rate'
        ]
    
    def get_growth_rate(self, obj):
        # Calculate growth rate compared to previous period
        try:
            from datetime import timedelta
            previous_date = obj.date - timedelta(days=1)
            previous_analytics = BusinessAnalytics.objects.filter(
                date=previous_date
            ).first()
            
            if previous_analytics and previous_analytics.total_revenue > 0:
                growth = ((obj.total_revenue - previous_analytics.total_revenue) / 
                         previous_analytics.total_revenue) * 100
                return round(growth, 2)
            return 0.0
        except:
            return 0.0

class VendorAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for vendor analytics."""
    vendor_name = serializers.CharField(source='vendor.business_name', read_only=True)
    
    class Meta:
        model = VendorAnalytics
        fields = [
            'vendor_name', 'date', 'total_sales', 'total_orders',
            'items_sold', 'average_order_value', 'unique_customers',
            'order_fulfillment_rate', 'average_shipping_time',
            'return_rate', 'customer_rating', 'commission_paid',
            'net_earnings'
        ]

class ProductAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for product analytics."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_sku = serializers.CharField(source='product.sku', read_only=True)
    
    class Meta:
        model = ProductAnalytics
        fields = [
            'product_name', 'product_sku', 'date', 'units_sold',
            'revenue_generated', 'orders_count', 'views', 'unique_views',
            'add_to_cart', 'add_to_wishlist', 'view_to_cart_rate',
            'cart_to_purchase_rate', 'overall_conversion_rate',
            'average_rating', 'return_rate'
        ]

class CustomerAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for customer analytics."""
    customer_email = serializers.CharField(source='user.email', read_only=True)
    customer_name = serializers.CharField(source='user.full_name', read_only=True)
    
    class Meta:
        model = CustomerAnalytics
        fields = [
            'customer_email', 'customer_name', 'date', 'orders_placed',
            'total_spent', 'items_purchased', 'average_order_value',
            'sessions', 'page_views', 'time_spent', 'products_viewed',
            'cart_additions', 'wishlist_additions', 'searches_performed',
            'reviews_written', 'days_since_last_order'
        ]

class CategoryAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for category analytics."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = CategoryAnalytics
        fields = [
            'category_name', 'date', 'total_sales', 'units_sold',
            'orders_count', 'total_products', 'active_products',
            'category_views', 'unique_visitors', 'conversion_rate',
            'average_product_rating'
        ]

class SearchAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for search analytics."""
    class Meta:
        model = SearchAnalytics
        fields = [
            'date', 'search_term', 'search_count', 'unique_searches',
            'results_count', 'clicks', 'conversions', 'click_through_rate',
            'conversion_rate', 'no_results'
        ]

class DashboardAnalyticsSerializer(serializers.Serializer):
    """Serializer for dashboard analytics summary."""
    # Revenue metrics
    total_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    revenue_growth = serializers.DecimalField(max_digits=5, decimal_places=2)
    
    # Order metrics
    total_orders = serializers.IntegerField()
    orders_growth = serializers.DecimalField(max_digits=5, decimal_places=2)
    
    # Customer metrics
    total_customers = serializers.IntegerField()
    new_customers_today = serializers.IntegerField()
    
    # Product metrics
    total_products = serializers.IntegerField()
    out_of_stock_products = serializers.IntegerField()
    
    # Recent activity
    recent_orders = serializers.ListField()
    recent_customers = serializers.ListField()
    top_products = serializers.ListField()
    
    # Charts data
    revenue_chart = serializers.ListField()
    orders_chart = serializers.ListField()
    customer_acquisition_chart = serializers.ListField()

class ReportSerializer(serializers.Serializer):
    """Serializer for analytics reports."""
    report_type = serializers.ChoiceField(choices=[
        'sales', 'customers', 'products', 'vendors', 'inventory'
    ])
    date_from = serializers.DateField()
    date_to = serializers.DateField()
    filters = serializers.JSONField(required=False)
    format = serializers.ChoiceField(choices=['json', 'csv', 'pdf'], default='json')
    
    def validate(self, attrs):
        if attrs['date_to'] < attrs['date_from']:
            raise serializers.ValidationError("End date must be after start date")
        
        # Limit report range to prevent performance issues
        from datetime import timedelta
        if attrs['date_to'] - attrs['date_from'] > timedelta(days=365):
            raise serializers.ValidationError("Report range cannot exceed 365 days")
        
        return attrs

class VendorDashboardSerializer(serializers.Serializer):
    """Serializer for vendor dashboard analytics."""
    # Sales metrics
    total_sales = serializers.DecimalField(max_digits=12, decimal_places=2)
    sales_growth = serializers.DecimalField(max_digits=5, decimal_places=2)
    
    # Order metrics
    pending_orders = serializers.IntegerField()
    processing_orders = serializers.IntegerField()
    shipped_orders = serializers.IntegerField()
    
    # Product metrics
    total_products = serializers.IntegerField()
    out_of_stock_products = serializers.IntegerField()
    low_stock_products = serializers.IntegerField()
    
    # Performance metrics
    average_rating = serializers.DecimalField(max_digits=3, decimal_places=2)
    fulfillment_rate = serializers.DecimalField(max_digits=5, decimal_places=2)
    
    # Charts data
    sales_chart = serializers.ListField()
    orders_chart = serializers.ListField()
    top_products = serializers.ListField()

class SystemMetricsSerializer(serializers.Serializer):
    """Serializer for system performance metrics."""
    # Performance metrics
    response_time_avg = serializers.DecimalField(max_digits=8, decimal_places=2)
    error_rate = serializers.DecimalField(max_digits=5, decimal_places=2)
    
    # Usage metrics
    active_users = serializers.IntegerField()
    api_requests_per_minute = serializers.IntegerField()
    
    # Resource utilization
    cpu_usage = serializers.DecimalField(max_digits=5, decimal_places=2)
    memory_usage = serializers.DecimalField(max_digits=5, decimal_places=2)
    
    # Business metrics
    daily_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    daily_orders = serializers.IntegerField()

class AnalyticsInsightSerializer(serializers.Serializer):
    """Serializer for AI-generated analytics insights."""
    insight_type = serializers.ChoiceField(choices=[
        'trend', 'anomaly', 'opportunity', 'risk', 'recommendation'
    ])
    title = serializers.CharField(max_length=255)
    description = serializers.TextField()
    confidence_score = serializers.DecimalField(max_digits=5, decimal_places=2)
    data_points = serializers.JSONField()
    suggested_actions = serializers.ListField(child=serializers.CharField())
    created_at = serializers.DateTimeField()