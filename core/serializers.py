
# core/serializers.py
from rest_framework import serializers

class BaseResponseSerializer(serializers.Serializer):
    """Base response serializer for consistent API responses."""
    success = serializers.BooleanField(default=True)
    message = serializers.CharField(max_length=255)
    data = serializers.JSONField(required=False)

class PaginationSerializer(serializers.Serializer):
    """Pagination metadata serializer."""
    count = serializers.IntegerField()
    next = serializers.URLField(required=False, allow_null=True)
    previous = serializers.URLField(required=False, allow_null=True)
    page_size = serializers.IntegerField()
    total_pages = serializers.IntegerField()
    current_page = serializers.IntegerField()

class ErrorSerializer(serializers.Serializer):
    """Error response serializer."""
    success = serializers.BooleanField(default=False)
    message = serializers.CharField(max_length=255)
    errors = serializers.JSONField()
    status_code = serializers.IntegerField()