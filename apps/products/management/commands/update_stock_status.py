# apps/products/management/commands/update_stock_status.py
from django.core.management.base import BaseCommand
from apps.products.models import Product

class Command(BaseCommand):
    help = 'Update product stock status based on quantity'

    def handle(self, *args, **options):
        self.stdout.write('Updating stock status...')
        
        # Update out of stock products
        out_of_stock = Product.objects.filter(
            stock_quantity=0,
            manage_stock=True
        ).exclude(stock_status='out_of_stock')
        
        out_of_stock_count = out_of_stock.update(stock_status='out_of_stock')
        
        # Update in stock products
        in_stock = Product.objects.filter(
            stock_quantity__gt=0,
            manage_stock=True
        ).exclude(stock_status='in_stock')
        
        in_stock_count = in_stock.update(stock_status='in_stock')
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Updated {out_of_stock_count} products to out of stock and '
                f'{in_stock_count} products to in stock!'
            )
        )
