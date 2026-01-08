import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/product_detail_screen.dart';
import 'package:martfury/src/service/product_service.dart';
import 'package:martfury/src/view/widget/product_card.dart';
import 'package:martfury/src/view/widget/section_header.dart';

class ProductSlider extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> products;
  final VoidCallback? onViewAll;
  final bool showProgressBar;

  const ProductSlider({
    super.key,
    required this.title,
    required this.products,
    this.onViewAll,
    this.showProgressBar = false,
  });

  @override
  State<ProductSlider> createState() => _ProductSliderState();
}

class _ProductSliderState extends State<ProductSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToProduct(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    // Add to recently viewed before navigation
    await ProductService.addToRecentlyViewed({
      'id': product['id'],
      'slug': product['slug'],
      'image': product['imageUrl'],
    });

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ProductDetailScreen(product: {'slug': product['url']}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate layout based on number of products
    // 2 products: single row (1x2), no dots
    // 4+ products: two rows (2x2), show dots if multiple pages
    final bool showTwoRows = widget.products.length >= 4;
    final int productsPerPage = showTwoRows ? 4 : 2;
    final int totalPages = (widget.products.length / productsPerPage).ceil();
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Column(
      children: [
        SectionHeader(title: widget.title, onViewAll: widget.onViewAll),
        SizedBox(
          height:
              showTwoRows
                  ? totalPages > 1
                      ? 640
                      : 620
                  : 300, // Reduced height for more compact display
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: totalPages,
                  itemBuilder: (context, pageIndex) {
                    if (showTwoRows) {
                      // Two rows layout (4 products per page)
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            // First row
                            Expanded(
                              child: Row(
                                children: List.generate(2, (index) {
                                  final productIndex = pageIndex * 4 + index;
                                  if (productIndex >= widget.products.length) {
                                    return const Spacer();
                                  }

                                  final product = widget.products[productIndex];
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            isRtl
                                                ? (index == 1 ? 8.0 : 0.0)
                                                : (index == 0 ? 8.0 : 0.0),
                                        left:
                                            isRtl
                                                ? (index == 0 ? 8.0 : 0.0)
                                                : (index == 1 ? 8.0 : 0.0),
                                      ),
                                      child: GestureDetector(
                                        onTap:
                                            () => _navigateToProduct(
                                              context,
                                              product,
                                            ),
                                        child: ProductCard(
                                          imageUrl: product['imageUrl'],
                                          title: product['title'],
                                          price: product['price'],
                                          originalPrice:
                                              product['originalPrice'],
                                          rating: product['rating'],
                                          reviewsCount: product['reviews'],
                                          seller: product['seller'],
                                          priceFormatted:
                                              product['priceFormatted'],
                                          originalPriceFormatted:
                                              product['originalPriceFormatted'],
                                          showProgressBar:
                                              widget.showProgressBar,
                                          soldCount:
                                              widget.showProgressBar
                                                  ? (product['sold'] as int? ??
                                                      0)
                                                  : null,
                                          totalCount:
                                              widget.showProgressBar
                                                  ? ((product['sold'] as int? ??
                                                          0) +
                                                      (product['sale_count_left']
                                                              as int? ??
                                                          1))
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Second row
                            Expanded(
                              child: Row(
                                children: List.generate(2, (index) {
                                  final productIndex =
                                      pageIndex * 4 + index + 2;
                                  if (productIndex >= widget.products.length) {
                                    return const Spacer();
                                  }

                                  final product = widget.products[productIndex];
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            isRtl
                                                ? (index == 1 ? 8.0 : 0.0)
                                                : (index == 0 ? 8.0 : 0.0),
                                        left:
                                            isRtl
                                                ? (index == 0 ? 8.0 : 0.0)
                                                : (index == 1 ? 8.0 : 0.0),
                                      ),
                                      child: GestureDetector(
                                        onTap:
                                            () => _navigateToProduct(
                                              context,
                                              product,
                                            ),
                                        child: ProductCard(
                                          imageUrl: product['imageUrl'],
                                          title: product['title'],
                                          price: product['price'],
                                          originalPrice:
                                              product['originalPrice'],
                                          rating: product['rating'],
                                          reviewsCount: product['reviews'],
                                          seller: product['seller'],
                                          priceFormatted:
                                              product['priceFormatted'],
                                          originalPriceFormatted:
                                              product['originalPriceFormatted'],
                                          showProgressBar:
                                              widget.showProgressBar,
                                          soldCount:
                                              widget.showProgressBar
                                                  ? (product['sold'] as int? ??
                                                      0)
                                                  : null,
                                          totalCount:
                                              widget.showProgressBar
                                                  ? ((product['sold'] as int? ??
                                                          0) +
                                                      (product['sale_count_left']
                                                              as int? ??
                                                          1))
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Single row layout (2 products per page)
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: List.generate(2, (index) {
                            final productIndex = pageIndex * 2 + index;
                            if (productIndex >= widget.products.length) {
                              return const Spacer();
                            }

                            final product = widget.products[productIndex];
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right:
                                      isRtl
                                          ? (index == 1 ? 8.0 : 0.0)
                                          : (index == 0 ? 8.0 : 0.0),
                                  left:
                                      isRtl
                                          ? (index == 0 ? 8.0 : 0.0)
                                          : (index == 1 ? 8.0 : 0.0),
                                ),
                                child: GestureDetector(
                                  onTap:
                                      () =>
                                          _navigateToProduct(context, product),
                                  child: ProductCard(
                                    imageUrl: product['imageUrl'],
                                    title: product['title'],
                                    price: product['price'],
                                    originalPrice: product['originalPrice'],
                                    rating: product['rating'],
                                    reviewsCount: product['reviews'],
                                    seller: product['seller'],
                                    priceFormatted: product['priceFormatted'],
                                    originalPriceFormatted:
                                        product['originalPriceFormatted'],
                                    showProgressBar: widget.showProgressBar,
                                    soldCount:
                                        widget.showProgressBar
                                            ? (product['sold'] as int? ?? 0)
                                            : null,
                                    totalCount:
                                        widget.showProgressBar
                                            ? ((product['sold'] as int? ?? 0) +
                                                (product['sale_count_left']
                                                        as int? ??
                                                    1))
                                            : null,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }
                  },
                ),
              ),

              // Only show dots if there are multiple pages
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalPages, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _currentPage == index
                                  ? AppColors.primary
                                  : Colors.grey[300],
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
