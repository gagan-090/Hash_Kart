# core/utils.py
import random
import string
import secrets
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags
import uuid

def generate_random_string(length=10):
    """Generate a random string of specified length."""
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

def generate_unique_id():
    """Generate a unique ID."""
    return str(uuid.uuid4())

def generate_otp(length=6):
    """Generate a numeric OTP."""
    return ''.join(secrets.choice(string.digits) for _ in range(length))

def generate_token(length=64):
    """Generate a secure token."""
    return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(length))

def send_email_notification(subject, message, recipient_list, html_message=None):
    """Send email notification."""
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.EMAIL_HOST_USER,
            recipient_list=recipient_list,
            html_message=html_message,
            fail_silently=False,
        )
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False

def send_welcome_email(user):
    """Send welcome email to new user."""
    subject = 'Welcome to Multi-Vendor E-commerce Platform'
    html_message = render_to_string('emails/welcome.html', {'user': user})
    plain_message = strip_tags(html_message)
    
    return send_email_notification(
        subject=subject,
        message=plain_message,
        recipient_list=[user.email],
        html_message=html_message
    )

def send_verification_email(user, token):
    """Send email verification link."""
    verification_url = f"{settings.FRONTEND_URL}/verify-email?token={token.token}"
    subject = 'Verify Your Email Address'
    html_message = render_to_string('emails/verify_email.html', {
        'user': user,
        'verification_url': verification_url
    })
    plain_message = strip_tags(html_message)
    
    return send_email_notification(
        subject=subject,
        message=plain_message,
        recipient_list=[user.email],
        html_message=html_message
    )

def send_password_reset_email(user, token):
    """Send password reset email."""
    reset_url = f"{settings.FRONTEND_URL}/reset-password?token={token.token}"
    subject = 'Password Reset Request'
    html_message = render_to_string('emails/password_reset.html', {
        'user': user,
        'reset_url': reset_url
    })
    plain_message = strip_tags(html_message)
    
    return send_email_notification(
        subject=subject,
        message=plain_message,
        recipient_list=[user.email],
        html_message=html_message
    )

def send_vendor_approval_email(vendor):
    """Send vendor approval notification."""
    subject = 'Vendor Account Approved'
    html_message = render_to_string('emails/vendor_approved.html', {'vendor': vendor})
    plain_message = strip_tags(html_message)
    
    return send_email_notification(
        subject=subject,
        message=plain_message,
        recipient_list=[vendor.business_email],
        html_message=html_message
    )

def get_client_ip(request):
    """Get client IP address from request."""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

def get_user_agent_info(request):
    """Extract user agent information."""
    user_agent = request.META.get('HTTP_USER_AGENT', '')
    
    # Simple device type detection
    if 'Mobile' in user_agent:
        device_type = 'mobile'
    elif 'Tablet' in user_agent:
        device_type = 'tablet'
    else:
        device_type = 'desktop'
    
    return {
        'user_agent': user_agent,
        'device_type': device_type
    }

def validate_file_size(file, max_size_mb=5):
    """Validate uploaded file size."""
    if file.size > max_size_mb * 1024 * 1024:
        return False, f"File size exceeds {max_size_mb}MB limit"
    return True, "File size is valid"

def validate_image_file(file):
    """Validate image file type and size."""
    allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    
    if file.content_type not in allowed_types:
        return False, "Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed"
    
    size_valid, size_message = validate_file_size(file, max_size_mb=5)
    if not size_valid:
        return False, size_message
    
    return True, "Image is valid"

def validate_document_file(file):
    """Validate document file type and size."""
    allowed_types = ['application/pdf', 'image/jpeg', 'image/png']
    
    if file.content_type not in allowed_types:
        return False, "Invalid file type. Only PDF, JPEG, and PNG are allowed"
    
    size_valid, size_message = validate_file_size(file, max_size_mb=10)
    if not size_valid:
        return False, size_message
    
    return True, "Document is valid"


