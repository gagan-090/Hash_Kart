from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.products.models import Category, Product, Brand, ProductImage
from apps.vendors.models import Vendor
from apps.users.models import User
import random
from decimal import Decimal

User = get_user_model()

class Command(BaseCommand):
    help = 'Populate database with sample data for testing'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting to populate sample data...'))
        
        # Create sample users and vendors
        self.create_sample_users()
        
        # Create sample categories
        self.create_sample_categories()
        
        # Create sample brands
        self.create_sample_brands()
        
        # Create sample products
        self.create_sample_products()
        
        self.stdout.write(self.style.SUCCESS('Successfully populated sample data!'))

    def create_sample_users(self):
        self.stdout.write('Creating sample users and vendors...')
        
        # Create admin user
        admin_user, created = User.objects.get_or_create(
            email='admin@hashkart.com',
            defaults={
                'first_name': 'Admin',
                'last_name': 'User',
                'user_type': 'admin',
                'is_staff': True,
                'is_superuser': True,
                'is_email_verified': True,
            }
        )
        if created:
            admin_user.set_password('admin123')
            admin_user.save()
        
        # Create vendor users
        vendor_data = [
            {
                'email': 'vendor1@hashkart.com',
                'first_name': 'TechShop',
                'last_name': 'Electronics',
                'business_name': 'TechShop Electronics',
                'business_type': 'electronics'
            },
            {
                'email': 'vendor2@hashkart.com',
                'first_name': 'Fashion',
                'last_name': 'Hub',
                'business_name': 'Fashion Hub Store',
                'business_type': 'fashion'
            },
            {
                'email': 'vendor3@hashkart.com',
                'first_name': 'Home',
                'last_name': 'Essentials',
                'business_name': 'Home Essentials Plus',
                'business_type': 'home_garden'
            }
        ]
        
        for vendor_info in vendor_data:
            user, created = User.objects.get_or_create(
                email=vendor_info['email'],
                defaults={
                    'first_name': vendor_info['first_name'],
                    'last_name': vendor_info['last_name'],
                    'user_type': 'vendor',
                    'is_email_verified': True,
                }
            )
            if created:
                user.set_password('vendor123')
                user.save()
            
            # Create vendor profile
            vendor, created = Vendor.objects.get_or_create(
                user=user,
                defaults={
                    'business_name': vendor_info['business_name'],
                    'business_type': vendor_info['business_type'],
                    'business_email': vendor_info['email'],
                    'business_phone': f'+91{random.randint(7000000000, 9999999999)}',
                    'address_line_1': f'{random.randint(1, 999)} Business Street',
                    'city': 'Mumbai',
                    'state': 'Maharashtra',
                    'postal_code': '400001',
                    'verification_status': 'verified',
                }
            )

    def create_sample_categories(self):
        self.stdout.write('Creating sample categories...')
        
        categories_data = [
            {
                'name': 'Electronics',
                'slug': 'electronics',
                'description': 'Latest electronic gadgets and accessories',
                'image': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400',
                'is_featured': True
            },
            {
                'name': 'Mobile Phones',
                'slug': 'mobile-phones',
                'description': 'Smartphones and mobile accessories',
                'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
                'is_featured': True
            },
            {
                'name': 'Fashion',
                'slug': 'fashion',
                'description': 'Trendy clothing and accessories',
                'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400',
                'is_featured': True
            },
            {
                'name': 'Home & Living',
                'slug': 'home-living',
                'description': 'Home decor and living essentials',
                'image': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
                'is_featured': True
            },
            {
                'name': 'Sports & Fitness',
                'slug': 'sports-fitness',
                'description': 'Sports equipment and fitness gear',
                'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
                'is_featured': False
            },
            {
                'name': 'Books & Media',
                'slug': 'books-media',
                'description': 'Books, movies, and digital media',
                'image': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
                'is_featured': False
            }
        ]
        
        for cat_data in categories_data:
            category, created = Category.objects.get_or_create(
                slug=cat_data['slug'],
                defaults={
                    'name': cat_data['name'],
                    'description': cat_data['description'],
                    'image': cat_data['image'],
                    'is_featured': cat_data['is_featured'],
                    'is_active': True,
                    'sort_order': len(Category.objects.all()) + 1
                }
            )
            if created:
                self.stdout.write(f'Created category: {category.name}')

    def create_sample_brands(self):
        self.stdout.write('Creating sample brands...')
        
        brands_data = [
            {
                'name': 'Samsung',
                'slug': 'samsung',
                'description': 'South Korean electronics giant',
                'logo': 'https://logos-world.net/wp-content/uploads/2020/04/Samsung-Logo.png',
                'website': 'https://samsung.com'
            },
            {
                'name': 'Apple',
                'slug': 'apple',
                'description': 'American technology company',
                'logo': 'https://logos-world.net/wp-content/uploads/2020/04/Apple-Logo.png',
                'website': 'https://apple.com'
            },
            {
                'name': 'Nike',
                'slug': 'nike',
                'description': 'American athletic footwear and apparel',
                'logo': 'https://logos-world.net/wp-content/uploads/2020/04/Nike-Logo.png',
                'website': 'https://nike.com'
            },
            {
                'name': 'Adidas',
                'slug': 'adidas',
                'description': 'German athletic apparel and footwear',
                'logo': 'https://logos-world.net/wp-content/uploads/2020/04/Adidas-Logo.png',
                'website': 'https://adidas.com'
            },
            {
                'name': 'Zara',
                'slug': 'zara',
                'description': 'Spanish fast fashion retailer',
                'logo': 'https://logos-world.net/wp-content/uploads/2020/04/Zara-Logo.png',
                'website': 'https://zara.com'
            }
        ]
        
        for brand_data in brands_data:
            brand, created = Brand.objects.get_or_create(
                slug=brand_data['slug'],
                defaults={
                    'name': brand_data['name'],
                    'description': brand_data['description'],
                    'logo': brand_data['logo'],
                    'website': brand_data['website'],
                    'is_active': True
                }
            )
            if created:
                self.stdout.write(f'Created brand: {brand.name}')

    def create_sample_products(self):
        self.stdout.write('Creating sample products...')
        
        # Get categories and brands
        electronics = Category.objects.get(slug='electronics')
        mobile_phones = Category.objects.get(slug='mobile-phones')
        fashion = Category.objects.get(slug='fashion')
        home_living = Category.objects.get(slug='home-living')
        sports = Category.objects.get(slug='sports-fitness')
        
        samsung = Brand.objects.get(slug='samsung')
        apple = Brand.objects.get(slug='apple')
        nike = Brand.objects.get(slug='nike')
        zara = Brand.objects.get(slug='zara')
        
        vendors = list(Vendor.objects.all())
        
        products_data = [
            # Electronics
            {
                'name': 'Samsung Galaxy S24 Ultra',
                'slug': 'samsung-galaxy-s24-ultra',
                'description': 'Latest flagship smartphone with S Pen and AI features',
                'category': mobile_phones,
                'brand': samsung,
                'price': Decimal('89999.00'),
                'compare_price': Decimal('99999.00'),
                'cost_price': Decimal('75000.00'),
                'stock_quantity': 50,
                'images': [
                    'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=500',
                    'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=500'
                ],
                'is_featured': True
            },
            {
                'name': 'iPhone 15 Pro Max',
                'slug': 'iphone-15-pro-max',
                'description': 'Apple\'s most advanced iPhone with titanium design',
                'category': mobile_phones,
                'brand': apple,
                'price': Decimal('134900.00'),
                'compare_price': Decimal('139900.00'),
                'cost_price': Decimal('120000.00'),
                'stock_quantity': 30,
                'images': [
                    'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=500',
                    'https://images.unsplash.com/photo-1695048133078-d5d82b5c4cba?w=500'
                ],
                'is_featured': True
            },
            {
                'name': 'Samsung 55" 4K Smart TV',
                'slug': 'samsung-55-4k-smart-tv',
                'description': 'Crystal UHD 4K Smart TV with Tizen OS',
                'category': electronics,
                'brand': samsung,
                'price': Decimal('45999.00'),
                'compare_price': Decimal('52999.00'),
                'cost_price': Decimal('38000.00'),
                'stock_quantity': 25,
                'images': [
                    'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=500',
                    'https://images.unsplash.com/photo-1571498681579-9b5b16e52ef6?w=500'
                ],
                'is_featured': True
            },
            
            # Fashion
            {
                'name': 'Nike Air Max 270',
                'slug': 'nike-air-max-270',
                'description': 'Comfortable lifestyle sneakers with Air Max cushioning',
                'category': fashion,
                'brand': nike,
                'price': Decimal('12995.00'),
                'compare_price': Decimal('14995.00'),
                'cost_price': Decimal('8000.00'),
                'stock_quantity': 100,
                'images': [
                    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
                    'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=500'
                ],
                'is_featured': True
            },
            {
                'name': 'Zara Casual T-Shirt',
                'slug': 'zara-casual-t-shirt',
                'description': 'Premium cotton casual t-shirt for everyday wear',
                'category': fashion,
                'brand': zara,
                'price': Decimal('1999.00'),
                'compare_price': Decimal('2499.00'),
                'cost_price': Decimal('800.00'),
                'stock_quantity': 200,
                'images': [
                    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500',
                    'https://images.unsplash.com/photo-1583743814966-8936f37f5c50?w=500'
                ],
                'is_featured': False
            },
            
            # Home & Living
            {
                'name': 'Modern Table Lamp',
                'slug': 'modern-table-lamp',
                'description': 'Elegant bedside table lamp with LED bulb',
                'category': home_living,
                'brand': None,
                'price': Decimal('2999.00'),
                'compare_price': Decimal('3999.00'),
                'cost_price': Decimal('1500.00'),
                'stock_quantity': 75,
                'images': [
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
                    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500'
                ],
                'is_featured': False
            },
            {
                'name': 'Decorative Plant Pot',
                'slug': 'decorative-plant-pot',
                'description': 'Ceramic plant pot with drainage for indoor plants',
                'category': home_living,
                'brand': None,
                'price': Decimal('899.00'),
                'compare_price': Decimal('1299.00'),
                'cost_price': Decimal('400.00'),
                'stock_quantity': 150,
                'images': [
                    'https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=500',
                    'https://images.unsplash.com/photo-1606134893016-fd75d5d35bea?w=500'
                ],
                'is_featured': False
            },
            
            # Sports
            {
                'name': 'Yoga Mat Premium',
                'slug': 'yoga-mat-premium',
                'description': 'Non-slip yoga mat for home and studio practice',
                'category': sports,
                'brand': None,
                'price': Decimal('1499.00'),
                'compare_price': Decimal('1999.00'),
                'cost_price': Decimal('600.00'),
                'stock_quantity': 80,
                'images': [
                    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=500',
                    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500'
                ],
                'is_featured': False
            }
        ]
        
        for product_data in products_data:
            vendor = random.choice(vendors)
            
            product, created = Product.objects.get_or_create(
                slug=product_data['slug'],
                defaults={
                    'name': product_data['name'],
                    'description': product_data['description'],
                    'category': product_data['category'],
                    'brand': product_data['brand'],
                    'vendor': vendor,
                    'price': product_data['price'],
                    'compare_price': product_data['compare_price'],
                    'cost_price': product_data['cost_price'],
                    'stock_quantity': product_data['stock_quantity'],
                    'sku': f'SKU{random.randint(10000, 99999)}',
                    'barcode': f'{random.randint(1000000000000, 9999999999999)}',
                    'weight': Decimal(f'{random.uniform(0.1, 5.0):.2f}'),
                    'is_featured': product_data['is_featured'],
                    'status': 'published',
                    'meta_title': product_data['name'],
                    'meta_description': product_data['description'][:160],
                    'average_rating': Decimal(f'{random.uniform(3.5, 5.0):.1f}'),
                    'review_count': random.randint(10, 500)
                }
            )
            
            if created:
                self.stdout.write(f'Created product: {product.name}')
                
                # Add product images
                for i, image_url in enumerate(product_data['images']):
                    ProductImage.objects.create(
                        product=product,
                        image=image_url,
                        alt_text=f'{product.name} - Image {i+1}',
                        is_primary=(i == 0),
                        sort_order=i
                    )