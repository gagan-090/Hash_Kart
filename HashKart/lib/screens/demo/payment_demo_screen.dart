// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/cart_provider.dart';
// import '../../core/models/product.dart';
// import '../../widgets/payment/indian_payment_form.dart';
// import '../../core/services/razorpay_payment_service.dart';
// // ... existing code ...
// import '../../providers/cart_provider.dart';
// import '../../models/product_model.dart';  // Changed from core/models/product.dart
// import '../../widgets/payment/indian_payment_form.dart';
// // ... existing code ...
// class PaymentDemoScreen extends StatefulWidget {
//   const PaymentDemoScreen({super.key});

//   @override
//   State<PaymentDemoScreen> createState() => _PaymentDemoScreenState();
// }

// class _PaymentDemoScreenState extends State<PaymentDemoScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Add some demo products to cart
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _addDemoProducts();
//     });
//   }

//   void _addDemoProducts() {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
//     // Add demo products
//     final demoProducts = [
//       Product(
//         id: '1',
//         name: 'iPhone 15 Pro',
//         description: 'Latest iPhone with advanced features',
//         price: 149999.0,
//         imageUrl: 'https://via.placeholder.com/150x150?text=iPhone',
//         category: 'Electronics',
//         vendorId: 'vendor1',
//       ),
//       Product(
//         id: '2',
//         name: 'Samsung Galaxy S24',
//         description: 'Premium Android smartphone',
//         price: 89999.0,
//         imageUrl: 'https://via.placeholder.com/150x150?text=Samsung',
//         category: 'Electronics',
//         vendorId: 'vendor2',
//       ),
//       Product(
//         id: '3',
//         name: 'MacBook Air M2',
//         description: 'Powerful laptop for professionals',
//         price: 119999.0,
//         imageUrl: 'https://via.placeholder.com/150x150?text=MacBook',
//         category: 'Electronics',
//         vendorId: 'vendor3',
//       ),
//     ];

//     for (final product in demoProducts) {
//       cartProvider.addToCart(product, quantity: 1);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Payment Demo'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//       ),
//       body: Consumer<CartProvider>(
//         builder: (context, cartProvider, child) {
//           if (cartProvider.cartItems.isEmpty) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           final subtotal = cartProvider.subtotal;
//           final tax = subtotal * 0.18; // 18% GST
//           final deliveryCharge = 50.0;
//           final total = subtotal + tax + deliveryCharge;

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Demo Info
//                 Card(
//                   color: Colors.blue.shade50,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.info, color: Colors.blue.shade700),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Payment Demo',
//                               style: TextStyle(
//                                 color: Colors.blue.shade700,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'This is a demo of the complete payment flow. Add items to cart, proceed to checkout, and test Razorpay integration.',
//                           style: TextStyle(color: Colors.blue.shade700),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Cart Summary
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Cart Summary',
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
                        
//                         // Items
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text('Items (${cartProvider.cartItems.length})'),
//                             Text('₹${subtotal.toStringAsFixed(2)}'),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
                        
//                         // Tax
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text('GST (18%)'),
//                             Text('₹${tax.toStringAsFixed(2)}'),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
                        
//                         // Delivery
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text('Delivery Charge'),
//                             Text('₹${deliveryCharge.toStringAsFixed(2)}'),
//                           ],
//                         ),
//                         const Divider(),
                        
//                         // Total
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Total',
//                               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               '₹${total.toStringAsFixed(2)}',
//                               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).primaryColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Payment Form
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Payment Details',
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
                        
//                         IndianPaymentForm(
//                           amount: total,
//                           currency: 'INR',
//                           customerEmail: 'demo@hashkart.com',
//                           customerPhone: '+919876543210',
//                           customerName: 'Demo User',
//                           orderId: 'DEMO${DateTime.now().millisecondsSinceEpoch}',
//                           onPaymentComplete: (result) {
//                             _handlePaymentComplete(result);
//                           },
//                           notes: {
//                             'source': 'demo_app',
//                             'cart_items_count': cartProvider.cartItems.length.toString(),
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Test Instructions
//                 Card(
//                   color: Colors.orange.shade50,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.lightbulb, color: Colors.orange.shade700),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Test Instructions',
//                               style: TextStyle(
//                                 color: Colors.orange.shade700,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           '• Use test card numbers: 4111 1111 1111 1111\n'
//                           '• CVV: Any 3 digits (e.g., 123)\n'
//                           '• Expiry: Any future date (e.g., 12/25)\n'
//                           '• UPI: success@razorpay',
//                           style: TextStyle(color: Colors.orange.shade700),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _handlePaymentComplete(PaymentResult result) {
//     if (result.success) {
//       // Show success dialog
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Payment Successful! 🎉'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Your payment has been processed successfully.'),
//               if (result.transactionId != null) ...[
//                 const SizedBox(height: 8),
//                 Text('Transaction ID: ${result.transactionId}'),
//               ],
//               const SizedBox(height: 8),
//               const Text('This completes the payment demo flow.'),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // Clear cart after successful payment
//                 Provider.of<CartProvider>(context, listen: false).clearCart();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     } else {
//       // Show error dialog
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Payment Failed'),
//           content: Text(result.message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     }
//   }
// }
