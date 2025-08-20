# core/exceptions.py
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    """Custom exception handler for API responses."""
    response = exception_handler(exc, context)
    
    if response is not None:
        custom_response_data = {
            'success': False,
            'message': 'An error occurred',
            'errors': response.data,
            'status_code': response.status_code
        }
        
        # Log the exception
        logger.error(f"API Exception: {exc}", exc_info=True)
        
        response.data = custom_response_data
    
    return response

class APIException(Exception):
    """Base API exception class."""
    def __init__(self, message, status_code=status.HTTP_400_BAD_REQUEST):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class ValidationError(APIException):
    """Validation error exception."""
    def __init__(self, message):
        super().__init__(message, status.HTTP_400_BAD_REQUEST)

class AuthenticationError(APIException):
    """Authentication error exception."""
    def __init__(self, message="Authentication required"):
        super().__init__(message, status.HTTP_401_UNAUTHORIZED)

class PermissionError(APIException):
    """Permission error exception."""
    def __init__(self, message="Permission denied"):
        super().__init__(message, status.HTTP_403_FORBIDDEN)

class NotFoundError(APIException):
    """Not found error exception."""
    def __init__(self, message="Resource not found"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)

