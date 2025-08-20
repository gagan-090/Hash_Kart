# apps/products/management/commands/create_sample_data.py
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.vendors.models import Vendor
from apps.products.models import Category, Brand, Product, ProductAttribute, ProductAttributeValue

User = get_user_model()

class Command(BaseCommand):
    help = 'Create sample product data for testing'

    def handle(self, *args, **options):
        self.stdout.write('Creating sample product data...')
        
        # Create sample categories
        categories = [
            {
                'name': 'Electronics',
                'description': 'Electronic devices and accessories',
                'icon': 'fas fa-laptop'
            },
            {
                'name': 'Fashion',
                'description': 'Clothing and fashion accessories',
                'icon': 'fas fa-tshirt'
            },
            {
                'name': 'Home & Garden',
                'description': 'Home improvement and garden supplies',
                'icon': 'fas fa-home'
            },
            {
                'name': 'Sports',
                'description': 'Sports and outdoor equipment',
                'icon': 'fas fa-football-ball'
            },
            {
                'name': 'Books',
                'description': 'Books and educational materials',
                'icon': 'fas fa-book'
            }
        ]
        
        for cat_data in categories:
            category, created = Category.objects.get_or_create(
                name=cat_data['name'],
                defaults=cat_data
            )
            if created:
                self.stdout.write(f'Created category: {category.name}')
        
        # Create subcategories for Electronics
        electronics = Category.objects.get(name='Electronics')
        electronics_subcats = [
            {'name': 'Smartphones', 'parent': electronics},
            {'name': 'Laptops', 'parent': electronics},
            {'name': 'Tablets', 'parent': electronics},
            {'name': 'Accessories', 'parent': electronics},
        ]
        
        for subcat_data in electronics_subcats:
            subcat, created = Category.objects.get_or_create(
                name=subcat_data['name'],
                defaults=subcat_data
            )
            if created:
                self.stdout.write(f'Created subcategory: {subcat.name}')
        
        # Create sample brands
        brands = [
            {'name': 'Apple', 'description': 'Technology company'},
            {'name': 'Samsung', 'description': 'Electronics manufacturer'},
            {'name': 'Nike', 'description': 'Sports brand'},
            {'name': 'Adidas', 'description': 'Sports brand'},
            {'name': 'Zara', 'description': 'Fashion brand'},
        ]
        
        for brand_data in brands:
            brand, created = Brand.objects.get_or_create(
                name=brand_data['name'],
                defaults=brand_data
            )
            if created:
                self.stdout.write(f'Created brand: {brand.name}')
        
        # Create sample product attributes
        attributes = [
            {'name': 'Color', 'type': 'color', 'is_variation': True},
            {'name': 'Size', 'type': 'text', 'is_variation': True},
            {'name': 'Material', 'type': 'text', 'is_variation': False},
            {'name': 'Storage', 'type': 'text', 'is_variation': True},
            {'name': 'RAM', 'type': 'text', 'is_variation': True},
        ]
        
        for attr_data in attributes:
            attr, created = ProductAttribute.objects.get_or_create(
                name=attr_data['name'],
                defaults=attr_data
            )
            if created:
                self.stdout.write(f'Created attribute: {attr.name}')
        
        # Create attribute values
        color_attr = ProductAttribute.objects.get(name='Color')
        colors = [
            {'value': 'Red', 'color_code': '#FF0000'},
            {'value': 'Blue', 'color_code': '#0000FF'},
            {'value': 'Green', 'color_code': '#00FF00'},
            {'value': 'Black', 'color_code': '#000000'},
            {'value': 'White', 'color_code': '#FFFFFF'},
        ]
        
        for color_data in colors:
            color_val, created = ProductAttributeValue.objects.get_or_create(
                attribute=color_attr,
                value=color_data['value'],
                defaults=color_data
            )
            if created:
                self.stdout.write(f'Created color value: {color_val.value}')
        
        size_attr = ProductAttribute.objects.get(name='Size')
        sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL']
        
        for size in sizes:
            size_val, created = ProductAttributeValue.objects.get_or_create(
                attribute=size_attr,
                value=size
            )
            if created:
                self.stdout.write(f'Created size value: {size_val.value}')
        
        self.stdout.write(
            self.style.SUCCESS('Successfully created sample product data!')
        )



