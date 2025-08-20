# apps/products/models.py
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.text import slugify
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()

class Category(models.Model):
    """Product categories with hierarchical structure."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=100, unique=True, blank=True)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='categories/', blank=True, null=True)
    icon = models.CharField(max_length=100, blank=True)  # For icon class names
    
    # Hierarchical structure
    parent = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='children'
    )
    
    # SEO fields
    meta_title = models.CharField(max_length=255, blank=True)
    meta_description = models.TextField(blank=True)
    meta_keywords = models.CharField(max_length=500, blank=True)
    
    # Status and ordering
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    sort_order = models.PositiveIntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'categories'
        verbose_name = 'Category'
        verbose_name_plural = 'Categories'
        ordering = ['sort_order', 'name']
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    @property
    def full_path(self):
        """Get full category path."""
        if self.parent:
            return f"{self.parent.full_path} > {self.name}"
        return self.name
    
    def get_all_children(self):
        """Get all descendant categories."""
        children = list(self.children.all())
        for child in self.children.all():
            children.extend(child.get_all_children())
        return children

class Brand(models.Model):
    """Product brands."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, blank=True)
    description = models.TextField(blank=True)
    logo = models.ImageField(upload_to='brands/', blank=True, null=True)
    website = models.URLField(blank=True)
    
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'brands'
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

class Product(models.Model):
    """Main product model."""
    PRODUCT_TYPE_CHOICES = [
        ('simple', 'Simple Product'),
        ('variable', 'Variable Product'),
        ('digital', 'Digital Product'),
        ('service', 'Service'),
    ]
    
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('pending', 'Pending Review'),
        ('published', 'Published'),
        ('rejected', 'Rejected'),
        ('archived', 'Archived'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vendor = models.ForeignKey('vendors.Vendor', on_delete=models.CASCADE, related_name='products')
    
    # Basic Information
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, blank=True)
    sku = models.CharField(max_length=100, unique=True, blank=True)
    barcode = models.CharField(max_length=100, blank=True)
    
    # Product Classification
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
    brand = models.ForeignKey(Brand, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    product_type = models.CharField(max_length=20, choices=PRODUCT_TYPE_CHOICES, default='simple')
    
    # Descriptions
    short_description = models.CharField(max_length=500, blank=True)
    description = models.TextField()
    specifications = models.JSONField(default=dict, blank=True)
    
    # Pricing (for simple products or base price for variable products)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    compare_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    cost_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    
    # Inventory (for simple products)
    stock_quantity = models.PositiveIntegerField(default=0)
    low_stock_threshold = models.PositiveIntegerField(default=5)
    manage_stock = models.BooleanField(default=True)
    stock_status = models.CharField(
        max_length=20,
        choices=[
            ('in_stock', 'In Stock'),
            ('out_of_stock', 'Out of Stock'),
            ('on_backorder', 'On Backorder'),
        ],
        default='in_stock'
    )
    
    # Physical attributes
    weight = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    length = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    width = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    height = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    
    # Shipping
    requires_shipping = models.BooleanField(default=True)
    shipping_class = models.CharField(max_length=100, blank=True)
    
    # Status and visibility
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    is_featured = models.BooleanField(default=False)
    is_digital = models.BooleanField(default=False)
    
    # SEO
    meta_title = models.CharField(max_length=255, blank=True)
    meta_description = models.TextField(blank=True)
    meta_keywords = models.CharField(max_length=500, blank=True)
    
    # Analytics
    view_count = models.PositiveIntegerField(default=0)
    sales_count = models.PositiveIntegerField(default=0)
    
    # Ratings
    average_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        default=0.00,
        validators=[MinValueValidator(0), MaxValueValidator(5)]
    )
    review_count = models.PositiveIntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'products'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'is_featured']),
            models.Index(fields=['category', 'status']),
            models.Index(fields=['vendor', 'status']),
            models.Index(fields=['slug']),
        ]
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        if not self.sku:
            self.sku = f"SKU{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)
    
    @property
    def is_in_stock(self):
        if not self.manage_stock:
            return True
        return self.stock_quantity > 0
    
    @property
    def is_low_stock(self):
        if not self.manage_stock:
            return False
        return self.stock_quantity <= self.low_stock_threshold
    
    @property
    def discount_percentage(self):
        if self.compare_price and self.compare_price > self.price:
            return round(((self.compare_price - self.price) / self.compare_price) * 100, 2)
        return 0

class ProductAttribute(models.Model):
    """Product attributes like Color, Size, Material, etc."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, blank=True)
    type = models.CharField(
        max_length=20,
        choices=[
            ('text', 'Text'),
            ('color', 'Color'),
            ('image', 'Image'),
            ('number', 'Number'),
        ],
        default='text'
    )
    is_variation = models.BooleanField(default=True)  # Can be used for variations
    is_visible = models.BooleanField(default=True)    # Show on product page
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'product_attributes'
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

class ProductAttributeValue(models.Model):
    """Values for product attributes."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    attribute = models.ForeignKey(ProductAttribute, on_delete=models.CASCADE, related_name='values')
    value = models.CharField(max_length=200)
    color_code = models.CharField(max_length=7, blank=True)  # For color attributes
    image = models.ImageField(upload_to='attribute_values/', blank=True, null=True)
    
    sort_order = models.PositiveIntegerField(default=0)
    
    class Meta:
        db_table = 'product_attribute_values'
        unique_together = ['attribute', 'value']
        ordering = ['sort_order', 'value']
    
    def __str__(self):
        return f"{self.attribute.name}: {self.value}"

class ProductVariation(models.Model):
    """Product variations (e.g., Red T-shirt Size L)."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='variations')
    
    # Variation identifier
    sku = models.CharField(max_length=100, unique=True, blank=True)
    
    # Pricing
    price = models.DecimalField(max_digits=10, decimal_places=2)
    compare_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    cost_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    
    # Inventory
    stock_quantity = models.PositiveIntegerField(default=0)
    
    # Physical attributes
    weight = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    length = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    width = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    height = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    is_default = models.BooleanField(default=False)
    
    # Image
    image = models.ImageField(upload_to='product_variations/', blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'product_variations'
        ordering = ['is_default', '-created_at']
    
    def __str__(self):
        return f"{self.product.name} - {self.sku}"
    
    def save(self, *args, **kwargs):
        if not self.sku:
            self.sku = f"{self.product.sku}-{uuid.uuid4().hex[:6].upper()}"
        
        # Ensure only one default variation per product
        if self.is_default:
            ProductVariation.objects.filter(
                product=self.product, 
                is_default=True
            ).exclude(id=self.id).update(is_default=False)
        
        super().save(*args, **kwargs)
    
    @property
    def is_in_stock(self):
        return self.stock_quantity > 0

class ProductVariationAttribute(models.Model):
    """Link between product variations and their attribute values."""
    variation = models.ForeignKey(ProductVariation, on_delete=models.CASCADE, related_name='attributes')
    attribute = models.ForeignKey(ProductAttribute, on_delete=models.CASCADE)
    value = models.ForeignKey(ProductAttributeValue, on_delete=models.CASCADE)
    
    class Meta:
        db_table = 'product_variation_attributes'
        unique_together = ['variation', 'attribute']
    
    def __str__(self):
        return f"{self.variation} - {self.attribute.name}: {self.value.value}"

class ProductImage(models.Model):
    """Product images gallery."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='products/')
    alt_text = models.CharField(max_length=255, blank=True)
    is_primary = models.BooleanField(default=False)
    sort_order = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'product_images'
        ordering = ['sort_order', 'created_at']
    
    def __str__(self):
        return f"{self.product.name} - Image {self.sort_order}"
    
    def save(self, *args, **kwargs):
        # Ensure only one primary image per product
        if self.is_primary:
            ProductImage.objects.filter(
                product=self.product, 
                is_primary=True
            ).exclude(id=self.id).update(is_primary=False)
        super().save(*args, **kwargs)

class ProductReview(models.Model):
    """Product reviews and ratings."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='product_reviews')
    
    rating = models.PositiveIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    title = models.CharField(max_length=255, blank=True)
    comment = models.TextField()
    
    # Helpful votes
    helpful_count = models.PositiveIntegerField(default=0)
    not_helpful_count = models.PositiveIntegerField(default=0)
    
    # Status
    is_verified_purchase = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'product_reviews'
        unique_together = ['product', 'user']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.product.name} - {self.rating} stars by {self.user.email}"

class ProductTag(models.Model):
    """Product tags for better organization and search."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=50, unique=True)
    slug = models.SlugField(max_length=50, unique=True, blank=True)
    color = models.CharField(max_length=7, default='#007bff')  # Hex color
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'product_tags'
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

class ProductTagAssignment(models.Model):
    """Many-to-many relationship between products and tags."""
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='tag_assignments')
    tag = models.ForeignKey(ProductTag, on_delete=models.CASCADE, related_name='product_assignments')
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'product_tag_assignments'
        unique_together = ['product', 'tag']
    
    def __str__(self):
        return f"{self.product.name} - {self.tag.name}"

class Wishlist(models.Model):
    """User wishlist for products."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wishlist_items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'wishlists'
        unique_together = ['user', 'product']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.email} - {self.product.name}"