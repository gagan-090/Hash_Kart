class RazorpayConstants {
  // Replace these with your actual Razorpay keys
  // Get these from your Razorpay Dashboard: https://dashboard.razorpay.com/settings/keys
  
  // Test keys (for development)
  static const String keyId = 'rzp_test_R7xVvdyoHrXAT3';
  static const String keySecret = '0N4ChYZnK7BAn3j4eyi7vyfw';
  
  // Live keys (for production) - uncomment when going live
  // static const String keyId = 'rzp_live_your_live_key_id_here';
  // static const String keySecret = 'your_live_key_secret_here';
  
  // App configuration
  static const String appName = 'HashKart';
  static const String appDescription = 'Multi-Vendor E-Commerce';
  
  // Default currency (INR for India)
  static const String defaultCurrency = 'INR';
  
  // Supported currencies for India
  static const List<String> supportedCurrencies = [
    'INR', // Indian Rupee
    'USD', // US Dollar (if needed)
    'EUR', // Euro (if needed)
  ];
  
  // Payment method preferences (India-specific)
  static const List<String> preferredPaymentMethods = [
    'upi',        // UPI (most popular in India)
    'cards',      // Credit/Debit cards
    'netbanking', // Net banking
    'wallet',     // Digital wallets
    'emi',        // EMI options
    'paylater',   // Buy now pay later
  ];
  
  // UPI apps (popular in India)
  static const List<String> upiApps = [
    'google_pay',
    'phonepe',
    'paytm',
    'bhim',
    'amazon_pay',
    'icici_pockets',
    'hdfc_payzapp',
  ];
  
  // Digital wallets (popular in India)
  static const List<String> digitalWallets = [
    'paytm',
    'phonepe',
    'amazon_pay',
    'mobikwik',
    'freecharge',
    'ola_money',
    'airtel_money',
  ];
  
  // Major banks for net banking
  static const List<String> majorBanks = [
    'HDFC',
    'ICICI',
    'SBI',
    'Axis',
    'Kotak',
    'Yes Bank',
    'Federal Bank',
    'IDBI',
    'PNB',
    'Canara Bank',
    'Bank of Baroda',
    'Union Bank',
    'Bank of India',
    'Central Bank',
    'Indian Bank',
  ];
  
  // Card networks supported in India
  static const List<String> cardNetworks = [
    'visa',
    'mastercard',
    'rupay',      // India's own card network
    'amex',
    'discover',
  ];
  
  // EMI options
  static const List<String> emiOptions = [
    '3_months',
    '6_months',
    '9_months',
    '12_months',
    '18_months',
    '24_months',
  ];
  
  // Buy now pay later options
  static const List<String> payLaterOptions = [
    'lazy_pay',
    'simpl',
    'zest_money',
    'cashe',
    'epay_later',
  ];
  
  // Payment timeout (in seconds)
  static const int paymentTimeout = 180; // 3 minutes
  
  // Theme colors
  static const String primaryColor = '#3399cc';
  static const String accentColor = '#ff6b35';
  static const String backgroundColor = '#ffffff';
  
  // Error messages (localized for India)
  static const Map<String, String> errorMessages = {
    'payment_failed': 'Payment failed. Please try again.',
    'network_error': 'Network error. Please check your internet connection.',
    'invalid_amount': 'Invalid amount. Please enter a valid amount.',
    'card_declined': 'Card declined. Please try another card.',
    'insufficient_balance': 'Insufficient balance in your account.',
    'upi_error': 'UPI payment failed. Please try again.',
    'wallet_error': 'Wallet payment failed. Please try again.',
    'netbanking_error': 'Net banking failed. Please try again.',
  };
  
  // Success messages
  static const Map<String, String> successMessages = {
    'payment_success': 'Payment successful! Your order has been confirmed.',
    'upi_success': 'UPI payment successful!',
    'card_success': 'Card payment successful!',
    'wallet_success': 'Wallet payment successful!',
    'netbanking_success': 'Net banking payment successful!',
  };
}
