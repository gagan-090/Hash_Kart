# apps/products/management/commands/update_product_ratings.py
from django.core.management.base import BaseCommand
from django.db.models import Avg, Count
from apps.products.models import Product, ProductReview

class Command(BaseCommand):
    help = 'Update product ratings and review counts'

    def handle(self, *args, **options):
        self.stdout.write('Updating product ratings...')
        
        products = Product.objects.all()
        updated_count = 0
        
        for product in products:
            reviews = ProductReview.objects.filter(
                product=product, 
                is_approved=True
            )
            
            if reviews.exists():
                avg_rating = reviews.aggregate(avg=Avg('rating'))['avg']
                review_count = reviews.count()
                
                product.average_rating = round(avg_rating, 2) if avg_rating else 0.0
                product.review_count = review_count
                product.save(update_fields=['average_rating', 'review_count'])
                
                updated_count += 1
            else:
                if product.average_rating != 0.0 or product.review_count != 0:
                    product.average_rating = 0.0
                    product.review_count = 0
                    product.save(update_fields=['average_rating', 'review_count'])
                    updated_count += 1
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully updated ratings for {updated_count} products!'
            )
        )
