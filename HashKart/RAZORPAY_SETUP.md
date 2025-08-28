# Razorpay Payment Integration Setup Guide (India)

This guide will help you set up Razorpay payments in your HashKart e-commerce app, specifically designed for the Indian market.

## Why Razorpay for India?

- **Full India Support**: Native support for all Indian payment methods
- **UPI Integration**: Seamless UPI payments (Google Pay, PhonePe, Paytm, BHIM)
- **Digital Wallets**: Support for Paytm, PhonePe, Amazon Pay, Mobikwik
- **Net Banking**: All major Indian banks supported
- **EMI Options**: Flexible EMI plans for customers
- **Buy Now Pay Later**: Integration with LazyPay, Simpl, ZestMoney
- **Compliance**: Fully compliant with Indian regulations (RBI, NPCI)

## Prerequisites

1. A Razorpay account (sign up at [razorpay.com](https://razorpay.com))
2. Flutter SDK 3.0.0 or higher
3. Business verification documents (GST, PAN, Bank account)
4. Basic understanding of payment processing

## Step 1: Create Razorpay Account

1. Visit [razorpay.com](https://razorpay.com) and click "Get Started"
2. Choose "Business Account" and fill in your business details
3. Complete KYC verification with required documents:
   - PAN Card
   - GST Certificate (if applicable)
   - Bank Account Details
   - Business Address Proof
4. Wait for account activation (usually 24-48 hours)

## Step 2: Get Your API Keys

1. Log in to your [Razorpay Dashboard](https://dashboard.razorpay.com)
2. Navigate to **Settings** → **API Keys**
3. Copy your **Key ID** (starts with `rzp_test_` for testing, `rzp_live_` for production)
4. Copy your **Key Secret** (keep this secure, never expose in client code)

## Step 3: Update Razorpay Configuration

1. Open `lib/core/constants/razorpay_constants.dart`
2. Replace the placeholder keys with your actual Razorpay keys:

```dart
class RazorpayConstants {
  // Test keys (for development)
  static const String keyId = 'rzp_test_your_actual_test_key_id_here';
  static const String keySecret = 'your_test_key_secret_here';
  
  // Live keys (for production) - uncomment when going live
  // static const String keyId = 'rzp_live_your_actual_live_key_id_here';
  // static const String keySecret = 'your_live_key_secret_here';
  
  // ... rest of the constants
}
```

## Step 4: Configure Your Backend (Recommended)

For security reasons, you should process payments through your backend server:

### Backend Implementation Example (Node.js/Express)

```javascript
const express = require('express');
const Razorpay = require('razorpay');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// Create order
app.post('/create-order', async (req, res) => {
  try {
    const { amount, currency, receipt, notes } = req.body;
    
    const order = await razorpay.orders.create({
      amount: Math.round(amount * 100), // Convert to paise
      currency: currency.toUpperCase(),
      receipt: receipt,
      notes: notes,
    });
    
    res.json({
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Verify payment signature
app.post('/verify-payment', async (req, res) => {
  try {
    const { orderId, paymentId, signature } = req.body;
    
    const text = orderId + '|' + paymentId;
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(text.toString())
      .digest('hex');
    
    if (expectedSignature === signature) {
      res.json({ verified: true });
    } else {
      res.status(400).json({ verified: false });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## Step 5: Test Your Integration

### Test Card Numbers

Use these test card numbers for development:

- **Visa**: `4111 1111 1111 1111`
- **Mastercard**: `5555 5555 5555 4444`
- **RuPay**: `6073 8400 0000 0000`
- **American Express**: `3782 8224 6310 005`
- **Declined Card**: `4000 0000 0000 0002`

### Test UPI IDs

- **Google Pay**: `success@razorpay`
- **PhonePe**: `success@razorpay`
- **Paytm**: `success@razorpay`

### Test CVV and Expiry

- **CVV**: Any 3-digit number (e.g., `123`)
- **Expiry**: Any future date (e.g., `12/25`)

## Step 6: Handle Webhooks (Production)

For production, set up webhooks to handle payment events:

1. In your Razorpay Dashboard, go to **Settings** → **Webhooks**
2. Add endpoint: `https://your-domain.com/webhook/razorpay`
3. Select events:
   - `payment.captured`
   - `payment.failed`
   - `order.paid`
   - `refund.processed`

### Webhook Handler Example

```javascript
app.post('/webhook/razorpay', async (req, res) => {
  try {
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    const signature = req.headers['x-razorpay-signature'];
    
    // Verify webhook signature
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(JSON.stringify(req.body))
      .digest('hex');
    
    if (expectedSignature === signature) {
      const event = req.body;
      
      switch (event.event) {
        case 'payment.captured':
          // Handle successful payment
          console.log('Payment captured:', event.payload.payment.entity);
          break;
        case 'payment.failed':
          // Handle failed payment
          console.log('Payment failed:', event.payload.payment.entity);
          break;
        case 'order.paid':
          // Handle order completion
          console.log('Order paid:', event.payload.order.entity);
          break;
      }
      
      res.json({ received: true });
    } else {
      res.status(400).json({ error: 'Invalid signature' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## Step 7: Go Live

When ready for production:

1. Switch from test to live keys in `razorpay_constants.dart`
2. Update your backend to use live keys
3. Complete business verification in Razorpay dashboard
4. Test with real cards in live mode
5. Ensure PCI compliance if handling card data directly

## Indian Payment Methods Supported

### 1. UPI (Unified Payments Interface)
- **Google Pay**
- **PhonePe**
- **Paytm**
- **BHIM**
- **Amazon Pay**
- **ICICI Pockets**
- **HDFC PayZapp**

### 2. Digital Wallets
- **Paytm**
- **PhonePe**
- **Amazon Pay**
- **Mobikwik**
- **Freecharge**
- **Ola Money**
- **Airtel Money**

### 3. Net Banking
- **HDFC Bank**
- **ICICI Bank**
- **State Bank of India**
- **Axis Bank**
- **Kotak Mahindra Bank**
- **Yes Bank**
- **Federal Bank**
- **IDBI Bank**
- **Punjab National Bank**
- **Canara Bank**

### 4. Credit/Debit Cards
- **Visa**
- **Mastercard**
- **RuPay** (India's own network)
- **American Express**
- **Discover**

### 5. EMI Options
- **3 months**
- **6 months**
- **9 months**
- **12 months**
- **18 months**
- **24 months**

### 6. Buy Now Pay Later
- **LazyPay**
- **Simpl**
- **ZestMoney**
- **Cashe**
- **ePayLater**

## Security Best Practices

1. **Never expose secret keys** in client-side code
2. **Use HTTPS** for all payment communications
3. **Verify payment signatures** on your backend
4. **Implement webhooks** for payment confirmation
5. **Log payment events** for audit trails
6. **Use test mode** for development
7. **Implement proper error handling**

## Testing Checklist

- [ ] Test with valid test cards
- [ ] Test with declined cards
- [ ] Test with expired cards
- [ ] Test with invalid CVV
- [ ] Test UPI payments
- [ ] Test wallet payments
- [ ] Test net banking
- [ ] Test EMI options
- [ ] Test error handling
- [ ] Test network failures
- [ ] Test webhook delivery
- [ ] Test signature verification

## Common Issues and Solutions

### Issue: "Invalid key provided"
**Solution**: Check that you're using the correct key type (test vs live) and that the key is properly copied.

### Issue: "Amount must be greater than 0"
**Solution**: Ensure the amount is being passed as a positive number and converted to paise properly.

### Issue: "Currency not supported"
**Solution**: Use 'INR' for Indian Rupee. Other currencies may have limited support.

### Issue: "UPI payment failed"
**Solution**: Ensure the customer has a valid UPI app installed and the UPI ID is correct.

### Issue: "Card declined"
**Solution**: Use test card numbers for development. Real cards may be declined due to various reasons.

## Compliance Requirements

### RBI Guidelines
- Follow RBI guidelines for digital payments
- Implement proper KYC procedures
- Maintain transaction records as per regulations

### NPCI Compliance
- Follow UPI guidelines for UPI payments
- Implement proper security measures
- Use secure communication protocols

### GST Compliance
- Generate proper invoices with GST details
- Maintain GST records as per Indian tax laws

## Support

- [Razorpay Documentation](https://razorpay.com/docs/)
- [Razorpay Support](https://razorpay.com/support/)
- [Razorpay Flutter Plugin](https://pub.dev/packages/razorpay_flutter)
- [Razorpay Developer Community](https://razorpay.com/developers/)

## Next Steps

1. Implement your backend payment processing
2. Add payment analytics and reporting
3. Implement subscription billing if needed
4. Add support for additional payment methods
5. Implement fraud detection measures
6. Add support for international payments
7. Implement recurring payments
8. Add support for bulk payments

## Cost Structure

- **Setup Fee**: ₹0 (Free)
- **Transaction Fee**: 2% + ₹3 per transaction
- **International Cards**: 3% + ₹3 per transaction
- **UPI**: 0.5% + ₹2 per transaction
- **Net Banking**: 1.5% + ₹2 per transaction
- **Wallets**: 1.5% + ₹2 per transaction

*Note: Fees may vary based on your business category and transaction volume.*
