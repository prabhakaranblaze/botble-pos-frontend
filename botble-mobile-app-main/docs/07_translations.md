# Configuring Translations

The app uses `easy_localization` for managing multiple languages with a two-tier translation system:

- **Default translations**: Located in `lib/translations/` - these are the built-in translations that come with the app
- **User translations**: Located in `assets/translations/` - these are custom translations that override the defaults

## Translation Priority System

The app uses a fallback system where:
1. **User translations** in `assets/translations/` take priority
2. **Default translations** in `lib/translations/` are used as fallback
3. Missing keys in user translations will automatically fall back to default translations
4. User translations can partially override defaults (you don't need to copy the entire file)

## Adding/Modifying User Translations

1. Navigate to `assets/translations/`
2. Create or edit language files (e.g., `en.json`, `vi.json`, `ar.json`)
3. Add only the translations you want to customize:
   ```json
   {
     "app": {
       "unlock_amazing": "Your Custom Text Here"
     },
     "common": {
       "submit": "Custom Submit Text"
     }
   }
   ```

## Modifying Default Translations

1. Navigate to `lib/translations/`
2. Edit the appropriate language file
3. These changes will affect all installations unless overridden by user translations

## Supported Languages
The app currently supports:
- English (en)
- Vietnamese (vi)
- Arabic (ar)
- Bengali (bn)
- Spanish (es)
- French (fr)
- Hindi (hi)
- Indonesian (id)

## Adding a New Language

1. **For default support**: Create a new JSON file in `lib/translations/` (e.g., `fr.json` for French)
2. **For user customization**: Create a new JSON file in `assets/translations/` (e.g., `fr.json` for French)
3. Add the new locale in `lib/main.dart`:
   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('vi'),
     Locale('ar'),
     // Add your new locale here
     Locale('fr'),
   ],
   ```

## Translation File Structure

Both `lib/translations/` and `assets/translations/` use the same JSON structure. Here's an example:

```json
{
  "app": {
    "unlock_amazing": "Unlock Amazing",
    "deals_discounts": "Deals & Discounts"
  },
  "common": {
    "submit": "Submit",
    "cancel": "Cancel"
  }
}
```

## Using Translations in Code

1. Import the translation package:
   ```dart
   import 'package:easy_localization/easy_localization.dart';
   ```

2. Use translations in your code:
   ```dart
   // Simple translation
   Text('hello'.tr())

   // Translation with parameters
   Text('welcome_user'.tr(args: ['John']))

   // Pluralization
   Text('items_count'.plural(5))
   ```

## Important Notes
- Always use meaningful keys for translations
- Keep translations organized in nested objects for better structure
- Test all supported languages after making changes
- Consider RTL (Right-to-Left) support for languages like Arabic
- **User translations** in `assets/translations/` will override **default translations** in `lib/translations/`
- You only need to include the keys you want to customize in user translation files
- Missing keys in user translations will automatically fall back to default translations
- Default translations should be comprehensive, while user translations can be partial
