import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'
    hide StringTranslateExtension;
import 'package:martfury/src/theme/app_colors.dart';

enum ProductCardLayout { grid, list, horizontal }

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double price;
  final double originalPrice;
  final int? reviewsCount;
  final double? rating;
  final String? seller;
  final VoidCallback? onTap;
  final String priceFormatted;
  final String originalPriceFormatted;
  final ProductCardLayout layout;
  final double? height;
  final double? width;
  final int? soldCount;
  final int? totalCount;
  final bool showProgressBar;

  const ProductCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.originalPrice,
    this.reviewsCount,
    this.rating,
    this.seller,
    this.onTap,
    required this.priceFormatted,
    required this.originalPriceFormatted,
    this.layout = ProductCardLayout.grid,
    this.height,
    this.width,
    this.soldCount,
    this.totalCount,
    this.showProgressBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case ProductCardLayout.list:
        return _buildListCard(context);
      case ProductCardLayout.horizontal:
        return _buildHorizontalCard(context);
      case ProductCardLayout.grid:
        return _buildGridCard(context);
    }
  }

  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed aspect ratio image container
            AspectRatio(
              aspectRatio: 1.0, // Square aspect ratio
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.getSurfaceColor(context),
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.getHintTextColor(context),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Content area with flexible sizing
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(showProgressBar ? 4.0 : 6.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate available height for content
                    final availableHeight = constraints.maxHeight;
                    final titleHeight =
                        availableHeight > 70 ? 22.0 : 20.0; // Adjust title height based on available space

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Title with adaptive height - more compact for flash sale
                        SizedBox(
                          height: titleHeight,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: availableHeight > 80 ? 14 : 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getPrimaryTextColor(context),
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: availableHeight > 80 ? 3 : 1),
                        // Price section - more compact for smaller cards
                        Text(
                          priceFormatted,
                          style: TextStyle(
                            fontSize:
                                availableHeight > 80
                                    ? 15
                                    : (availableHeight > 60 ? 14 : 13),
                            fontWeight: FontWeight.bold,
                            color: AppColors.priceColor,
                          ),
                        ),
                        // Sale price (if exists) - only show if there's enough space
                        if (price != originalPrice && availableHeight > 60) ...[
                          const SizedBox(height: 1),
                          Text(
                            originalPriceFormatted,
                            style: TextStyle(
                              fontSize: availableHeight > 60 ? 10 : 9,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.originalPriceColor,
                            ),
                          ),
                        ],
                        // Flexible spacer to push content to bottom
                        Expanded(
                          child: Container(
                            constraints: BoxConstraints(
                              minHeight: availableHeight > 70 ? 6.0 : 2.0,
                            ),
                          ),
                        ),
                        // Bottom section - positioned at bottom with minimal padding
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: availableHeight > 80 ? 2.0 : 0.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar section (for flash sale products) - show first
                              if (showProgressBar &&
                                  soldCount != null &&
                                  totalCount != null) ...[
                                Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F6F6),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor:
                                          totalCount! > 0
                                              ? (soldCount! / totalCount!)
                                                  .clamp(0.0, 1.0)
                                              : 0.0,
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: availableHeight > 70 ? 2 : 1),
                              ],
                              // Rating info - show if available and there's enough space
                              if (rating != null && availableHeight > 60) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Color(0xFFFBBF24),
                                    ),
                                    const SizedBox(width: 1),
                                    Text(
                                      rating?.toStringAsFixed(1) ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.getPrimaryTextColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 1),
                                    Expanded(
                                      child: Text(
                                        '(${reviewsCount ?? 0})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              AppColors.getSecondaryTextColor(
                                                context,
                                              ),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Seller info - show if available and there's enough space
                              if (seller != null &&
                                  seller!.isNotEmpty &&
                                  availableHeight > 80) ...[
                                const SizedBox(height: 1),
                                Text(
                                  context.tr(
                                    'product.by_seller',
                                    namedArgs: {'seller': seller!},
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            SizedBox(
              width: height ?? 120,
              height: height ?? 120,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.getSurfaceColor(context),
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.getHintTextColor(context),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    // Price and rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceFormatted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.priceColor,
                          ),
                        ),
                        if (price != originalPrice) ...[
                          const SizedBox(height: 2),
                          Text(
                            originalPriceFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.originalPriceColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (rating != null) ...[
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating?.toStringAsFixed(1) ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.getPrimaryTextColor(context),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${reviewsCount ?? 0})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                            if (seller != null && seller!.isNotEmpty) ...[
                              if (rating != null) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr(
                                    'product.by_seller',
                                    namedArgs: {'seller': seller!},
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 160,
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 120,
                    color: AppColors.getSurfaceColor(context),
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.getHintTextColor(context),
                    ),
                  );
                },
              ),
            ),
            // Product content with flexible spacing
            Padding(
              padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product title with minimum height for 2 lines
                  SizedBox(
                    height: 33.8, // 13px font * 1.3 line height * 2 lines
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getPrimaryTextColor(context),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price section
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priceFormatted,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.priceColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Always reserve space for sale price line
                      SizedBox(
                        height: 13.2, // 11px font size * 1.2 line height
                        child:
                            (price != originalPrice)
                                ? Text(
                                  originalPriceFormatted,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.originalPriceColor,
                                  ),
                                )
                                : null, // Empty space when no sale price
                      ),
                    ],
                  ),
                  // Rating section
                  if (rating != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating?.toStringAsFixed(1) ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getPrimaryTextColor(context),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '(${reviewsCount ?? 0})',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Seller section (make it more compact)
                  if (seller != null && seller!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        'product.by_seller',
                        namedArgs: {'seller': seller!},
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
