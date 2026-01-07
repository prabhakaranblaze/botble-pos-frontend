import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../constants/app_constants.dart';

/// A dropdown button to switch between languages
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;

    return DropdownButton<Locale>(
      value: localeProvider.locale,
      underline: const SizedBox(),
      icon: const Icon(Icons.language),
      items: LocaleProvider.supportedLocales.map((locale) {
        return DropdownMenuItem<Locale>(
          value: locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getFlagEmoji(locale.languageCode)),
              const SizedBox(width: 8),
              Text(localeProvider.getDisplayName(locale)),
            ],
          ),
        );
      }).toList(),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          localeProvider.setLocale(newLocale);
        }
      },
    );
  }

  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      default:
        return '🌐';
    }
  }
}

/// A tile for language selection in settings
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(localeProvider.getDisplayName(localeProvider.locale)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleProvider.supportedLocales.map((locale) {
            final isSelected = locale == localeProvider.locale;
            return ListTile(
              leading: Text(
                _getFlagEmoji(locale.languageCode),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(localeProvider.getDisplayName(locale)),
              trailing: isSelected
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              selected: isSelected,
              onTap: () {
                localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      default:
        return '🌐';
    }
  }
}

/// A simple toggle button for language (EN/FR)
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return TextButton.icon(
      icon: const Icon(Icons.language, size: 20),
      label: Text(
        localeProvider.locale.languageCode.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () => localeProvider.toggleLocale(),
    );
  }
}
