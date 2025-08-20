# apps/products/management/commands/cleanup_unused_images.py
import os
from django.core.management.base import BaseCommand
from django.conf import settings
from apps.products.models import ProductImage

class Command(BaseCommand):
    help = 'Clean up unused product images'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        if dry_run:
            self.stdout.write('DRY RUN - No files will be deleted')
        
        self.stdout.write('Finding unused product images...')
        
        # Get all image files in the products directory
        products_dir = os.path.join(settings.MEDIA_ROOT, 'products')
        
        if not os.path.exists(products_dir):
            self.stdout.write('Products directory does not exist')
            return
        
        # Get all database image paths
        db_images = set()
        for img in ProductImage.objects.all():
            if img.image:
                db_images.add(os.path.basename(img.image.name))
        
        # Get all files in the directory
        file_count = 0
        deleted_count = 0
        
        for root, dirs, files in os.walk(products_dir):
            for file in files:
                file_count += 1
                if file not in db_images:
                    file_path = os.path.join(root, file)
                    if dry_run:
                        self.stdout.write(f'Would delete: {file_path}')
                    else:
                        try:
                            os.remove(file_path)
                            self.stdout.write(f'Deleted: {file_path}')
                        except OSError as e:
                            self.stdout.write(f'Error deleting {file_path}: {e}')
                    deleted_count += 1
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f'DRY RUN: Found {deleted_count} unused files out of {file_count} total files'
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f'Deleted {deleted_count} unused files out of {file_count} total files'
                )
            )