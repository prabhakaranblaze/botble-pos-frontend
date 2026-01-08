import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/compare_service.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCompareDetails();
  }

  Future<void> _getCompareDetails() async {
    try {
      setState(() => _isLoading = true);
      final response = await CompareService().getCompare();
      setState(() {
        _products =
            response['items'].isNotEmpty
                ? response['items'].values.toList()
                : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromCompare(String productId) async {
    try {
      await CompareService().removeFromCompare(productId);
      _getCompareDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: AppColors.primary, size: 16);
        } else if (index < rating.ceil() && rating % 1 != 0) {
          return const Icon(
            Icons.star_half,
            color: AppColors.primary,
            size: 16,
          );
        } else {
          return const Icon(
            Icons.star_border,
            color: AppColors.primary,
            size: 16,
          );
        }
      }),
    );
  }

  Widget _buildPriceText(dynamic product) {
    if (product == null || product == '-') {
      return Text(
        '-',
        style: kAppTextStyle(
          fontSize: 14,
          color: AppColors.getSecondaryTextColor(context),
        ),
      );
    }

    final String currentPrice = product['price_formatted'] ?? '';
    final String originalPrice = product['original_price_formatted'] ?? '';
    final bool hasDiscount =
        originalPrice.isNotEmpty &&
        originalPrice != currentPrice &&
        (product['original_price'] ?? 0) > (product['price'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current/Sale Price
        Text(
          currentPrice,
          style: kAppTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        // Original Price (if on sale)
        if (hasDiscount) ...[
          const SizedBox(height: 2),
          Text(
            originalPrice,
            style: kAppTextStyle(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              color: AppColors.getSecondaryTextColor(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderProduct() {
    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getBackgroundColor(context),
                border: Border.all(
                  color: AppColors.getBorderColor(context),
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 32,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'compare.add_more_products'.tr(),
                    style: kAppTextStyle(
                      fontSize: 12,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '',
            style: kAppTextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Product images skeleton
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(context),
            border: Border(
              bottom: BorderSide(color: AppColors.getBorderColor(context)),
            ),
          ),
          child: Row(
            children:
                List.generate(
                  2,
                  (index) => [
                    if (index > 0) const SizedBox(width: 16),
                    _buildProductImageSkeleton(),
                  ],
                ).expand((widgets) => widgets).toList(),
          ),
        ),
        // Add to cart buttons skeleton
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children:
                List.generate(
                  2,
                  (index) => [
                    if (index > 0) const SizedBox(width: 16),
                    _buildButtonSkeleton(),
                  ],
                ).expand((widgets) => widgets).toList(),
          ),
        ),
        // Comparison attributes skeleton
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                5,
                (index) => _buildAttributeRowSkeleton(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImageSkeleton() {
    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.getSkeletonColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSkeleton() {
    return Expanded(
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.getSkeletonColor(context),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildAttributeRowSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        children: [
          // Attribute name column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Product value columns with gaps
          ...List.generate(
            2,
            (index) => [
              if (index > 0) const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).expand((widgets) => widgets).toList(),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String attribute, List<dynamic> values) {
    // Pad values with placeholder if there's only one product (for 2-product comparison)
    List<dynamic> paddedValues = List.from(values);
    if (paddedValues.length == 1) {
      paddedValues.add('-');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Attribute name column
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attribute,
                    style: kAppTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16), // Gap between attribute name and values
            // Product value columns
            ...paddedValues
                .asMap()
                .entries
                .map((entry) {
                  int index = entry.key;
                  var value = entry.value;
                  bool isPlaceholder = values.length == 1 && value == '-';
                  return [
                    if (index > 0)
                      const SizedBox(width: 16), // Gap between product columns
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPlaceholder)
                            Text(
                              '-',
                              style: kAppTextStyle(
                                fontSize: 14,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                            )
                          else if (attribute == 'compare.rating'.tr())
                            _buildRatingStars(
                              double.tryParse(value?.toString() ?? '0') ?? 0,
                            )
                          else if (attribute == 'compare.price'.tr())
                            _buildPriceText(value)
                          else
                            Text(
                              value?.toString() ?? '-',
                              style: kAppTextStyle(
                                fontSize: 14,
                                color: AppColors.getPrimaryTextColor(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ];
                })
                .expand((widgets) => widgets)
                .toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'compare.compare'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _products.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      size: 64,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'compare.no_products_to_compare'.tr(),
                      style: kAppTextStyle(
                        fontSize: 16,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Show notification message when only one product
                  if (_products.length == 1)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'compare.single_product_message'.tr(),
                              style: kAppTextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(context),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.getBorderColor(context),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Show actual products with gaps
                        ..._products
                            .asMap()
                            .entries
                            .map((entry) {
                              int index = entry.key;
                              var product = entry.value;
                              return [
                                if (index > 0)
                                  const SizedBox(
                                    width: 16,
                                  ), // Gap between products
                                Expanded(
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 1,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color:
                                                      AppColors.getBorderColor(
                                                        context,
                                                      ),
                                                  width: 1,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Image.network(
                                                product['image_url'] ?? '',
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color:
                                                          AppColors.getSkeletonColor(
                                                            context,
                                                          ),
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color:
                                                            AppColors.getSecondaryTextColor(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => _removeFromCompare(
                                                    product['id'].toString(),
                                                  ),
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.getSurfaceColor(
                                                      context,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                minimumSize: const Size(28, 28),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product['name'] ?? '',
                                        style: kAppTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getPrimaryTextColor(
                                            context,
                                          ),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            })
                            .expand((widgets) => widgets)
                            .toList(),
                        // Show placeholder when there's only one product (for 2-product comparison)
                        if (_products.length == 1) ...[
                          const SizedBox(width: 16), // Gap before placeholder
                          _buildPlaceholderProduct(),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Add to cart buttons for actual products with gaps
                        ..._products
                            .asMap()
                            .entries
                            .map((entry) {
                              int index = entry.key;
                              var product = entry.value;
                              return [
                                if (index > 0)
                                  const SizedBox(
                                    width: 16,
                                  ), // Gap between buttons
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final scaffoldMessenger =
                                          ScaffoldMessenger.of(context);
                                      try {
                                        await CartService().createCartItem(
                                          productId: product['id'].toString(),
                                          quantity: 1,
                                        );
                                        if (mounted) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'product.added_to_cart'.tr(),
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size(
                                        double.infinity,
                                        36,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'product.add_to_cart'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ];
                            })
                            .expand((widgets) => widgets)
                            .toList(),
                        // Empty space for placeholder when there's only one product
                        if (_products.length == 1) ...[
                          const SizedBox(width: 16), // Gap before empty space
                          const Expanded(child: SizedBox()),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAttributeRow(
                            'compare.rating'.tr(),
                            _products
                                .map((p) => p['reviews_avg'] ?? 0)
                                .toList(),
                          ),
                          _buildAttributeRow(
                            'compare.price'.tr(),
                            _products.toList(),
                          ),
                          // Add stock status comparison
                          _buildAttributeRow(
                            'compare.stock_status'.tr(),
                            _products
                                .map((p) => p['stock_status_label'] ?? '-')
                                .toList(),
                          ),
                          // Add SKU comparison
                          _buildAttributeRow(
                            'compare.sku'.tr(),
                            _products.map((p) => p['sku'] ?? '-').toList(),
                          ),
                          // Add product attributes/specifications if available
                          if (_products.isNotEmpty &&
                              _products[0]['specifications'] != null)
                            ...(_products[0]['specifications']
                                    as Map<String, dynamic>)
                                .keys
                                .map(
                                  (spec) => _buildAttributeRow(
                                    spec,
                                    _products
                                        .map((p) => p['specifications']?[spec])
                                        .toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
