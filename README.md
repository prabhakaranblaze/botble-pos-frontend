# StampSmart POS Desktop Application

A professional Point of Sale (POS) desktop application built with Flutter for Windows, with offline support and seamless API integration.

## Features

### ✨ Core Features
- **User Authentication** - Secure login with email/password
- **Cash Register Management** - Multi-register support with session tracking
- **Session Management** - Open/close sessions with denomination counting
- **Product Management** - Browse, search, and manage products
- **Barcode Scanning** - Quick product lookup with audio feedback
- **Cart Management** - Add, update, remove items with real-time calculations
- **Customer Management** - Select or create customers
- **Payment Processing** - Cash and card payment support with denomination entry
- **Receipt Generation** - Print receipts with PDF generation
- **Offline Support** - Continue working offline with automatic sync
- **Real-time Connectivity** - Visual indicators for online/offline status

### 📊 Additional Features
- **Reports Dashboard** - View sales, sessions, and financial reports
- **Short/Excess Tracking** - Monitor cash discrepancies
- **Multi-currency Support** - USD and INR denominations
- **Responsive UI** - 70/30 split layout (products/cart)
- **Audio Feedback** - Beep sounds for barcode scanning

## Prerequisites

1. **Flutter SDK** (3.0+)
   - Download from: https://docs.flutter.dev/get-started/install/windows
   - Add Flutter to your PATH

2. **Visual Studio 2022** (for Windows desktop development)
   - Download from: https://visualstudio.microsoft.com/downloads/
   - Install "Desktop development with C++" workload

3. **Git** (for version control)
   - Download from: https://git-scm.com/downloads

## Installation

### 1. Clone or Copy the Project

```bash
# If using git
git clone <your-repo-url>
cd pos_desktop

# Or simply copy the pos_desktop folder to your desired location
```

### 2. Configure API Settings

Open `lib/shared/constants/app_constants.dart` and update:

```dart
static const String baseUrl = 'http://localhost/api/v1/pos'; // Your API URL
static const String apiKey = 'YOUR_API_KEY_HERE'; // Your API key
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Enable Windows Desktop Support

```bash
flutter config --enable-windows-desktop
```

### 5. Run the Application

```bash
# Development mode
flutter run -d windows

# Release mode (faster)
flutter run -d windows --release
```

### 6. Build Executable

```bash
# Build Windows executable
flutter build windows --release

# The executable will be in: build/windows/runner/Release/
```

## Project Structure

```
pos_desktop/
├── lib/
│   ├── core/
│   │   ├── api/              # API service with offline support
│   │   ├── database/         # Local SQLite database
│   │   ├── models/           # Data models
│   │   └── services/         # Storage, audio, connectivity services
│   ├── features/
│   │   ├── auth/             # Login & authentication
│   │   ├── dashboard/        # Main navigation
│   │   ├── sales/            # POS interface, cart, payment
│   │   ├── session/          # Session management
│   │   └── reports/          # Reports dashboard
│   ├── shared/
│   │   ├── constants/        # App constants & colors
│   │   └── widgets/          # Reusable widgets
│   └── main.dart             # Entry point
├── assets/
│   ├── sounds/               # Audio files for feedback
│   └── images/               # App images
├── pubspec.yaml              # Dependencies
└── README.md
```

## Configuration

### API Endpoints

The app connects to these API endpoints:

- **Auth**: `/auth/login`, `/auth/me`, `/auth/logout`
- **Products**: `/products`, `/products/scan-barcode`, `/products/categories`
- **Cart**: `/cart/add`, `/cart/update`, `/cart/remove`, `/cart/clear`
- **Orders**: `/orders` (checkout), `/orders/{id}/receipt`
- **Cash Registers**: `/cash-registers`
- **Sessions**: `/sessions/open`, `/sessions/close`, `/sessions/active`
- **Denominations**: `/denominations`

### Default Login Credentials

```
Email: admin@example.com
Password: 12345678
```

## Usage Guide

### 1. Login
- Launch the application
- Enter your email and password
- Click "Sign In"

### 2. Select Cash Register
- After login, select your cash register
- Click on the register card to proceed

### 3. Open Session
- Enter opening cash amount
- Optionally count denominations
- Add notes if needed
- Click "Open Session"

### 4. Make Sales
- **Scan Barcode**: Type or scan barcode in the top-left input field
- **Search Products**: Use the search bar to find products
- **Add to Cart**: Click on product cards to add them
- **Adjust Quantity**: Use +/- buttons in the cart
- **Select Customer**: (Optional) Search and select a customer

### 5. Checkout
- Click "Checkout" button
- Select payment method (Cash or Card)
- **For Cash**: Enter amount received, view change
- **For Card**: Enter last 4 digits of card
- Click "Complete Payment"
- View/print receipt

### 6. Close Session
- Go to "Session" tab
- Click "Close Session"
- Enter closing cash amount
- Optionally count denominations
- Add notes if needed
- Click "Close Session"

### 7. Logout
- Close active session first
- Click logout icon at bottom of left menu

## Offline Mode

The app automatically switches to offline mode when internet is unavailable:

- Yellow banner appears at the top
- Products are loaded from local database
- Orders are queued for sync
- All data syncs automatically when back online

## Barcode Scanning

1. Keep the barcode scanner input focused (top-left)
2. Scan or type the barcode
3. Press Enter
4. Product is added to cart with a beep sound
5. If product not found, error sound plays

## Troubleshooting

### App Won't Start
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d windows
```

### Database Issues
```bash
# Delete database and restart
# Database location: %USERPROFILE%\Documents\StampSmartPOS\pos_local.db
```

### API Connection Errors
- Check `app_constants.dart` for correct API URL
- Verify API key is set correctly
- Ensure your Laravel API is running
- Check network connectivity

### Build Errors
```bash
# Update Flutter
flutter upgrade

# Get latest dependencies
flutter pub upgrade

# Rebuild
flutter build windows --release
```

## Sound Files (Optional)

Add these files to `assets/sounds/` for audio feedback:
- `beep.mp3` - Barcode scan success
- `error.mp3` - Error sound
- `success.mp3` - Checkout success

If sound files are missing, the app will continue to work without audio feedback.

## Development

### Adding New Features
1. Create feature folder in `lib/features/`
2. Add provider in feature folder
3. Register provider in `main.dart`
4. Add routes/navigation as needed

### Updating Models
1. Modify model in `lib/core/models/`
2. Update database schema if needed
3. Update API service methods
4. Test offline sync

## Performance Tips

1. **Use Release Mode** for production:
   ```bash
   flutter build windows --release
   ```

2. **Optimize Images**: Use compressed images for faster loading

3. **Limit Product Grid**: Pagination helps with large catalogs

4. **Regular Sync**: Close and reopen app daily to sync data

## Security

- Tokens are stored securely in encrypted storage
- API key should be kept secret
- Use HTTPS for API connections in production
- Implement proper access controls on the backend

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter documentation: https://docs.flutter.dev
3. Check API logs in your Laravel application

## License

This project is proprietary software for StampSmart POS.

## Version History

### v1.0.0 (Current)
- Initial release
- Full POS functionality
- Offline support
- Session management
- Receipt printing
- Multi-currency support
