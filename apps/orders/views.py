# apps/orders/views.py
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.db.models import Sum, Count, Avg, Q
from decimal import Decimal
from django.utils import timezone

from .models import (
    ShoppingCart, CartItem, Order, OrderItem, OrderStatusHistory,
    Coupon, CouponUsage, ShippingMethod, Return
)
from .serializers import (
    ShoppingCartSerializer, AddToCartSerializer, UpdateCartItemSerializer,
    OrderSerializer, OrderCreateSerializer, OrderDetailSerializer,
    ShippingMethodSerializer, CouponSerializer, ApplyCouponSerializer,
    ReturnSerializer, CreateReturnSerializer, VendorOrderItemSerializer,
    VendorOrderStatsSerializer, CheckoutSummarySerializer, UpdateOrderStatusSerializer
)
from core.permissions import IsVendorOnly, IsOwnerOrReadOnly
from apps.products.models import Product, ProductVariation

# Shopping Cart Views
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_cart(request):
    """Get user's shopping cart."""
    cart, created = ShoppingCart.objects.get_or_create(user=request.user)
    serializer = ShoppingCartSerializer(cart)
    return Response({
        'success': True,
        'data': serializer.data
    })

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def add_to_cart(request):
    """Add item to shopping cart."""
    serializer = AddToCartSerializer(data=request.data)
    
    if serializer.is_valid():
        product = serializer.validated_data['product_obj']
        variation = serializer.validated_data.get('variation_obj')
        quantity = serializer.validated_data['quantity']
        
        # Get or create cart
        cart, created = ShoppingCart.objects.get_or_create(user=request.user)
        
        # Check if item already exists in cart
        cart_item, item_created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            variation=variation,
            defaults={'quantity': quantity}
        )
        
        if not item_created:
            # Update quantity if item already exists
            cart_item.quantity += quantity
            
            # Check stock again after update
            max_stock = variation.stock_quantity if variation else (
                product.stock_quantity if product.manage_stock else 999999
            )
            
            if cart_item.quantity > max_stock:
                cart_item.quantity = max_stock
                cart_item.save()
                return Response({
                    'success': False,
                    'message': f'Only {max_stock} items available. Cart updated to maximum available quantity.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            cart_item.save()
            message = 'Cart item quantity updated'
        else:
            message = 'Item added to cart successfully'
        
        # Return updated cart
        cart_serializer = ShoppingCartSerializer(cart)
        return Response({
            'success': True,
            'message': message,
            'data': cart_serializer.data
        })
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
@permission_classes([permissions.IsAuthenticated])
def update_cart_item(request, item_id):
    """Update cart item quantity."""
    try:
        cart = ShoppingCart.objects.get(user=request.user)
        cart_item = CartItem.objects.get(id=item_id, cart=cart)
    except (ShoppingCart.DoesNotExist, CartItem.DoesNotExist):
        return Response({
            'success': False,
            'message': 'Cart item not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    serializer = UpdateCartItemSerializer(
        data=request.data,
        context={'cart_item': cart_item}
    )
    
    if serializer.is_valid():
        quantity = serializer.validated_data['quantity']
        
        if quantity == 0:
            cart_item.delete()
            message = 'Item removed from cart'
        else:
            cart_item.quantity = quantity
            cart_item.save()
            message = 'Cart item updated'
        
        # Return updated cart
        cart_serializer = ShoppingCartSerializer(cart)
        return Response({
            'success': True,
            'message': message,
            'data': cart_serializer.data
        })
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def remove_from_cart(request, item_id):
    """Remove item from cart."""
    try:
        cart = ShoppingCart.objects.get(user=request.user)
        cart_item = CartItem.objects.get(id=item_id, cart=cart)
        cart_item.delete()
        
        # Return updated cart
        cart_serializer = ShoppingCartSerializer(cart)
        return Response({
            'success': True,
            'message': 'Item removed from cart',
            'data': cart_serializer.data
        })
    except (ShoppingCart.DoesNotExist, CartItem.DoesNotExist):
        return Response({
            'success': False,
            'message': 'Cart item not found'
        }, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def clear_cart(request):
    """Clear all items from cart."""
    try:
        cart = ShoppingCart.objects.get(user=request.user)
        cart.items.all().delete()
        
        cart_serializer = ShoppingCartSerializer(cart)
        return Response({
            'success': True,
            'message': 'Cart cleared successfully',
            'data': cart_serializer.data
        })
    except ShoppingCart.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Cart not found'
        }, status=status.HTTP_404_NOT_FOUND)

# Shipping Methods
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_shipping_methods(request):
    """Get available shipping methods."""
    country = request.query_params.get('country', 'India')
    
    # Get cart details for cost calculation
    try:
        cart = ShoppingCart.objects.get(user=request.user)
        cart_total = cart.subtotal
        cart_weight = cart.total_weight
    except ShoppingCart.DoesNotExist:
        cart_total = Decimal('0.00')
        cart_weight = Decimal('0.00')
    
    # Filter shipping methods available for country
    shipping_methods = ShippingMethod.objects.filter(is_active=True)
    available_methods = [
        method for method in shipping_methods
        if method.is_available_for_country(country)
    ]
    
    serializer = ShippingMethodSerializer(
        available_methods,
        many=True,
        context={
            'cart_total': cart_total,
            'cart_weight': cart_weight
        }
    )
    
    return Response({
        'success': True,
        'data': serializer.data
    })

# Coupon Management
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def apply_coupon(request):
    """Apply coupon to cart."""
    serializer = ApplyCouponSerializer(data=request.data)
    
    if serializer.is_valid():
        coupon = serializer.coupon
        
        # Get cart
        try:
            cart = ShoppingCart.objects.get(user=request.user)
        except ShoppingCart.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Cart is empty'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate coupon
        is_valid, message = coupon.is_valid(user=request.user, cart_total=cart.subtotal)
        
        if not is_valid:
            return Response({
                'success': False,
                'message': message
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Calculate discount
        discount_amount = coupon.calculate_discount(cart.subtotal)
        
        # Store coupon in session (you might want to use a different approach)
        request.session['applied_coupon'] = {
            'id': str(coupon.id),
            'code': coupon.code,
            'discount_amount': str(discount_amount)
        }
        
        return Response({
            'success': True,
            'message': 'Coupon applied successfully',
            'data': {
                'coupon': CouponSerializer(coupon).data,
                'discount_amount': discount_amount,
                'new_total': cart.subtotal - discount_amount
            }
        })
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def remove_coupon(request):
    """Remove applied coupon."""
    if 'applied_coupon' in request.session:
        del request.session['applied_coupon']
        return Response({
            'success': True,
            'message': 'Coupon removed successfully'
        })
    
    return Response({
        'success': False,
        'message': 'No coupon applied'
    }, status=status.HTTP_400_BAD_REQUEST)

# Checkout
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def checkout_summary(request):
    """Get checkout summary with all calculations."""
    try:
        cart = ShoppingCart.objects.get(user=request.user)
    except ShoppingCart.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Cart is empty'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    if not cart.items.exists():
        return Response({
            'success': False,
            'message': 'Cart is empty'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Calculate totals
    subtotal = cart.subtotal
    tax_amount = subtotal * Decimal('0.18')  # 18% GST
    shipping_cost = Decimal('0.00')
    discount_amount = Decimal('0.00')
    
    # Get applied coupon from session
    applied_coupon = None
    if 'applied_coupon' in request.session:
        coupon_data = request.session['applied_coupon']
        try:
            applied_coupon = Coupon.objects.get(id=coupon_data['id'])
            discount_amount = Decimal(coupon_data['discount_amount'])
        except Coupon.DoesNotExist:
            del request.session['applied_coupon']
    
    # Get shipping method if provided
    shipping_method_id = request.query_params.get('shipping_method')
    shipping_method = None
    if shipping_method_id:
        try:
            shipping_method = ShippingMethod.objects.get(id=shipping_method_id, is_active=True)
            shipping_cost = shipping_method.calculate_cost(
                weight=cart.total_weight,
                order_total=subtotal
            )
        except ShippingMethod.DoesNotExist:
            pass
    
    # Calculate final total
    total_amount = subtotal + tax_amount + shipping_cost - discount_amount
    
    summary_data = {
        'subtotal': subtotal,
        'shipping_cost': shipping_cost,
        'tax_amount': tax_amount,
        'discount_amount': discount_amount,
        'total_amount': total_amount,
        'total_items': cart.total_items,
        'applied_coupon': CouponSerializer(applied_coupon).data if applied_coupon else None,
        'shipping_method': ShippingMethodSerializer(shipping_method).data if shipping_method else None
    }
    
    serializer = CheckoutSummarySerializer(summary_data)
    return Response({
        'success': True,
        'data': serializer.data
    })

# Order Management
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_order(request):
    """Create order from cart."""
    serializer = OrderCreateSerializer(data=request.data)
    
    if serializer.is_valid():
        # Get cart
        try:
            cart = ShoppingCart.objects.get(user=request.user)
        except ShoppingCart.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Cart is empty'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not cart.items.exists():
            return Response({
                'success': False,
                'message': 'Cart is empty'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        with transaction.atomic():
            # Create order
            order_data = {
                'user': request.user,
                'customer_email': request.user.email,
                'customer_first_name': request.user.first_name,
                'customer_last_name': request.user.last_name,
                'customer_phone': str(request.user.phone) if request.user.phone else '',
                
                # Shipping address
                'shipping_address_line_1': serializer.validated_data['shipping_address_line_1'],
                'shipping_address_line_2': serializer.validated_data.get('shipping_address_line_2', ''),
                'shipping_city': serializer.validated_data['shipping_city'],
                'shipping_state': serializer.validated_data['shipping_state'],
                'shipping_postal_code': serializer.validated_data['shipping_postal_code'],
                'shipping_country': serializer.validated_data['shipping_country'],
                
                'payment_method': serializer.validated_data['payment_method'],
                'customer_notes': serializer.validated_data.get('customer_notes', ''),
            }
            
            # Handle billing address
            if serializer.validated_data.get('billing_same_as_shipping', True):
                order_data.update({
                    'billing_address_line_1': order_data['shipping_address_line_1'],
                    'billing_address_line_2': order_data['shipping_address_line_2'],
                    'billing_city': order_data['shipping_city'],
                    'billing_state': order_data['shipping_state'],
                    'billing_postal_code': order_data['shipping_postal_code'],
                    'billing_country': order_data['shipping_country'],
                })
            else:
                order_data.update({
                    'billing_address_line_1': serializer.validated_data['billing_address_line_1'],
                    'billing_address_line_2': serializer.validated_data.get('billing_address_line_2', ''),
                    'billing_city': serializer.validated_data['billing_city'],
                    'billing_state': serializer.validated_data['billing_state'],
                    'billing_postal_code': serializer.validated_data['billing_postal_code'],
                    'billing_country': serializer.validated_data['billing_country'],
                })
            
            # Calculate totals
            subtotal = cart.subtotal
            tax_amount = subtotal * Decimal('0.18')  # 18% GST
            discount_amount = Decimal('0.00')
            
            # Handle shipping
            shipping_method = serializer.validated_data['shipping_method_obj']
            shipping_cost = shipping_method.calculate_cost(
                weight=cart.total_weight,
                order_total=subtotal
            )
            
            # Handle coupon
            coupon = serializer.validated_data.get('coupon_obj')
            if coupon:
                is_valid, message = coupon.is_valid(user=request.user, cart_total=subtotal)
                if is_valid:
                    discount_amount = coupon.calculate_discount(subtotal)
                else:
                    return Response({
                        'success': False,
                        'message': f'Coupon error: {message}'
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            # Calculate final total
            total_amount = subtotal + tax_amount + shipping_cost - discount_amount
            
            order_data.update({
                'subtotal': subtotal,
                'tax_amount': tax_amount,
                'shipping_cost': shipping_cost,
                'discount_amount': discount_amount,
                'total_amount': total_amount,
            })
            
            # Create order
            order = Order.objects.create(**order_data)
            
            # Create order items
            for cart_item in cart.items.all():
                # Store variation details
                variation_details = {}
                if cart_item.variation:
                    variation_details = {
                        'sku': cart_item.variation.sku,
                        'attributes': [
                            {
                                'attribute': attr.attribute.name,
                                'value': attr.value.value,
                                'color_code': attr.value.color_code
                            }
                            for attr in cart_item.variation.attributes.all()
                        ]
                    }
                
                # Get primary image URL
                primary_image = cart_item.product.images.filter(is_primary=True).first()
                product_image_url = ''
                if primary_image:
                    product_image_url = request.build_absolute_uri(primary_image.image.url)
                
                OrderItem.objects.create(
                    order=order,
                    vendor=cart_item.product.vendor,
                    product=cart_item.product,
                    product_name=cart_item.product.name,
                    product_sku=cart_item.product.sku,
                    product_image=product_image_url,
                    variation=cart_item.variation,
                    variation_details=variation_details,
                    quantity=cart_item.quantity,
                    unit_price=cart_item.unit_price,
                )
                
                # Update product stock
                if cart_item.variation:
                    cart_item.variation.stock_quantity -= cart_item.quantity
                    cart_item.variation.save()
                elif cart_item.product.manage_stock:
                    cart_item.product.stock_quantity -= cart_item.quantity
                    cart_item.product.save()
                
                # Update product sales count
                cart_item.product.sales_count += cart_item.quantity
                cart_item.product.save()
            
            # Create coupon usage record
            if coupon:
                CouponUsage.objects.create(
                    coupon=coupon,
                    user=request.user,
                    order=order,
                    discount_amount=discount_amount
                )
                coupon.used_count += 1
                coupon.save()
            
            # Create initial status history
            OrderStatusHistory.objects.create(
                order=order,
                status='pending',
                notes='Order created successfully',
                changed_by=request.user
            )
            
            # Clear cart
            cart.items.all().delete()
            
            # Clear session data
            if 'applied_coupon' in request.session:
                del request.session['applied_coupon']
            
            # Return order details
            order_serializer = OrderDetailSerializer(order)
            return Response({
                'success': True,
                'message': 'Order created successfully',
                'data': order_serializer.data
            }, status=status.HTTP_201_CREATED)
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

class UserOrderListView(generics.ListAPIView):
    """List user's orders."""
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Order.objects.filter(user=self.request.user).order_by('-created_at')

class UserOrderDetailView(generics.RetrieveAPIView):
    """Get user's order details."""
    serializer_class = OrderDetailSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Order.objects.filter(user=self.request.user)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def cancel_order(request, order_id):
    """Cancel an order."""
    try:
        order = Order.objects.get(id=order_id, user=request.user)
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Check if order can be cancelled
    if order.status not in ['pending', 'confirmed']:
        return Response({
            'success': False,
            'message': 'Order cannot be cancelled at this stage'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    with transaction.atomic():
        # Update order status
        order.status = 'cancelled'
        order.save()
        
        # Restore stock
        for item in order.items.all():
            if item.variation:
                item.variation.stock_quantity += item.quantity
                item.variation.save()
            elif item.product.manage_stock:
                item.product.stock_quantity += item.quantity
                item.product.save()
            
            # Update product sales count
            item.product.sales_count -= item.quantity
            item.product.save()
        
        # Create status history
        OrderStatusHistory.objects.create(
            order=order,
            status='cancelled',
            notes='Order cancelled by customer',
            changed_by=request.user
        )
        
        # Handle coupon usage (restore usage if needed)
        coupon_usage = order.coupon_usages.first()
        if coupon_usage:
            coupon_usage.coupon.used_count -= 1
            coupon_usage.coupon.save()
    
    return Response({
        'success': True,
        'message': 'Order cancelled successfully'
    })

# Vendor Order Management
class VendorOrderItemListView(generics.ListAPIView):
    """List vendor's order items."""
    serializer_class = VendorOrderItemSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendorOnly]
    
    def get_queryset(self):
        vendor = get_object_or_404('vendors.Vendor', user=self.request.user)
        return OrderItem.objects.filter(vendor=vendor).select_related('order').order_by('-created_at')

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def update_order_item_status(request, item_id):
    """Update order item status by vendor."""
    vendor = get_object_or_404('vendors.Vendor', user=request.user)
    
    try:
        order_item = OrderItem.objects.get(id=item_id, vendor=vendor)
    except OrderItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order item not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    serializer = UpdateOrderStatusSerializer(data=request.data)
    
    if serializer.is_valid():
        new_status = serializer.validated_data['status']
        notes = serializer.validated_data.get('notes', '')
        tracking_number = serializer.validated_data.get('tracking_number', '')
        carrier = serializer.validated_data.get('carrier', '')
        
        with transaction.atomic():
            # Update order item status
            order_item.status = new_status
            order_item.save()
            
            # Update main order status if all items have same status
            order = order_item.order
            all_items_status = order.items.values_list('status', flat=True).distinct()
            
            if len(all_items_status) == 1:
                order.status = new_status
                if new_status == 'shipped':
                    order.shipped_at = timezone.now()
                    order.tracking_number = tracking_number
                    order.carrier = carrier
                elif new_status == 'delivered':
                    order.delivered_at = timezone.now()
                order.save()
            
            # Create status history
            OrderStatusHistory.objects.create(
                order=order,
                status=new_status,
                notes=notes,
                changed_by=request.user
            )
        
        return Response({
            'success': True,
            'message': 'Order status updated successfully'
        })
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def vendor_order_stats(request):
    """Get vendor order statistics."""
    vendor = get_object_or_404('vendors.Vendor', user=request.user)
    
    # Get order items for this vendor
    order_items = OrderItem.objects.filter(vendor=vendor)
    
    # Calculate statistics
    stats = {
        'total_orders': order_items.values('order').distinct().count(),
        'pending_orders': order_items.filter(status='pending').values('order').distinct().count(),
        'processing_orders': order_items.filter(status='processing').values('order').distinct().count(),
        'shipped_orders': order_items.filter(status='shipped').values('order').distinct().count(),
        'delivered_orders': order_items.filter(status='delivered').values('order').distinct().count(),
        'cancelled_orders': order_items.filter(status='cancelled').values('order').distinct().count(),
        'total_revenue': order_items.filter(status__in=['delivered', 'shipped']).aggregate(
            total=Sum('total_price')
        )['total'] or Decimal('0.00'),
        'total_items_sold': order_items.filter(status__in=['delivered', 'shipped']).aggregate(
            total=Sum('quantity')
        )['total'] or 0,
    }
    
    # Calculate average order value
    if stats['total_orders'] > 0:
        stats['average_order_value'] = stats['total_revenue'] / stats['total_orders']
    else:
        stats['average_order_value'] = Decimal('0.00')
    
    serializer = VendorOrderStatsSerializer(stats)
    return Response({
        'success': True,
        'data': serializer.data
    })

# Return Management
class ReturnListView(generics.ListAPIView):
    """List user's returns."""
    serializer_class = ReturnSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Return.objects.filter(user=self.request.user).order_by('-created_at')

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_return(request):
    """Create a return request."""
    serializer = CreateReturnSerializer(data=request.data, context={'request': request})
    
    if serializer.is_valid():
        order_item = serializer.order_item
        
        # Check if there's already a return for this item
        existing_return = Return.objects.filter(order_item=order_item).first()
        if existing_return:
            return Response({
                'success': False,
                'message': 'Return request already exists for this item'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Handle image uploads
        images = request.FILES.getlist('images')
        image_urls = []
        
        for image in images:
            # Validate and save images (you might want to use a proper storage service)
            from core.utils import validate_image_file
            is_valid, message = validate_image_file(image)
            
            if not is_valid:
                return Response({
                    'success': False,
                    'message': f'Image validation failed: {message}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Save image and get URL (implement according to your storage setup)
            # For now, we'll just store the filename
            image_urls.append(image.name)
        
        # Create return
        return_obj = Return.objects.create(
            order=order_item.order,
            order_item=order_item,
            user=request.user,
            reason=serializer.validated_data['reason'],
            detailed_reason=serializer.validated_data['detailed_reason'],
            quantity=serializer.validated_data['quantity'],
            images=image_urls
        )
        
        return_serializer = ReturnSerializer(return_obj)
        return Response({
            'success': True,
            'message': 'Return request created successfully',
            'data': return_serializer.data
        }, status=status.HTTP_201_CREATED)
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

class ReturnDetailView(generics.RetrieveAPIView):
    """Get return details."""
    serializer_class = ReturnSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Return.objects.filter(user=self.request.user)

# Admin/Vendor Return Management
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def vendor_returns(request):
    """Get returns for vendor's products."""
    vendor = get_object_or_404('vendors.Vendor', user=request.user)
    
    returns = Return.objects.filter(
        order_item__vendor=vendor
    ).select_related('order', 'order_item', 'user').order_by('-created_at')
    
    serializer = ReturnSerializer(returns, many=True)
    return Response({
        'success': True,
        'data': serializer.data
    })

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated, IsVendorOnly])
def process_return(request, return_id):
    """Process a return request (approve/reject)."""
    vendor = get_object_or_404('vendors.Vendor', user=request.user)
    
    try:
        return_obj = Return.objects.get(id=return_id, order_item__vendor=vendor)
    except Return.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Return request not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    action = request.data.get('action')  # 'approve' or 'reject'
    admin_notes = request.data.get('admin_notes', '')
    
    if action not in ['approve', 'reject']:
        return Response({
            'success': False,
            'message': 'Invalid action. Use "approve" or "reject"'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    with transaction.atomic():
        if action == 'approve':
            return_obj.status = 'approved'
            # Calculate refund amount (you might want to add logic for partial refunds)
            return_obj.refund_amount = return_obj.order_item.unit_price * return_obj.quantity
        else:
            return_obj.status = 'rejected'
        
        return_obj.admin_notes = admin_notes
        return_obj.processed_by = request.user
        return_obj.processed_at = timezone.now()
        return_obj.save()
    
    return Response({
        'success': True,
        'message': f'Return request {action}d successfully'
    })

# Order Analytics
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_order_analytics(request):
    """Get user's order analytics."""
    user_orders = Order.objects.filter(user=request.user)
    
    analytics = {
        'total_orders': user_orders.count(),
        'total_spent': user_orders.aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00'),
        'average_order_value': user_orders.aggregate(avg=Avg('total_amount'))['avg'] or Decimal('0.00'),
        'orders_by_status': {
            status: user_orders.filter(status=status).count()
            for status, _ in Order.STATUS_CHOICES
        },
        'recent_orders': OrderSerializer(
            user_orders.order_by('-created_at')[:5], many=True
        ).data
    }
    
    return Response({
        'success': True,
        'data': analytics
    })