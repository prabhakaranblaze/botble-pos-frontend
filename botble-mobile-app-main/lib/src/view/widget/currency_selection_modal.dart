import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/model/currency.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';

class CurrencySelectionModal extends StatefulWidget {
  final List<Currency> currencies;
  final Currency? selectedCurrency;

  const CurrencySelectionModal({
    super.key,
    required this.currencies,
    this.selectedCurrency,
  });

  @override
  State<CurrencySelectionModal> createState() => _CurrencySelectionModalState();
}

class _CurrencySelectionModalState extends State<CurrencySelectionModal> {
  late List<Currency> _sortedCurrencies;

  @override
  void initState() {
    super.initState();
    _sortedCurrencies = List.from(widget.currencies);
    _sortedCurrencies.sort((a, b) => a.order.compareTo(b.order));
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
                  'profile.select_currency'.tr(),
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

          // Currencies list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _sortedCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _sortedCurrencies[index];
                final isSelected = widget.selectedCurrency?.id == currency.id;
                final isLast = index == _sortedCurrencies.length - 1;

                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, currency),
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
                              // Currency symbol
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.getBackgroundColor(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.getBorderColor(context),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    currency.symbol,
                                    style: kAppTextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Currency details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currency.title,
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
                                    if (!currency.isDefault)
                                      Text(
                                        '1 USD = ${currency.exchangeRate.toStringAsFixed(currency.exchangeRate >= 1 ? 2 : 6)} ${currency.title}',
                                        style: kAppTextStyle(
                                          fontSize: 12,
                                          color:
                                              AppColors.getSecondaryTextColor(
                                                context,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Default badge or selected indicator
                              if (currency.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'common.default'.tr(),
                                    style: kAppTextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                )
                              else if (isSelected)
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
                        indent: 76, // Align with text content
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
}
