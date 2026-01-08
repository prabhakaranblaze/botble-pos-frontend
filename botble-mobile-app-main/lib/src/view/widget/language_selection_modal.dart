import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/model/language.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';

class LanguageSelectionModal extends StatefulWidget {
  final List<Language> languages;
  final Language? selectedLanguage;

  const LanguageSelectionModal({
    super.key,
    required this.languages,
    this.selectedLanguage,
  });

  @override
  State<LanguageSelectionModal> createState() => _LanguageSelectionModalState();
}

class _LanguageSelectionModalState extends State<LanguageSelectionModal> {
  late List<Language> _sortedLanguages;

  @override
  void initState() {
    super.initState();
    _sortedLanguages = List.from(widget.languages);
    _sortedLanguages.sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.getSecondaryTextColor(
                context,
              ).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'profile.select_language'.tr(),
                  style: kAppTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getPrimaryTextColor(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),

          // Languages list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _sortedLanguages.length,
              itemBuilder: (context, index) {
                final language = _sortedLanguages[index];
                final isSelected = widget.selectedLanguage?.id == language.id;
                final isLast = index == _sortedLanguages.length - 1;

                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, language),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration:
                              isSelected
                                  ? BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: const Border(
                                      left: BorderSide(
                                        color: AppColors.primary,
                                        width: 3,
                                      ),
                                    ),
                                  )
                                  : null,
                          child: Row(
                            children: [
                              // Flag
                              Container(
                                width: 32,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.getBorderColor(context),
                                    width: 0.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3.5),
                                  child: _buildFlag(language.flag),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Language name
                              Expanded(
                                child: Text(
                                  language.name,
                                  style: kAppTextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    color: AppColors.getPrimaryTextColor(
                                      context,
                                    ),
                                  ),
                                ),
                              ),

                              // Selected indicator
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.getBorderColor(
                          context,
                        ).withValues(alpha: 0.3),
                        indent: 68, // Align with text content
                        endIndent: 20,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlag(String flag) {
    // Check if the flag is SVG content (starts with <svg or contains svg tags)
    if (flag.contains('<svg') || flag.contains('</svg>')) {
      return SvgPicture.string(
        flag,
        fit: BoxFit.cover,
        placeholderBuilder:
            (context) => Container(
              color: AppColors.getSkeletonColor(context),
              child: Icon(
                Icons.flag,
                size: 16,
                color: AppColors.getSecondaryTextColor(context),
              ),
            ),
      );
    } else {
      // Assume it's a URL
      return Image.network(
        flag,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.getSkeletonColor(context),
            child: Icon(
              Icons.flag,
              size: 16,
              color: AppColors.getSecondaryTextColor(context),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: AppColors.getSkeletonColor(context));
        },
      );
    }
  }
}
