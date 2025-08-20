# apps/analytics/views.py
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Sum, Count, Avg, F
from django.utils import timezone
from datetime import timedelta, datetime
import json

from .models import (
    BusinessAnalytics, VendorAnalytics, ProductAnalytics,
    CustomerAnalytics, UserActivityLog
)
from .serializers import (
    BusinessAnalyticsSerializer, VendorAnalyticsSerializer,
    ProductAnalyticsSerializer, DashboardAnalyticsSerializer,
    VendorDashboardSerializer, ReportSerializer
)
from core.permissions import IsVendorOnly, IsAdminOnly

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def admin_dashboard_analytics(request):
    """Get admin dashboard analytics."""
    # Get date range
    days = int(request.query_params.get('days', 30))
    end_date = timezone.now().date()
    start_date = end_date - timedelta(days=days)
    
    # Get business analytics
    analytics = BusinessAnalytics.objects.filter(
        date__range=[start_date, end_date]
    ).order_by('date')
    
    if not analytics.exists():
        return Response({
            'success': False,
            'message': 'No analytics data available'
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Calculate totals
    total_revenue = sum(a.total_revenue for a in analytics)
    total_orders = sum(a.total_orders for a in analytics)
    total_customers = sum(a.new_customers for a in analytics)
    
    # Calculate growth rates
    latest = analytics.last()
    previous_period_start = start_date - timedelta(days=days)
    previous_analytics = BusinessAnalytics.objects.filter(
        date__range=[previous_period_start, start_date]
    )
    
    previous_revenue = sum(a.total_revenue for a in previous_analytics)
    revenue_growth = 0
    if previous_revenue > 0:
        revenue_growth = ((total_revenue - previous_revenue) / previous_revenue) * 100
    
    # Get recent activity
    from apps.orders.models import Order
    from django.contrib.auth import get_user_model
    from apps.products.models import Product
    
    User = get_user_model()
    
    recent_orders = Order.objects.order_by('-created_at')[:5]
    recent_customers = User.objects.filter(
        date_joined__gte=timezone.now() - timedelta(days=7)
    ).order_by('-date_joined')[:5]
    
    # Top products by sales
    top_products = Product.objects.annotate(
        total_sales=Sum('orderitem__total_price')
    ).order_by('-total_sales')[:5]
    
    # Charts data
    revenue_chart = [
        {
            'date': a.date.isoformat(),
            'revenue': float(a.total_revenue),
            'orders': a.total_orders
        }
        for a in analytics
    ]
    
    dashboard_data = {
        'total_revenue': total_revenue,
        'revenue_growth': round(revenue_growth, 2),
        'total_orders': total_orders,
        'orders_growth': 0,  # Calculate similarly
        'total_customers': User.objects.count(),
        'new_customers_today': latest.new_customers if latest else 0,
        'total_products': Product.objects.count(),
        'out_of_stock_products': Product.objects.filter(stock_quantity=0).count(),
        'recent_orders': [
            {
                'id': str(order.id),
                'order_number': order.order_number,
                'customer': order.customer_full_name,
                'total': float(order.total_amount),
                'status': order.status,
                'created_at': order.created_at.isoformat()
            }
            for order in recent_orders
        ],
        'recent_customers': [
            {
                'id': str(user.id),
                'name': user.full_name,
                'email': user.email,
                'joined_at': user.date_joined.isoformat()
            }
            for user in recent_customers
        ],
        'top_products': [
            {
                'id': str(product.id),
                'name': product.name,
                'sales': float(product.total_sales or 0),
                'stock': product.stock_quantity
            }
            for product in top_products
        ],
        'revenue_chart': revenue_chart,
        'orders_chart': revenue_chart,  # Same data for now
        'customer_acquisition_chart': [
            {
                'date': a.date.isoformat(),
                'new_customers': a.new_customers,
                'returning_customers': a.returning_customers
            }
            for a in analytics
        ]
    }
    
    serializer = DashboardAnalyticsSerializer(dashboard_data)
    return Response({
        'success': True,
        'data': serializer.data
    })

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def vendor_dashboard_analytics(request):
    """Get vendor dashboard analytics."""
    vendor = get_object_or_404('vendors.Vendor', user=request.user)
    
    # Get date range
    days = int(request.query_params.get('days', 30))
    end_date = timezone.now().date()
    start_date = end_date - timedelta(days=days)
    
    # Get vendor analytics
    analytics = VendorAnalytics.objects.filter(
        vendor=vendor,
        date__range=[start_date, end_date]
    ).order_by('date')
    
    # Calculate totals
    total_sales = sum(a.total_sales for a in analytics)
    total_orders = sum(a.total_orders for a in analytics)
    
    # Get order status counts
    from apps.orders.models import OrderItem
    order_items = OrderItem.objects.filter(vendor=vendor)
    
    pending_orders = order_items.filter(status='pending').count()
    processing_orders = order_items.filter(status='processing').count()
    shipped_orders = order_items.filter(status='shipped').count()
    
    # Get product metrics
    from apps.products.models import Product
    products = Product.objects.filter(vendor=vendor)
    
    total_products = products.count()
    out_of_stock_products = products.filter(stock_quantity=0).count()
    low_stock_products = products.filter(
        stock_quantity__gt=0,
        stock_quantity__lte=F('low_stock_threshold')
    ).count()
    
    # Performance metrics
    average_rating = vendor.average_rating
    fulfillment_rate = analytics.aggregate(
        avg_rate=Avg('order_fulfillment_rate')
    )['avg_rate'] or 0
    
    # Charts data
    sales_chart = [
        {
            'date': a.date.isoformat(),
            'sales': float(a.total_sales),
            'orders': a.total_orders
        }
        for a in analytics
    ]
    
    # Top products
    top_products = products.annotate(
        total_sales=Sum('orderitem__total_price')
    ).order_by('-total_sales')[:5]
    
    dashboard_data = {
        'total_sales': total_sales,
        'sales_growth': 0,  # Calculate growth rate
        'pending_orders': pending_orders,
        'processing_orders': processing_orders,
        'shipped_orders': shipped_orders,
        'total_products': total_products,
        'out_of_stock_products': out_of_stock_products,
        'low_stock_products': low_stock_products,
        'average_rating': float(average_rating),
        'fulfillment_rate': float(fulfillment_rate),
        'sales_chart': sales_chart,
        'orders_chart': sales_chart,
        'top_products': [
            {
                'id': str(product.id),
                'name': product.name,
                'sales': float(product.total_sales or 0),
                'stock': product.stock_quantity
            }
            for product in top_products
        ]
    }
    
    serializer = VendorDashboardSerializer(dashboard_data)
    return Response({
        'success': True,
        'data': serializer.data
    })

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_activity_analytics(request):
    """Get user activity analytics."""
    user = request.user
    days = int(request.query_params.get('days', 30))
    end_date = timezone.now()
    start_date = end_date - timedelta(days=days)
    
    # Get user activity logs
    activities = UserActivityLog.objects.filter(
        user=user,
        created_at__range=[start_date, end_date]
    )
    
    # Activity breakdown
    activity_breakdown = dict(
        activities.values('action').annotate(count=Count('id'))
        .values_list('action', 'count')
    )
    
    # Daily activity
    daily_activity = {}
    for activity in activities:
        date_key = activity.created_at.date().isoformat()
        if date_key not in daily_activity:
            daily_activity[date_key] = 0
        daily_activity[date_key] += 1
    
    # Recent activities
    recent_activities = activities.order_by('-created_at')[:10]
    
    return Response({
        'success': True,
        'data': {
            'total_activities': activities.count(),
            'activity_breakdown': activity_breakdown,
            'daily_activity': daily_activity,
            'recent_activities': [
                {
                    'action': activity.action,
                    'object_type': activity.object_type,
                    'created_at': activity.created_at.isoformat(),
                    'metadata': activity.metadata
                }
                for activity in recent_activities
            ]
        }
    })

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def track_user_activity(request):
    """Track user activity."""
    action = request.data.get('action')
    object_type = request.data.get('object_type', '')
    object_id = request.data.get('object_id')
    metadata = request.data.get('metadata', {})
    
    if not action:
        return Response({
            'success': False,
            'message': 'Action is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Get client information
    from core.utils import get_client_ip, get_user_agent_info
    ip_address = get_client_ip(request)
    user_agent_info = get_user_agent_info(request)
    
    # Create activity log
    UserActivityLog.objects.create(
        user=request.user,
        session_id=request.session.session_key or '',
        action=action,
        object_type=object_type,
        object_id=object_id,
        metadata=metadata,
        ip_address=ip_address,
        user_agent=request.META.get('HTTP_USER_AGENT', ''),
        referrer=request.META.get('HTTP_REFERER', '')
    )
    
    return Response({
        'success': True,
        'message': 'Activity tracked successfully'
    })

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def generate_report(request):
    """Generate analytics report."""
    serializer = ReportSerializer(data=request.data)
    
    if serializer.is_valid():
        data = serializer.validated_data
        report_type = data['report_type']
        date_from = data['date_from']
        date_to = data['date_to']
        filters = data.get('filters', {})
        format_type = data.get('format', 'json')
        
        # Generate report based on type
        if report_type == 'sales':
            report_data = generate_sales_report(date_from, date_to, filters)
        elif report_type == 'customers':
            report_data = generate_customer_report(date_from, date_to, filters)
        elif report_type == 'products':
            report_data = generate_product_report(date_from, date_to, filters)
        elif report_type == 'vendors':
            report_data = generate_vendor_report(date_from, date_to, filters)
        else:
            return Response({
                'success': False,
                'message': 'Invalid report type'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if format_type == 'json':
            return Response({
                'success': True,
                'data': report_data
            })
        elif format_type == 'csv':
            # Generate CSV response
            from django.http import HttpResponse
            import csv
            
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = f'attachment; filename="{report_type}_report.csv"'
            
            writer = csv.writer(response)
            # Write CSV headers and data based on report_data
            # Implementation depends on report structure
            
            return response
        
        # Add PDF generation if needed
        
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

def generate_sales_report(date_from, date_to, filters):
    """Generate sales analytics report."""
    from apps.orders.models import Order
    
    orders = Order.objects.filter(
        created_at__date__range=[date_from, date_to],
        status__in=['completed', 'delivered']
    )
    
    # Apply filters
    if filters.get('vendor'):
        orders = orders.filter(items__vendor_id=filters['vendor'])
    
    # Calculate metrics
    total_revenue = orders.aggregate(total=Sum('total_amount'))['total'] or 0
    total_orders = orders.count()
    average_order_value = total_revenue / total_orders if total_orders > 0 else 0
    
    # Daily breakdown
    daily_sales = {}
    for order in orders:
        date_key = order.created_at.date().isoformat()
        if date_key not in daily_sales:
            daily_sales[date_key] = {'revenue': 0, 'orders': 0}
        daily_sales[date_key]['revenue'] += float(order.total_amount)
        daily_sales[date_key]['orders'] += 1
    
    return {
        'summary': {
            'total_revenue': float(total_revenue),
            'total_orders': total_orders,
            'average_order_value': float(average_order_value)
        },
        'daily_breakdown': daily_sales,
        'top_products': [],  # Add product analysis
        'payment_methods': {}  # Add payment method breakdown
    }

def generate_customer_report(date_from, date_to, filters):
    """Generate customer analytics report."""
    from django.contrib.auth import get_user_model
    User = get_user_model()
    
    customers = User.objects.filter(
        date_joined__date__range=[date_from, date_to]
    )
    
    return {
        'summary': {
            'new_customers': customers.count(),
            'total_customers': User.objects.count()
        },
        'acquisition_trend': {},
        'customer_segments': {}
    }

def generate_product_report(date_from, date_to, filters):
    """Generate product analytics report."""
    from apps.products.models import Product
    
    products = Product.objects.filter(created_at__date__range=[date_from, date_to])
    
    return {
        'summary': {
            'new_products': products.count(),
            'total_products': Product.objects.count()
        },
        'top_sellers': [],
        'category_performance': {}
    }

def generate_vendor_report(date_from, date_to, filters):
    """Generate vendor analytics report."""
    from apps.vendors.models import Vendor
    
    vendors = Vendor.objects.filter(created_at__date__range=[date_from, date_to])
    
    return {
        'summary': {
            'new_vendors': vendors.count(),
            'total_vendors': Vendor.objects.count()
        },
        'performance_metrics': {},
        'commission_breakdown': {}
    }

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsAdminOnly])
def system_health_metrics(request):
    """Get system health and performance metrics."""
    from .models import SystemMetrics
    
    # Get latest metrics
    latest_metrics = SystemMetrics.objects.order_by('-timestamp').first()
    
    if not latest_metrics:
        return Response({
            'success': False,
            'message': 'No system metrics available'
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Get historical data for trends
    historical_metrics = SystemMetrics.objects.filter(
        timestamp__gte=timezone.now() - timedelta(hours=24)
    ).order_by('-timestamp')[:24]  # Last 24 hours
    
    trends = [
        {
            'timestamp': metric.timestamp.isoformat(),
            'response_time': float(metric.response_time_avg),
            'error_rate': float(metric.error_rate),
            'active_users': metric.active_users,
            'cpu_usage': float(metric.cpu_usage),
            'memory_usage': float(metric.memory_usage)
        }
        for metric in historical_metrics
    ]
    
    from .serializers import SystemMetricsSerializer
    serializer = SystemMetricsSerializer({
        'response_time_avg': latest_metrics.response_time_avg,
        'error_rate': latest_metrics.error_rate,
        'active_users': latest_metrics.active_users,
        'api_requests_per_minute': latest_metrics.api_requests_per_minute,
        'cpu_usage': latest_metrics.cpu_usage,
        'memory_usage': latest_metrics.memory_usage,
        'daily_revenue': latest_metrics.daily_revenue,
        'daily_orders': latest_metrics.daily_orders
    })
    
    return Response({
        'success': True,
        'data': {
            'current_metrics': serializer.data,
            'trends': trends,
            'health_status': 'healthy' if latest_metrics.error_rate < 1.0 else 'warning'
        }
    })

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def search_analytics(request):
    """Get search analytics."""
    from .models import SearchAnalytics
    
    days = int(request.query_params.get('days', 30))
    end_date = timezone.now().date()
    start_date = end_date - timedelta(days=days)
    
    # Get search analytics
    search_data = SearchAnalytics.objects.filter(
        date__range=[start_date, end_date]
    ).order_by('-search_count')
    
    # Top search terms
    top_searches = search_data[:20]
    
    # No results searches
    no_results = search_data.filter(no_results=True)[:10]
    
    # Search trends
    daily_searches = {}
    for search in search_data:
        date_key = search.date.isoformat()
        if date_key not in daily_searches:
            daily_searches[date_key] = 0
        daily_searches[date_key] += search.search_count
    
    return Response({
        'success': True,
        'data': {
            'top_searches': [
                {
                    'term': search.search_term,
                    'count': search.search_count,
                    'ctr': float(search.click_through_rate),
                    'conversion_rate': float(search.conversion_rate)
                }
                for search in top_searches
            ],
            'no_results_searches': [
                {
                    'term': search.search_term,
                    'count': search.search_count
                }
                for search in no_results
            ],
            'daily_trends': daily_searches
        }
    })