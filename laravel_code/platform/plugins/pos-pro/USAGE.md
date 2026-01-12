# POS Pro - Usage Guide

## Introduction

POS Pro is a comprehensive Point of Sale system designed for Botble E-commerce stores. It provides a user-friendly interface for managing in-store sales, processing orders, and handling customer transactions efficiently. This document will guide you through the setup and usage of the POS Pro plugin.

## Requirements

Before using POS Pro, ensure your system meets the following requirements:

- Botble CMS version 7.5.0 or higher
- PHP version 8.2 or higher
- Active E-commerce plugin

## Installation

1. Download the plugin from [CodeCanyon downloads page](https://codecanyon.net/downloads)
2. Extract the downloaded zip file
3. Upload the extracted folder to `platform/plugins/pos-pro` directory
4. Go to **Admin** > **Plugins** and activate the POS Pro plugin
5. Refresh your website

After installation, you can access the POS system from the main menu in your admin panel.

## Configuration

### Accessing POS Settings

1. Log in to your admin panel
2. Navigate to **Settings** > **E-commerce** > **POS Settings**
3. Configure the following options:

### Available Settings

- **Enable POS**: Turn the POS system on or off
- **Active Payment Methods**: Select which payment methods are available in the POS interface (Cash, Card, Other)
- **Default Payment Method**: Set the default payment method for POS transactions
- **Auto Apply Discount**: Automatically apply discounts to products when added to cart
- **Auto Add Shipping**: Automatically add shipping cost to orders
- **Default Shipping Amount**: Set the default shipping amount for POS orders
- **Remember Customer Selection**: Remember the last selected customer for new orders
- **Print Receipt After Checkout**: Automatically open print dialog after successful checkout

## Using the POS System

### Accessing the POS Interface

1. Log in to your admin panel
2. Click on the "POS" menu item in the main navigation
3. The POS interface will load with products on the left and cart on the right

### Interface Overview

The POS interface is divided into two main sections:
- **Left Side**: Product catalog with search functionality
- **Right Side**: Shopping cart and checkout options

### Product Management

#### Browsing Products

1. Products are displayed in a grid layout with images, prices, and stock information
2. Scroll down to load more products (infinite scrolling)
3. Use the search bar to find products by name, SKU, or barcode

#### Adding Products to Cart

1. For simple products, click the "Add to Cart" button
2. For products with variations (like size, color, etc.):
   - Click the "Select Options" button
   - Choose the desired attributes in the popup modal
   - Set the quantity
   - Click "Add to Cart"

### Cart Management

#### Viewing the Cart

The cart displays:
- Product name and image
- Unit price
- Quantity
- Subtotal for each item
- Cart total with tax and shipping

#### Modifying Cart Items

1. **Adjust Quantity**: Use the +/- buttons next to each product
2. **Remove Item**: Click the trash icon next to the product
3. **Clear Cart**: Click the "Clear Cart" button to remove all items

#### Applying Discounts and Coupons

1. **Apply Coupon**:
   - Click "Have a coupon?"
   - Enter the coupon code
   - Click "Apply"

2. **Add Manual Discount**:
   - Click the discount icon
   - Enter discount amount or percentage
   - Click "Apply Discount"

#### Setting Shipping

1. Click the shipping icon
2. Enter shipping amount
3. Click "Update Shipping"

### Customer Management

#### Selecting a Customer

1. Use the customer dropdown to select an existing customer
2. Or click "Create Customer" to add a new one

#### Creating a New Customer

1. Click "Create Customer"
2. Fill in the required information:
   - Name
   - Email
   - Phone
   - Address (optional)
3. Click "Save"

#### Managing Customer Addresses

1. Select a customer
2. Choose from their existing addresses or enter a new one
3. The selected address will be used for the order

### Checkout Process

1. Add products to the cart
2. Select a customer (or create a new one)
3. Choose a payment method (Cash, Card, Other)
4. Add any order notes if needed
5. Review the order summary
6. Click "Complete Order"

### After Checkout

After completing an order:
1. A success message will appear with the order number
2. You can print the receipt by clicking "Print Receipt"
3. Start a new order by clicking "New Order"

### Printing Receipts

The receipt includes:
- Store information
- Order number and date
- Customer details
- List of purchased items with quantities and prices
- Payment information
- Subtotal, tax, shipping, and total amount

## Additional Features

### Full Screen Mode

1. Click the "Fullscreen" button in the top navigation bar
2. The POS interface will expand to fill the entire screen
3. Press "Exit Fullscreen" to return to normal view

### Language Switching

If your store supports multiple languages:
1. Click the language icon in the top navigation
2. Select your preferred language
3. The interface will update to display text in the selected language

## Barcode Scanner

### Overview

The POS Pro plugin includes a built-in barcode scanner feature that allows you to quickly search for products by scanning their barcodes. This feature supports both camera-based scanning (using your device's camera) and hardware barcode scanners (USB or Bluetooth).

### Features

- **Camera-based scanning**: Use your device's camera to scan barcodes
- **Hardware scanner support**: Compatible with USB and Bluetooth barcode scanners
- **Multiple barcode formats**: Supports common formats including UPC, EAN, Code 128, Code 39, QR codes, and more
- **Instant search**: Automatically searches for products when a barcode is detected
- **Fallback options**: Manual entry option when scanning isn't available

### Requirements

- **For camera scanning**:
  - A device with a camera (laptop, tablet, or desktop with webcam)
  - A modern browser (Chrome, Firefox, Safari, or Edge)
  - Camera permissions granted to the website

- **For hardware scanning**:
  - A compatible USB or Bluetooth barcode scanner
  - Proper drivers installed (if required by your scanner)

### How It Works

#### Camera-Based Scanning

The camera-based scanner uses the [ZXing ("Zebra Crossing")](https://github.com/zxing/zxing) library to detect and decode barcodes in real-time from your device's camera feed. When a barcode is detected, the system automatically searches for the corresponding product in your inventory.

#### Hardware Scanner Support

The system also supports hardware barcode scanners that function as keyboard emulators (most common type). These scanners "type" the barcode as if it were entered from a keyboard, followed by an Enter key press. The system detects this pattern and processes it as a barcode scan.

### Using the Barcode Scanner

#### Accessing the Scanner

1. Navigate to the POS screen in your admin panel
2. Look for the barcode scanner icon (![barcode icon](https://tabler-icons.io/static/tabler-icons/icons/barcode.svg)) next to the search box
3. Click the icon to activate the scanner

#### Camera-Based Scanning

When you click the barcode scanner icon for the first time:

1. Your browser will ask for permission to access your camera
2. Grant permission to allow the scanner to work
3. A camera view will appear showing what your camera sees
4. Position the barcode within the scanning guide (dashed box)
5. Hold the barcode steady until it's detected
6. Once detected, the system will automatically search for the product

**Tips for successful scanning:**

- Ensure good lighting conditions
- Hold the barcode steady
- Position the barcode within the scanning guide
- Make sure the barcode is clearly visible and not damaged
- Try different distances if scanning fails

#### Using a Hardware Scanner

If you have a hardware barcode scanner:

1. Make sure it's properly connected to your device
2. Focus on any input field on the page (or click anywhere on the page)
3. Scan the barcode with your hardware scanner
4. The system will automatically detect the scan and search for the product

#### Manual Entry

If scanning isn't working:

1. Click the barcode scanner icon
2. If camera access fails or no camera is available, a manual entry field will appear
3. Type the barcode number manually
4. Press Enter or click "Search" to find the product

### Troubleshooting

#### Camera Access Issues

If your browser cannot access your camera:

1. Check that your device has a working camera
2. Ensure you've granted camera permissions to the website
   - Look for the camera icon in your browser's address bar
   - Click it and select "Allow" if it's currently blocked
3. Try using a different browser
4. Restart your browser or device

#### Scanner Not Detecting Barcodes

If the scanner is not detecting barcodes:

1. Ensure there's adequate lighting
2. Try adjusting the distance between the barcode and camera
3. Make sure the barcode is not damaged or obscured
4. Position the barcode within the scanning guide
5. Hold the device steady while scanning
6. Try cleaning your camera lens if it appears blurry

#### Hardware Scanner Issues

If your hardware scanner isn't working:

1. Ensure it's properly connected and powered on
2. Check that the scanner is configured in keyboard emulation mode
3. Test the scanner in a text editor to verify it's working correctly
4. Make sure the scanner is configured to send an Enter key after scanning

### Supported Barcode Formats

The camera-based scanner supports the following formats:

- **1D Product**: UPC-A, UPC-E, EAN-8, EAN-13
- **1D Industrial**: Code 39, Code 93, Code 128, Codabar, ITF
- **2D**: QR Code, Data Matrix, Aztec, PDF 417

Hardware scanners typically support a similar range of formats, depending on the specific model.

### Privacy and Security

- Camera access is only requested when you explicitly click the barcode scanner button
- Camera access is not persistent between sessions (you'll need to grant permission each time)
- No images from your camera are stored or transmitted
- All barcode processing happens locally in your browser

### Technical Details

The barcode scanner implementation uses:

- The ZXing library for barcode detection and decoding
- The MediaDevices API for accessing the camera
- JavaScript event handling for hardware scanner support

### Limitations

- Camera-based scanning requires good lighting conditions
- Some very small or damaged barcodes may be difficult to scan
- Performance may vary depending on your device's camera quality
- Some older browsers may not support the required APIs

## Permissions

POS Pro includes the following permissions that can be assigned to user roles:

- **POS**: Access to the POS system
- **Create**: Ability to create orders through POS
- **Edit**: Ability to edit POS settings
- **Delete**: Ability to delete POS-related data
- **Settings**: Access to POS settings

To manage permissions:
1. Go to **Users** > **Roles**
2. Edit a role
3. Find the POS section in permissions
4. Check/uncheck permissions as needed
5. Save changes

## Troubleshooting

### Common Issues

1. **Products not showing up**:
   - Ensure products are published and have stock
   - Check if product search is working correctly

2. **Payment methods not available**:
   - Verify that payment methods are enabled in POS Settings

3. **Cannot complete checkout**:
   - Check if all required fields are filled
   - Ensure the selected payment method is active

### Getting Support

If you encounter any issues or have questions about the POS Pro plugin, please contact support:

- **Documentation**: [https://docs.botble.com/pos-pro](https://docs.botble.com/pos-pro)
- **Support Email**: [support@botble.com](mailto:support@botble.com)
- **Support Forum**: [https://botble.com/forum](https://botble.com/forum)

## Changelog

### Version 1.1.0
- Added barcode scanner functionality with camera and hardware scanner support
- Added dark mode support for reduced eye strain
- Added in-app language switcher for quick language changes
- Added full screen mode for distraction-free operation
- Improved UI/UX for better user experience
- Various bug fixes and performance improvements

### Version 1.0.0
- Initial release
- Core POS functionality
- Integration with Botble E-commerce
- Multi-language support
- Receipt generation
