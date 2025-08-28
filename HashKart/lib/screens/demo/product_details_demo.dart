import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../product/ProductDetailsScreen.dart';

class ProductDetailsDemo extends StatelessWidget {
  const ProductDetailsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Product Details Screen Demo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This demo showcases the hyper-realistic, modern product details screen with all the requested features.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Demo Product Cards
          _buildDemoProductCard(
            context,
            'Premium Smartphone',
            'Latest flagship smartphone with advanced features',
            29999.0,
            34999.0,
            4.5,
            1250,
            'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
          ),

          const SizedBox(height: 16),

          _buildDemoProductCard(
            context,
            'Wireless Headphones',
            'Premium noise-cancelling wireless headphones',
            8999.0,
            12999.0,
            4.3,
            890,
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
          ),

          const SizedBox(height: 16),

          _buildDemoProductCard(
            context,
            'Smart Watch',
            'Advanced fitness tracking smartwatch',
            15999.0,
            19999.0,
            4.7,
            2100,
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
          ),
        ],
      ),
    );
  }

  Widget _buildDemoProductCard(
    BuildContext context,
    String name,
    String description,
    double price,
    double originalPrice,
    double rating,
    int reviews,
    String imageUrl,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text('$rating ($reviews reviews)'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                product: _createDemoProduct(
                  name,
                  description,
                  price,
                  originalPrice,
                  rating,
                  reviews,
                  imageUrl,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Product _createDemoProduct(
    String name,
    String description,
    double price,
    double originalPrice,
    double rating,
    int reviews,
    String imageUrl,
  ) {
    // Create different specifications based on product type
    Map<String, dynamic> specs = _getSpecificationsForProduct(name);
    return Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vendorId: 'demo_vendor',
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      description: '''$description

This is a comprehensive product description that showcases the expandable text feature. The product comes with premium build quality and advanced features that make it stand out in the market.

Key Features:
• Premium materials and construction
• Advanced technology integration
• User-friendly interface
• Long-lasting durability
• Excellent customer support

The product has been designed with attention to detail and incorporates the latest innovations in the industry. Whether you're a professional or casual user, this product delivers exceptional performance and reliability.

Technical specifications include state-of-the-art components that ensure optimal functionality. The design philosophy focuses on both aesthetics and practicality, making it a perfect choice for modern consumers.

Customer satisfaction is our top priority, and this product comes with comprehensive warranty coverage and dedicated support services.''',
      price: price,
      comparePrice: originalPrice,
      averageRating: rating,
      reviewCount: reviews,
      stockQuantity: 50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      images: [
        ProductImage(
          id: '1',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          image: imageUrl,
          isPrimary: true,
          createdAt: DateTime.now(),
        ),
        ProductImage(
          id: '2',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          image:
              'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
          createdAt: DateTime.now(),
        ),
        ProductImage(
          id: '3',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          image:
              'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
          createdAt: DateTime.now(),
        ),
      ],
      variations: [
        ProductVariation(
          id: 'var1',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          price: price,
          comparePrice: originalPrice,
          stockQuantity: 25,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attributes: {'Color': 'Black', 'Storage': '128GB'},
        ),
        ProductVariation(
          id: 'var2',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          price: price + 2000,
          comparePrice: originalPrice + 2000,
          stockQuantity: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attributes: {'Color': 'Blue', 'Storage': '256GB'},
        ),
        ProductVariation(
          id: 'var3',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          price: price + 4000,
          comparePrice: originalPrice + 4000,
          stockQuantity: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attributes: {'Color': 'White', 'Storage': '512GB'},
        ),
      ],
      reviews: [
        ProductReview(
          id: 'rev1',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'user1',
          rating: 5,
          title: 'Excellent Product!',
          comment:
              'This product exceeded my expectations. The build quality is outstanding and the features work flawlessly. Highly recommended!',
          isVerifiedPurchase: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          userFirstName: 'John',
          userLastName: 'Doe',
        ),
        ProductReview(
          id: 'rev2',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'user2',
          rating: 4,
          title: 'Great value for money',
          comment:
              'Good product with nice features. The delivery was fast and packaging was excellent. Minor issues with setup but overall satisfied.',
          isVerifiedPurchase: true,
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          updatedAt: DateTime.now().subtract(const Duration(days: 12)),
          userFirstName: 'Sarah',
          userLastName: 'Smith',
        ),
        ProductReview(
          id: 'rev3',
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'user3',
          rating: 5,
          title: 'Perfect!',
          comment:
              'Exactly what I was looking for. The quality is top-notch and the customer service was very helpful.',
          isVerifiedPurchase: false,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
          userFirstName: 'Mike',
          userLastName: 'Johnson',
        ),
      ],
      specifications: specs,
      brand: Brand(
        id: 'brand1',
        name: name.split(' ').first,
        slug: name.split(' ').first.toLowerCase(),
        description: 'Premium brand known for quality products',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      category: Category(
        id: 'cat1',
        name: 'Electronics',
        slug: 'electronics',
        description: 'Electronic devices and accessories',
        productCount: 150,
        isActive: true,
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> _getSpecificationsForProduct(String productName) {
    if (productName.toLowerCase().contains('smartphone')) {
      return {
        'Brand': 'Samsung',
        'Model': 'Galaxy S24 Ultra',
        'Display': '6.8-inch Dynamic AMOLED 2X',
        'Resolution': '3120 x 1440 pixels',
        'Processor': 'Snapdragon 8 Gen 3',
        'RAM': '12GB LPDDR5X',
        'Storage': '256GB UFS 4.0',
        'Camera': '200MP Main + 50MP Telephoto + 12MP Ultra-wide',
        'Front Camera': '12MP',
        'Battery': '5000mAh with 45W Fast Charging',
        'Operating System': 'Android 14 with One UI 6.1',
        'Connectivity': '5G, WiFi 7, Bluetooth 5.3',
        'Water Resistance': 'IP68',
        'Weight': '232g',
        'Dimensions': '162.3 x 79.0 x 8.6 mm',
        'Colors': 'Titanium Black, Titanium Gray, Titanium Violet',
        'Warranty': '1 Year Manufacturer Warranty',
      };
    } else if (productName.toLowerCase().contains('headphones')) {
      return {
        'Brand': 'Sony',
        'Model': 'WH-1000XM5',
        'Type': 'Over-Ear Wireless Headphones',
        'Driver Size': '30mm',
        'Frequency Response': '4Hz - 40kHz',
        'Impedance': '48 ohms',
        'Noise Cancellation': 'Industry-leading Active Noise Cancellation',
        'Battery Life': 'Up to 30 hours with ANC off, 20 hours with ANC on',
        'Charging': 'USB-C Quick Charge (3 min = 3 hours playback)',
        'Connectivity': 'Bluetooth 5.2, NFC, 3.5mm jack',
        'Codecs': 'SBC, AAC, LDAC',
        'Weight': '250g',
        'Controls': 'Touch controls on right ear cup',
        'Microphone': 'Built-in for calls and voice assistant',
        'Colors': 'Black, Silver',
        'Warranty': '1 Year International Warranty',
      };
    } else if (productName.toLowerCase().contains('watch')) {
      return {
        'Brand': 'Apple',
        'Model': 'Apple Watch Series 9',
        'Display': '1.9-inch Retina LTPO OLED',
        'Resolution': '484 x 396 pixels',
        'Processor': 'S9 SiP with 64-bit dual-core processor',
        'Storage': '64GB',
        'Sensors': 'ECG, Blood Oxygen, Heart Rate, Accelerometer, Gyroscope',
        'Connectivity': 'WiFi, Bluetooth 5.3, GPS, Cellular (optional)',
        'Water Resistance': 'WR50 (50 meters)',
        'Battery Life': 'Up to 18 hours',
        'Charging': 'Magnetic charging cable',
        'Operating System': 'watchOS 10',
        'Case Material': 'Aluminum, Stainless Steel, Titanium',
        'Band Options': 'Sport Band, Sport Loop, Leather, Milanese Loop',
        'Sizes': '41mm, 45mm',
        'Colors': 'Multiple color options',
        'Warranty': '1 Year Limited Warranty',
      };
    } else {
      return {
        'Brand': productName.split(' ').first,
        'Model': productName,
        'Color Options': 'Multiple colors available',
        'Warranty': '1 Year Manufacturer Warranty',
        'Weight': 'Lightweight design',
        'Material': 'Premium quality materials',
        'Connectivity': 'Latest connectivity options',
        'Battery Life': 'Long-lasting battery',
        'Water Resistance': 'Water-resistant design',
        'Operating System': 'Latest software version',
        'Storage': 'Ample storage capacity',
        'Display': 'High-quality display',
        'Processor': 'High-performance processor',
      };
    }
  }
}
