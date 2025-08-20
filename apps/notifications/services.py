# apps/notifications/services.py
from django.core.mail import send_mail, EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
from django.utils import timezone
from .models import (
    Notification, NotificationTemplate, NotificationPreference,
    PushNotificationDevice, NotificationAnalytics
)
import logging
import json
import requests

logger = logging.getLogger(__name__)

class NotificationService:
    """Core notification service."""
    
    @staticmethod
    def create_notification(user, notification_type, title, message, 
                          content_object=None, data=None, priority='normal'):
        """Create a new notification."""
        try:
            # Get user preferences
            preferences, _ = NotificationPreference.objects.get_or_create(user=user)
            
            # Create notification record
            notification = Notification.objects.create(
                user=user,
                title=title,
                message=message,
                channel='in_app',
                content_object=content_object,
                priority=priority,
                data=data or {}
            )
            
            # Send through multiple channels based on preferences
            NotificationService.send_multi_channel(
                user, notification_type, title, message, 
                content_object, data, preferences
            )
            
            return notification
            
        except Exception as e:
            logger.error(f"Error creating notification: {e}")
            return None
    
    @staticmethod
    def send_multi_channel(user, notification_type, title, message, 
                          content_object=None, data=None, preferences=None):
        """Send notification through multiple channels."""
        if not preferences:
            preferences, _ = NotificationPreference.objects.get_or_create(user=user)
        
        # Prepare context for templates
        context = {
            'user': user,
            'title': title,
            'message': message,
            'user_name': user.full_name,
            'user_email': user.email,
        }
        
        # Add object-specific context
        if content_object:
            context['object'] = content_object
            if hasattr(content_object, 'order_number'):
                context['order_number'] = content_object.order_number
            if hasattr(content_object, 'name'):
                context['object_name'] = content_object.name
        
        # Add custom data
        if data:
            context.update(data)
        
        # Send email if enabled
        if preferences.is_channel_enabled('email', notification_type):
            EmailService.send_notification_email(
                user, notification_type, context
            )
        
        # Send SMS if enabled
        if preferences.is_channel_enabled('sms', notification_type):
            SMSService.send_notification_sms(
                user, notification_type, context
            )
        
        # Send push notification if enabled
        if preferences.is_channel_enabled('push', notification_type):
            PushNotificationService.send_notification_push(
                user, notification_type, title, message, data
            )

class EmailService:
    """Email notification service."""
    
    @staticmethod
    def send_notification_email(user, notification_type, context):
        """Send email notification using template."""
        try:
            # Get email template
            template = NotificationTemplate.objects.filter(
                notification_type=notification_type,
                channel='email',
                is_active=True
            ).first()
            
            if not template:
                logger.warning(f"No email template found for {notification_type}")
                return False
            
            # Render template content
            rendered = template.render_content(context)
            
            # Create email
            subject = rendered['subject']
            text_content = rendered['content']
            html_content = rendered['html_content']
            
            # Send email
            if html_content:
                msg = EmailMultiAlternatives(
                    subject=subject,
                    body=text_content,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    to=[user.email]
                )
                msg.attach_alternative(html_content, "text/html")
                msg.send()
            else:
                send_mail(
                    subject=subject,
                    message=text_content,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[user.email]
                )
            
            logger.info(f"Email sent to {user.email} for {notification_type}")
            return True
            
        except Exception as e:
            logger.error(f"Error sending email to {user.email}: {e}")
            return False
    
    @staticmethod
    def send_custom_email(to_email, subject, message, html_content=None):
        """Send custom email."""
        try:
            if html_content:
                msg = EmailMultiAlternatives(
                    subject=subject,
                    body=message,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    to=[to_email]
                )
                msg.attach_alternative(html_content, "text/html")
                msg.send()
            else:
                send_mail(
                    subject=subject,
                    message=message,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[to_email]
                )
            return True
        except Exception as e:
            logger.error(f"Error sending custom email to {to_email}: {e}")
            return False

class SMSService:
    """SMS notification service."""
    
    @staticmethod
    def send_notification_sms(user, notification_type, context):
        """Send SMS notification using template."""
        try:
            # Check if user has phone number
            if not user.phone:
                logger.warning(f"No phone number for user {user.email}")
                return False
            
            # Get SMS template
            template = NotificationTemplate.objects.filter(
                notification_type=notification_type,
                channel='sms',
                is_active=True
            ).first()
            
            if not template:
                logger.warning(f"No SMS template found for {notification_type}")
                return False
            
            # Render template content
            rendered = template.render_content(context)
            message = rendered['content']
            
            # Send SMS using configured provider
            return SMSService.send_sms(str(user.phone), message)
            
        except Exception as e:
            logger.error(f"Error sending SMS to {user.phone}: {e}")
            return False
    
    @staticmethod
    def send_sms(phone_number, message):
        """Send SMS using configured provider."""
        try:
            # Example using Twilio (configure based on your provider)
            sms_config = getattr(settings, 'SMS_CONFIG', {})
            provider = sms_config.get('PROVIDER', 'console')
            
            if provider == 'console':
                # For development - just log
                logger.info(f"SMS to {phone_number}: {message}")
                return True
            
            elif provider == 'twilio':
                # Implement Twilio SMS
                return SMSService._send_twilio_sms(phone_number, message)
            
            elif provider == 'msg91':
                # Implement MSG91 SMS (popular in India)
                return SMSService._send_msg91_sms(phone_number, message)
            
            else:
                logger.error(f"Unknown SMS provider: {provider}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending SMS: {e}")
            return False
    
    @staticmethod
    def _send_twilio_sms(phone_number, message):
        """Send SMS using Twilio."""
        try:
            from twilio.rest import Client
            
            sms_config = settings.SMS_CONFIG
            client = Client(
                sms_config['TWILIO_ACCOUNT_SID'],
                sms_config['TWILIO_AUTH_TOKEN']
            )
            
            client.messages.create(
                body=message,
                from_=sms_config['TWILIO_PHONE_NUMBER'],
                to=phone_number
            )
            return True
        except Exception as e:
            logger.error(f"Twilio SMS error: {e}")
            return False
    
    @staticmethod
    def _send_msg91_sms(phone_number, message):
        """Send SMS using MSG91."""
        try:
            sms_config = settings.SMS_CONFIG
            
            url = "https://api.msg91.com/api/v2/sendsms"
            headers = {
                'authkey': sms_config['MSG91_AUTH_KEY'],
                'content-type': 'application/json'
            }
            
            payload = {
                'sender': sms_config['MSG91_SENDER_ID'],
                'route': '4',
                'country': '91',
                'sms': [{
                    'message': message,
                    'to': [phone_number.replace('+', '')]
                }]
            }
            
            response = requests.post(url, headers=headers, data=json.dumps(payload))
            return response.status_code == 200
            
        except Exception as e:
            logger.error(f"MSG91 SMS error: {e}")
            return False

class PushNotificationService:
    """Push notification service."""
    
    @staticmethod
    def send_notification_push(user, notification_type, title, message, data=None):
        """Send push notification to user's devices."""
        try:
            # Get user's active devices
            devices = PushNotificationDevice.objects.filter(
                user=user,
                is_active=True
            )
            
            if not devices.exists():
                logger.info(f"No active devices for user {user.email}")
                return False
            
            success_count = 0
            for device in devices:
                if PushNotificationService.send_to_device(
                    device, title, message, data
                ):
                    success_count += 1
            
            return success_count > 0
            
        except Exception as e:
            logger.error(f"Error sending push notification: {e}")
            return False
    
    @staticmethod
    def send_to_device(device, title, message, data=None):
        """Send push notification to specific device."""
        try:
            if device.platform == 'android':
                return PushNotificationService._send_fcm_notification(
                    device.device_token, title, message, data
                )
            elif device.platform == 'ios':
                return PushNotificationService._send_apns_notification(
                    device.device_token, title, message, data
                )
            elif device.platform == 'web':
                return PushNotificationService._send_web_push_notification(
                    device.device_token, title, message, data
                )
            else:
                logger.error(f"Unknown platform: {device.platform}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending to device {device.id}: {e}")
            return False
    
    @staticmethod
    def _send_fcm_notification(device_token, title, message, data=None):
        """Send FCM notification for Android/Web."""
        try:
            push_config = getattr(settings, 'PUSH_NOTIFICATION_CONFIG', {})
            fcm_server_key = push_config.get('FCM_SERVER_KEY')
            
            if not fcm_server_key:
                logger.error("FCM server key not configured")
                return False
            
            url = 'https://fcm.googleapis.com/fcm/send'
            headers = {
                'Authorization': f'key={fcm_server_key}',
                'Content-Type': 'application/json',
            }
            
            payload = {
                'to': device_token,
                'notification': {
                    'title': title,
                    'body': message,
                    'sound': 'default',
                },
                'data': data or {}
            }
            
            response = requests.post(url, headers=headers, data=json.dumps(payload))
            return response.status_code == 200
            
        except Exception as e:
            logger.error(f"FCM notification error: {e}")
            return False
    
    @staticmethod
    def _send_apns_notification(device_token, title, message, data=None):
        """Send APNS notification for iOS."""
        try:
            # Implement APNS using libraries like pyfcm or aioapns
            # For now, using FCM which also supports iOS
            return PushNotificationService._send_fcm_notification(
                device_token, title, message, data
            )
        except Exception as e:
            logger.error(f"APNS notification error: {e}")
            return False
    
    @staticmethod
    def _send_web_push_notification(device_token, title, message, data=None):
        """Send web push notification."""
        try:
            # Use FCM for web push notifications
            return PushNotificationService._send_fcm_notification(
                device_token, title, message, data
            )
        except Exception as e:
            logger.error(f"Web push notification error: {e}")
            return False

class AnalyticsService:
    """Analytics tracking service."""
    
    @staticmethod
    def track_notification_sent(notification_type, channel):
        """Track notification sent for analytics."""
        try:
            today = timezone.now().date()
            analytics, created = NotificationAnalytics.objects.get_or_create(
                date=today,
                defaults={}
            )
            
            # Update sent count
            analytics.total_sent += 1
            
            if channel == 'email':
                analytics.email_sent += 1
            elif channel == 'sms':
                analytics.sms_sent += 1
            elif channel == 'push':
                analytics.push_sent += 1
            elif channel == 'in_app':
                analytics.in_app_sent += 1
            
            # Update type-specific counts
            if 'order' in notification_type:
                analytics.order_notifications += 1
            elif 'promotional' in notification_type:
                analytics.promotional_notifications += 1
            elif 'security' in notification_type:
                analytics.security_notifications += 1
            else:
                analytics.system_notifications += 1
            
            analytics.save()
            
        except Exception as e:
            logger.error(f"Error tracking notification analytics: {e}")
    
    @staticmethod
    def track_notification_delivered(channel):
        """Track notification delivered."""
        try:
            today = timezone.now().date()
            analytics, created = NotificationAnalytics.objects.get_or_create(
                date=today,
                defaults={}
            )
            
            analytics.total_delivered += 1
            
            if channel == 'email':
                analytics.email_delivered += 1
            elif channel == 'sms':
                analytics.sms_delivered += 1
            elif channel == 'push':
                analytics.push_delivered += 1
            
            analytics.save()
            
        except Exception as e:
            logger.error(f"Error tracking delivery analytics: {e}")
    
    @staticmethod
    def track_notification_opened(channel):
        """Track notification opened/read."""
        try:
            today = timezone.now().date()
            analytics, created = NotificationAnalytics.objects.get_or_create(
                date=today,
                defaults={}
            )
            
            analytics.total_opened += 1
            
            if channel == 'email':
                analytics.email_opened += 1
            elif channel == 'push':
                analytics.push_opened += 1
            elif channel == 'in_app':
                analytics.in_app_opened += 1
            
            analytics.save()
            
        except Exception as e:
            logger.error(f"Error tracking open analytics: {e}")

# Convenience functions for common notifications
def notify_order_created(order):
    """Send order creation notification."""
    NotificationService.create_notification(
        user=order.user,
        notification_type='order_created',
        title='Order Confirmed!',
        message=f'Your order #{order.order_number} has been confirmed.',
        content_object=order,
        data={
            'order_id': str(order.id),
            'order_number': order.order_number,
            'total_amount': str(order.total_amount)
        }
    )

def notify_order_shipped(order):
    """Send order shipped notification."""
    NotificationService.create_notification(
        user=order.user,
        notification_type='order_shipped',
        title='Order Shipped!',
        message=f'Your order #{order.order_number} has been shipped.',
        content_object=order,
        data={
            'order_id': str(order.id),
            'order_number': order.order_number,
            'tracking_number': order.tracking_number,
            'carrier': order.carrier
        }
    )

def notify_payment_successful(payment):
    """Send payment success notification."""
    NotificationService.create_notification(
        user=payment.user,
        notification_type='payment_successful',
        title='Payment Successful!',
        message=f'Payment of ₹{payment.amount} has been processed successfully.',
        content_object=payment,
        data={
            'payment_id': str(payment.id),
            'transaction_id': payment.transaction_id,
            'amount': str(payment.amount)
        }
    )

def notify_vendor_new_order(vendor, order_item):
    """Send new order notification to vendor."""
    NotificationService.create_notification(
        user=vendor.user,
        notification_type='vendor_new_order',
        title='New Order Received!',
        message=f'You have received a new order for {order_item.product_name}.',
        content_object=order_item,
        data={
            'order_id': str(order_item.order.id),
            'order_number': order_item.order.order_number,
            'product_name': order_item.product_name,
            'quantity': order_item.quantity,
            'total_price': str(order_item.total_price)
        }
    )

def notify_product_back_in_stock(product, users):
    """Send back in stock notification to interested users."""
    for user in users:
        NotificationService.create_notification(
            user=user,
            notification_type='product_back_in_stock',
            title='Product Back in Stock!',
            message=f'{product.name} is now back in stock.',
            content_object=product,
            data={
                'product_id': str(product.id),
                'product_name': product.name,
                'price': str(product.price)
            }
        )