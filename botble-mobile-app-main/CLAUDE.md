# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MartFury is a Flutter e-commerce mobile application designed to work with Botble E-commerce backend. It provides a complete e-commerce experience with multi-language support, social authentication, and modern UI.

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the application
flutter run

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk --release     # Android
flutter build ios --release     # iOS

# Generate launcher icons after changing assets/launcher_icon.png
flutter pub run flutter_launcher_icons
```

## Architecture Overview

The project follows Clean Architecture with GetX for state management:

### Directory Structure
- `/lib/core/`: Core configuration including `app_config.dart` for API endpoints and feature flags
- `/lib/src/controller/`: GetX controllers containing business logic
- `/lib/src/model/`: Data models (User, Product, Order, Cart, etc.)
- `/lib/src/service/`: API services layer
  - `base_service.dart`: Base API communication with error handling
  - Domain-specific services: `auth_service.dart`, `product_service.dart`, `order_service.dart`, etc.
- `/lib/src/view/screen/`: UI screens organized by feature
- `/lib/src/view/widget/`: Reusable UI components
- `/lib/src/theme/`: App theming (colors, fonts, styles)
- `/lib/src/utils/`: Utility classes and helpers

### Key Architectural Patterns

1. **State Management**: GetX is used throughout for:
   - Reactive state management (.obs variables)
   - Dependency injection (Get.put, Get.find)
   - Navigation (Get.to, Get.back)

2. **API Communication**: 
   - All API calls go through `BaseService` in `/lib/src/service/base_service.dart`
   - Services return typed models from `/lib/src/model/`
   - Error handling is centralized with maintenance mode support

3. **Localization**:
   - Translations in `/assets/translations/` (en, it, ja, th, vi, zh)
   - Use `'key'.tr` for translated strings
   - Supports RTL languages

4. **Environment Configuration**:
   - Uses `.env` file for API endpoints and feature flags
   - Access via `dotenv.env['KEY_NAME']`

## Key Features and Their Implementation

- **Authentication**: Multiple providers in `/lib/src/controller/auth_controller.dart`
- **Shopping Cart**: Cart management in `/lib/src/controller/cart_controller.dart`
- **Product Listing**: Products with filtering in `/lib/src/controller/product_controller.dart`
- **Orders**: Order management in `/lib/src/controller/order_controller.dart`
- **Maintenance Mode**: Recently added in `/lib/src/view/screen/maintenance_screen.dart`

## Testing Approach

Tests are located in `/test/` directory. Run specific tests with:
```bash
flutter test test/specific_test_file.dart
```

## Important Considerations

1. **API Integration**: The app connects to Botble E-commerce backend. Check `app_config.dart` for endpoint configuration.

2. **State Persistence**: User data and cart are persisted using `shared_preferences`.

3. **Image Handling**: Uses `cached_network_image` for efficient image loading with placeholders.

4. **Social Login Configuration**: Social login credentials must be configured in the respective platform consoles and `.env` file.

5. **Push Notifications**: Firebase is configured for push notifications. Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly configured.

6. **Recent Changes**: The git status shows modifications to translation files and services, plus a new maintenance screen implementation.