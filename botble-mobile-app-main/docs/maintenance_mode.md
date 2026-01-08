# Error Handling for API Status Codes

The app now automatically handles multiple error scenarios when the API returns specific status codes.

## Supported Error Codes

### 502 - Bad Gateway (Server Error)
When your backend API returns a 502 status code, the app will:
1. **Automatically detect** the server error response
2. **Navigate to a server error screen** with appropriate messaging
3. **Provide a retry option** to go back to the start screen

### 503 - Service Unavailable (Maintenance Mode)
When your backend API returns a 503 status code, the app will:
1. **Automatically detect** the maintenance mode response
2. **Navigate to a maintenance screen** that shows a user-friendly message
3. **Provide a retry option** to go back to the start screen

### 404 - Not Found
When your backend API returns a 404 status code, the app will:
1. **Automatically detect** the not found response
2. **Navigate to a not found error screen** with helpful messaging
3. **Provide a go back option** to return to the start screen

## What Users See

### Server Error (502)
When a server error occurs, users will see:
- 🖥️ **Server icon** - Clear visual indicator (dns_outlined)
- **Server Error title** - Translated to user's language
- **Helpful message** - Explaining the temporary server issue
- **Try Again button** - To retry when server is back online

### Maintenance Mode (503)
When maintenance mode is active, users will see:
- 🔧 **Maintenance icon** - Clear visual indicator (build_circle_outlined)
- **Maintenance Mode title** - Translated to user's language
- **Friendly message** - Explaining the situation
- **Try Again button** - To retry when maintenance is complete

### Not Found (404)
When a resource is not found, users will see:
- 🔍 **Search off icon** - Clear visual indicator (search_off_outlined)
- **Page Not Found title** - Translated to user's language
- **Helpful message** - Explaining the missing resource
- **Go Back button** - To return to the previous screen

## Supported Languages

All error screens support multiple languages with appropriate translations:

### Server Error Messages (502)
- **English** - "The server is temporarily unavailable. Please try again in a few moments."
- **Thai** - "เซิร์ฟเวอร์ไม่สามารถใช้งานได้ชั่วคราว กรุณาลองใหม่อีกครั้งในอีกสักครู่"
- **Japanese** - "サーバーが一時的に利用できません。しばらくしてから再度お試しください。"
- **Chinese** - "伺服器暫時無法使用。請稍後再試。"
- **Vietnamese** - "Máy chủ tạm thời không khả dụng. Vui lòng thử lại sau ít phút."
- **Italian** - "Il server è temporaneamente non disponibile. Riprova tra qualche momento."
- **Spanish** - "El servidor no está disponible temporalmente. Por favor, inténtalo de nuevo en unos momentos."
- **French** - "Le serveur est temporairement indisponible. Veuillez réessayer dans quelques instants."
- **German** - "Der Server ist vorübergehend nicht verfügbar. Bitte versuchen Sie es in wenigen Augenblicken erneut."
- **Arabic** - "الخادم غير متاح مؤقتاً. يرجى المحاولة مرة أخرى خلال لحظات قليلة."

### Maintenance Mode Messages (503)
- **English** - "We're currently performing maintenance to improve your experience. Please try again later."
- **Thai** - "เรากำลังดำเนินการบำรุงรักษาเพื่อปรับปรุงประสบการณ์ของคุณ กรุณาลองใหม่อีกครั้งในภายหลัง"
- **Japanese** - "より良いサービスを提供するためにメンテナンスを実施しています。しばらくしてから再度お試しください。"
- **Chinese** - "我們正在進行維護以改善您的體驗。請稍後再試。"
- **Vietnamese** - "Chúng tôi đang thực hiện bảo trì để cải thiện trải nghiệm của bạn. Vui lòng thử lại sau."
- **Italian** - "Stiamo eseguendo la manutenzione per migliorare la tua esperienza. Riprova più tardi."
- **Spanish** - "Estamos realizando mantenimiento para mejorar tu experiencia. Por favor, inténtalo de nuevo más tarde."
- **French** - "Nous effectuons actuellement une maintenance pour améliorer votre expérience. Veuillez réessayer plus tard."
- **German** - "Wir führen derzeit Wartungsarbeiten durch, um Ihre Erfahrung zu verbessern. Bitte versuchen Sie es später erneut."
- **Arabic** - "نحن نقوم حالياً بأعمال الصيانة لتحسين تجربتك. يرجى المحاولة مرة أخرى لاحقاً."

### Not Found Messages (404)
- **English** - "The page or resource you're looking for could not be found. Please check and try again."
- **Thai** - "ไม่พบหน้าหรือทรัพยากรที่คุณกำลังมองหา กรุณาตรวจสอบและลองใหม่อีกครั้ง"
- **Japanese** - "お探しのページまたはリソースが見つかりませんでした。確認してから再度お試しください。"
- **Chinese** - "找不到您要尋找的頁面或資源。請檢查後重試。"
- **Vietnamese** - "Không thể tìm thấy trang hoặc tài nguyên bạn đang tìm kiếm. Vui lòng kiểm tra và thử lại."
- **Italian** - "La pagina o risorsa che stai cercando non è stata trovata. Controlla e riprova."
- **Spanish** - "No se pudo encontrar la página o recurso que buscas. Por favor, verifica e inténtalo de nuevo."
- **French** - "La page ou la ressource que vous recherchez est introuvable. Veuillez vérifier et réessayer."
- **German** - "Die gesuchte Seite oder Ressource konnte nicht gefunden werden. Bitte überprüfen Sie und versuchen Sie es erneut."
- **Arabic** - "لا يمكن العثور على الصفحة أو المورد الذي تبحث عنه. يرجى التحقق والمحاولة مرة أخرى."

## Technical Implementation

### BaseService Changes

The `BaseService` class now handles multiple error status codes in the `_handleResponse` method:

```dart
if (response.statusCode == 502) {
  // Handle bad gateway - show server error screen
  Get.offAll(() => ServerErrorScreen(
    onRetry: () {
      Get.offAll(() => const StartScreen());
    },
  ));
  throw Exception('Bad Gateway - Server Error');
}

if (response.statusCode == 503) {
  // Handle maintenance mode - show maintenance screen
  Get.offAll(() => MaintenanceScreen(
    onRetry: () {
      Get.offAll(() => const StartScreen());
    },
  ));
  throw Exception('Service Unavailable - Maintenance Mode');
}

if (response.statusCode == 404) {
  // Handle not found - show not found error screen
  Get.offAll(() => NotFoundErrorScreen(
    onRetry: () {
      Get.offAll(() => const StartScreen());
    },
  ));
  throw Exception('Not Found - Resource Not Available');
}
```

### Error Screens

Three new error screens provide comprehensive error handling:

#### ServerErrorScreen (`lib/src/view/screen/server_error_screen.dart`)
- **Server error icon** (dns_outlined) with red error color
- **Responsive design** that works on all screen sizes
- **Dark mode support** with appropriate colors
- **Consistent styling** with the app's design system

#### MaintenanceScreen (`lib/src/view/screen/maintenance_screen.dart`)
- **Maintenance icon** (build_circle_outlined) with warning color
- **Responsive design** that works on all screen sizes
- **Dark mode support** with appropriate colors
- **Consistent styling** with the app's design system

#### NotFoundErrorScreen (`lib/src/view/screen/not_found_error_screen.dart`)
- **Search off icon** (search_off_outlined) with info color
- **Responsive design** that works on all screen sizes
- **Dark mode support** with appropriate colors
- **Consistent styling** with the app's design system

## For Developers

### Adding New Languages

To add error handling support for a new language:

1. Open the translation file (e.g., `assets/translations/your_language.json`)
2. Add these keys to the `common` section:

```json
{
  "common": {
    "server_error": "Your translation for 'Server Error'",
    "server_error_message": "Your translation for the server error message",
    "server_error_retry": "Your translation for 'Try Again'",
    "maintenance_mode": "Your translation for 'Maintenance Mode'",
    "maintenance_message": "Your translation for the maintenance message",
    "maintenance_retry": "Your translation for 'Try Again'",
    "not_found_error": "Your translation for 'Page Not Found'",
    "not_found_message": "Your translation for the not found message",
    "not_found_retry": "Your translation for 'Go Back'"
  }
}
```

### Testing

The error handling functionality includes comprehensive tests:

- **Unit tests** for all error screen widgets
- **Integration tests** for 502, 503, and 404 error handling
- **UI tests** for dark/light mode compatibility
- **Color and icon tests** for visual consistency

Run tests with:
```bash
flutter test test/error_screens_test.dart
flutter test test/maintenance_mode_test.dart
flutter test test/base_service_503_test.dart
```

## User Experience

The error handling system provides a smooth user experience by:

- **Automatically handling** 502, 503, and 404 errors without crashes
- **Providing clear communication** about what's happening with appropriate icons and messages
- **Offering easy recovery** with retry/go back buttons
- **Maintaining app consistency** with familiar styling and colors
- **Supporting all languages** the app supports
- **Using appropriate visual cues** (different icons and colors for different error types)

This ensures users understand what's happening and can easily recover from different error scenarios:
- **Server errors (502)**: Users know it's a temporary server issue and can retry
- **Maintenance mode (503)**: Users understand maintenance is happening and can retry later
- **Not found errors (404)**: Users understand the resource doesn't exist and can go back
