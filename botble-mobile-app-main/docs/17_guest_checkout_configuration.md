# Guest Checkout Configuration

This document explains how to configure the guest checkout feature in the MartFury Flutter app.

## Overview

The guest checkout feature allows customers to proceed to checkout without requiring them to log in first. This can improve conversion rates by reducing friction in the checkout process.

## Configuration

### Environment Variable

Add the following configuration to your `.env` file:

```env
# Guest Checkout Feature
# When true, users can proceed to checkout without logging in
# When false, users must be logged in before accessing checkout
ENABLE_GUEST_CHECKOUT=true
```

### Values

- `true`: Enables guest checkout. Users can proceed to checkout without logging in.
- `false`: Disables guest checkout. Users must log in before accessing the checkout screen.

## Behavior

### When Guest Checkout is Enabled (`ENABLE_GUEST_CHECKOUT=true`)

- Users can click the "Proceed to Checkout" button in the cart screen without being logged in
- The checkout screen will load without requiring authentication
- Both logged-in and guest users can complete their purchases

### When Guest Checkout is Disabled (`ENABLE_GUEST_CHECKOUT=false`)

- If a user is not logged in and clicks "Proceed to Checkout", they will be redirected to the sign-in screen
- Only logged-in users can access the checkout screen
- Users must complete authentication before proceeding with their purchase

## Implementation Details

The feature is implemented in the following files:

- `lib/core/app_config.dart`: Configuration handling
- `lib/src/view/screen/cart_screen.dart`: Authentication check before checkout
- `lib/src/view/screen/checkout_screen.dart`: Optional authentication header handling

## Default Setting

The default value is `true` (guest checkout enabled) to provide the best user experience and reduce checkout friction.

## Testing

To test the feature:

1. Set `ENABLE_GUEST_CHECKOUT=false` in your `.env` file
2. Restart the app
3. Add items to cart without logging in
4. Try to proceed to checkout - you should be redirected to the sign-in screen
5. Set `ENABLE_GUEST_CHECKOUT=true` and restart
6. Try to proceed to checkout - you should go directly to the checkout screen
