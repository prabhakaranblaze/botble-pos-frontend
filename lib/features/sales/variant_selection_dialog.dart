import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../shared/constants/app_constants.dart';

class VariantSelectionDialog extends StatefulWidget {
  final Product product;

  const VariantSelectionDialog({
    super.key,
    required this.product,
  });

  @override
  State<VariantSelectionDialog> createState() => _VariantSelectionDialogState();
}

class _VariantSelectionDialogState extends State<VariantSelectionDialog> {
  final Map<int, int> _selectedVariantOptions = {}; // variantId -> optionId
  int _quantity = 1;

  double get _calculatedPrice {
    double basePrice = widget.product.finalPrice;
    double modifiersTotal = 0;

    // Add price modifiers from selected variants
    for (var variant in widget.product.variants ?? []) {
      final selectedOptionId = _selectedVariantOptions[variant.id];
      if (selectedOptionId != null) {
        final option = variant.options.firstWhere(
          (o) => o.id == selectedOptionId,
          orElse: () => variant.options.first,
        );
        modifiersTotal += option.priceModifier ?? 0;
      }
    }

    return (basePrice + modifiersTotal) * _quantity;
  }

  bool get _isValid {
    // Check if all variants have a selection
    if (widget.product.variants == null) return true;

    for (var variant in widget.product.variants!) {
      if (!_selectedVariantOptions.containsKey(variant.id)) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Pre-select first option for each variant
    for (var variant in widget.product.variants ?? []) {
      if (variant.options.isNotEmpty) {
        _selectedVariantOptions[variant.id] = variant.options.first.id;
      }
    }
  }

  void _handleAddToCart() {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all options')),
      );
      return;
    }

    // Return selected variant data
    Navigator.pop(context, {
      'product_id': widget.product.id,
      'quantity': _quantity,
      'variants': _selectedVariantOptions,
      'price': _calculatedPrice,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Product Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Image
                    if (widget.product.image != null)
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(widget.product.image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Product Name
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Base Price
                    Text(
                      'Base: ${AppCurrency.format(widget.product.finalPrice)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Divider(),

                    const SizedBox(height: 16),

                    // Variant Options
                    ...widget.product.variants?.map((variant) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _buildVariantSelector(variant),
                          );
                        }) ??
                        [],

                    const SizedBox(height: 8),

                    // Quantity Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Total Price
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            AppCurrency.format(_calculatedPrice),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Add to Cart Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isValid ? _handleAddToCart : null,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    'Add to Cart - ${AppCurrency.format(_calculatedPrice)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelector(ProductVariant variant) {
    final selectedOptionId = _selectedVariantOptions[variant.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          variant.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variant.options.map((option) {
            final isSelected = option.id == selectedOptionId;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedVariantOptions[variant.id] = option.id;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (option.priceModifier != null &&
                        option.priceModifier != 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          option.priceModifier! > 0
                              ? '+\$${option.priceModifier!.toStringAsFixed(2)}'
                              : '-\$${option.priceModifier!.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
