import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/controller/home_controller.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/widget/header.dart';
import 'package:martfury/src/view/widget/product_slider.dart';
import 'package:martfury/src/view/widget/countdown_timer.dart';
import 'package:martfury/src/view/widget/recently_viewed_slider.dart';
import 'package:martfury/src/view/widget/product_card.dart';
import 'package:martfury/src/service/product_service.dart';
import 'package:martfury/src/model/category.dart';
import 'package:martfury/src/model/brand.dart';
import 'package:martfury/src/view/screen/product_detail_screen.dart';
import 'package:martfury/src/view/screen/product_screen.dart';
import 'package:martfury/src/view/screen/main_screen.dart';
import 'package:martfury/src/view/screen/webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _categoriesPageController = PageController();
  bool _isHeaderCollapsed = false;
  int _currentCategoryPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _categoriesPageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = true;
      });
    } else if (_scrollController.offset <= 100 && _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = false;
      });
    }
  }

  void _navigateToProduct(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    await ProductService.addToRecentlyViewed({
      'id': product['id'],
      'slug': product['slug'],
      'image':
          product['image_with_sizes']?['small']?[0] ??
          product['image_url'] ??
          '',
    });

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ProductDetailScreen(product: {'slug': product['slug']}),
        ),
      );
    }
  }

  Widget _buildCategorySection(
    BuildContext context,
    HomeController controller,
    Category category,
  ) {
    final products = controller.categoryProducts[category.id] ?? [];

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    final productMaps =
        products
            .map(
              (product) => {
                'id': product.id,
                'slug': product.slug,
                'imageUrl': product.imageUrl,
                'title': product.name,
                'price': product.price,
                'originalPrice': product.originalPrice,
                'rating': product.reviewsAvg,
                'reviews': product.reviewsCount,
                'seller': product.store?.name,
                'url': product.slug,
                'priceFormatted': product.priceFormatted,
                'originalPriceFormatted': product.originalPriceFormatted,
                'onTap': () {
                  _navigateToProduct(context, {
                    'id': product.id,
                    'slug': product.slug,
                    'image_with_sizes': product.imageWithSizes?.toJson(),
                    'image_url': product.imageUrl,
                  });
                },
              },
            )
            .toList();

    return ProductSlider(
      title: category.name,
      products: productMaps,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductScreen(categoryId: category.id),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedCategoriesSection(
    BuildContext context,
    HomeController controller,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildFeaturedCategoriesSkeleton();
      }

      if (controller.featuredCategories.isEmpty) {
        return const SizedBox.shrink();
      }

      final totalPages = (controller.featuredCategories.length / 6).ceil();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('home.featured_categories'),
                  style: kAppTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getPrimaryTextColor(context),
                  ),
                ),
                if (totalPages > 1)
                  Text(
                    '${_currentCategoryPage + 1}/$totalPages',
                    style: kAppTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 280,

            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PageView.builder(
              controller: _categoriesPageController,
              itemCount: totalPages,
              onPageChanged: (page) {
                setState(() {
                  _currentCategoryPage = page;
                });
              },
              itemBuilder: (context, pageIndex) {
                final startIndex = pageIndex * 6;
                final endIndex = (startIndex + 6).clamp(
                  0,
                  controller.featuredCategories.length,
                );
                final pageCategories = controller.featuredCategories.sublist(
                  startIndex,
                  endIndex,
                );

                return GridView.builder(
                  padding: const EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: pageCategories.length,
                  itemBuilder: (context, index) {
                    final category = pageCategories[index];
                    return _buildFeaturedCategoryCard(context, category);
                  },
                );
              },
            ),
          ),
          if (totalPages > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalPages,
                (index) => GestureDetector(
                  onTap: () {
                    _categoriesPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentCategoryPage == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color:
                          _currentCategoryPage == index
                              ? AppColors.primary
                              : AppColors.getBorderColor(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildFeaturedCategoryCard(BuildContext context, Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MainScreen(
                  initialIndex: 2,
                  productScreen: ProductScreen(
                    categoryId: category.id,
                    categoryName: category.name,
                  ),
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    category.imageWithSizes?.medium != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            category.imageWithSizes!.medium,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.getSurfaceColor(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.category_outlined,
                                  size: 32,
                                  color: AppColors.getHintTextColor(context),
                                ),
                              );
                            },
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            size: 32,
                            color: AppColors.getHintTextColor(context),
                          ),
                        ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Text(
                  category.name,
                  style: kAppTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBrandsSection(
    BuildContext context,
    HomeController controller,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildFeaturedBrandsSkeleton();
      }

      if (controller.featuredBrands.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              context.tr('home.featured_brands'),
              style: kAppTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.getPrimaryTextColor(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.featuredBrands.length,
              itemBuilder: (context, index) {
                final brand = controller.featuredBrands[index];
                return _buildFeaturedBrandCard(context, brand);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFeaturedBrandCard(BuildContext context, Brand brand) {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MainScreen(
                  initialIndex: 2,
                  productScreen: ProductScreen(
                    brandId: brand.id,
                    brandName: brand.name,
                  ),
                ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: EdgeInsets.only(
          right: isRtl ? 0.0 : 12.0,
          left: isRtl ? 12.0 : 0.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child:
            brand.logo != null && brand.logo!.isNotEmpty
                ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.network(
                    brand.logo!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          brand.name,
                          style: kAppTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                )
                : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      brand.name,
                      style: kAppTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildFeaturedBrandsSkeleton() {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 24,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5, // Show 5 skeleton items
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(
                  right: isRtl ? 0.0 : 12.0,
                  left: isRtl ? 12.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.getBorderColor(context),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCategoriesSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 24,
                width: 180,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                height: 16,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 320,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: 6, // Show 6 skeleton items (2 rows × 3 columns)
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.getBorderColor(context),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.getSkeletonColor(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Flexible(
                              child: Container(
                                height: 8,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.getSkeletonColor(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == 0 ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color:
                    index == 0
                        ? AppColors.getHintTextColor(context)
                        : AppColors.getBorderColor(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashSaleSection(
    BuildContext context,
    HomeController controller,
  ) {
    if (controller.flashSaleProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final int totalFlashSalePages =
        (controller.flashSaleProducts.length / 2).ceil();
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: totalFlashSalePages,
              itemBuilder: (context, pageIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: List.generate(2, (index) {
                      final productIndex = pageIndex * 2 + index;
                      if (productIndex >= controller.flashSaleProducts.length) {
                        return const Spacer();
                      }

                      final product =
                          controller.flashSaleProducts[productIndex];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: isRtl
                                ? (index == 1 ? 8.0 : 0.0)
                                : (index == 0 ? 8.0 : 0.0),
                            left: isRtl
                                ? (index == 0 ? 8.0 : 0.0)
                                : (index == 1 ? 8.0 : 0.0),
                          ),
                          child: ProductCard(
                            imageUrl: product['image_with_sizes']?['origin']?[0] ?? '',
                            title: product['name'] ?? '',
                            price: (product['price'] as num?)?.toDouble() ?? 0.0,
                            originalPrice: (product['original_price'] as num?)?.toDouble() ?? 0.0,
                            priceFormatted: product['price_formatted'] ?? '\$${(product['price'] ?? 0).toStringAsFixed(2)}',
                            originalPriceFormatted: product['original_price_formatted'] ?? '\$${(product['original_price'] ?? 0).toStringAsFixed(2)}',
                            rating: (product['reviews_avg'] as num?)?.toDouble(),
                            reviewsCount: product['reviews_count'] as int? ?? 0,
                            seller: product['store']?['name'] as String?,
                            layout: ProductCardLayout.grid,
                            onTap: () => _navigateToProduct(context, product),
                            showProgressBar: true,
                            soldCount: int.tryParse(product['sold']?.toString() ?? '0') ?? 0,
                            totalCount: (int.tryParse(product['sold']?.toString() ?? '0') ?? 0) +
                                       (int.tryParse(product['sale_count_left']?.toString() ?? '1') ?? 1),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsSection(BuildContext context, HomeController controller) {
    if (controller.adsLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    // Don't show error message, just hide the ads section if there's an error or no ads
    if (controller.adsError.value != null || controller.ads.isEmpty) {
      return const SizedBox.shrink();
    }

    final ads = controller.ads;
    final isOddLength = ads.length % 2 == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // If odd length, show first ad as large image
          if (isOddLength && ads.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: GestureDetector(
                onTap: () {
                  if (ads[0].link != null && ads[0].link!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => WebViewScreen(
                              url: ads[0].link!,
                              title: ads[0].name,
                            ),
                      ),
                    );
                  }
                },
                child: Image.network(
                  ads[0].image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ],

          // Build rows of small ads
          ..._buildSmallAdsRows(context, ads, isOddLength ? 1 : 0),
        ],
      ),
    );
  }

  List<Widget> _buildSmallAdsRows(
    BuildContext context,
    List<dynamic> ads,
    int startIndex,
  ) {
    final List<Widget> rows = [];
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    for (int i = startIndex; i < ads.length; i += 2) {
      final hasSecondAd = i + 1 < ads.length;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              // First ad in the row
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: isRtl ? 0.0 : 4.0,
                    left: isRtl ? 4.0 : 0.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (ads[i].link != null && ads[i].link!.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => WebViewScreen(
                                  url: ads[i].link!,
                                  title: ads[i].name,
                                ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 96, // Fixed height for all small ads
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceColor(context),
                      ),
                      child: Image.network(
                        ads[i].image,
                        fit: BoxFit.cover, // Changed from contain to cover
                        width: double.infinity,
                        height: 96,
                      ),
                    ),
                  ),
                ),
              ),
              // Second ad in the row (if exists)
              if (hasSecondAd)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isRtl ? 0.0 : 4.0,
                      right: isRtl ? 4.0 : 0.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (ads[i + 1].link != null &&
                            ads[i + 1].link!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => WebViewScreen(
                                    url: ads[i + 1].link!,
                                    title: ads[i + 1].name,
                                  ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 96, // Fixed height for all small ads
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(context),
                        ),
                        child: Image.network(
                          ads[i + 1].image,
                          fit: BoxFit.cover, // Changed from contain to cover
                          width: double.infinity,
                          height: 96,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdsSkeletonSection(),
          const SizedBox(height: 16),
          _buildFeaturedCategoriesSkeleton(),
          const SizedBox(height: 16),
          _buildFeaturedBrandsSkeleton(),
          const SizedBox(height: 16),
          _buildFlashSaleSkeletonSection(),
          _buildCategorySkeletonSection(),
          _buildCategorySkeletonSection(),
          _buildCategorySkeletonSection(),
          _buildRecentlyViewedSkeletonSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAdsSkeletonSection() {
    // Get the number of ad keys to determine skeleton layout
    final adKeys = AppConfig.adKeys;
    if (adKeys == null || adKeys.isEmpty) {
      return const SizedBox.shrink(); // No ads configured, no skeleton
    }

    final isOddLength = adKeys.length % 2 == 1;
    final smallAdsCount = isOddLength ? adKeys.length - 1 : adKeys.length;
    final smallAdsRows = (smallAdsCount / 2).ceil();
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Large ad placeholder (only if odd number of ads)
          if (isOddLength) ...[
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.getSkeletonColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Small ads rows
          ...List.generate(smallAdsRows, (rowIndex) {
            final startIndex = rowIndex * 2;
            final hasSecondAd = startIndex + 1 < smallAdsCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  // First ad in the row
                  Expanded(
                    child: Container(
                      height: 96,
                      margin: EdgeInsets.only(
                        right: isRtl ? 0.0 : 4.0,
                        left: isRtl ? 4.0 : 0.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Second ad in the row (if exists)
                  if (hasSecondAd)
                    Expanded(
                      child: Container(
                        height: 96,
                        margin: EdgeInsets.only(
                          left: isRtl ? 0.0 : 4.0,
                          right: isRtl ? 4.0 : 0.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFlashSaleSkeletonSection() {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Column(
      children: [
        // Flash sale header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        // Flash sale products
        SizedBox(
          height: 295,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: isRtl ? 0.0 : 8.0,
                      left: isRtl ? 8.0 : 0.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getCardBackgroundColor(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getSkeletonColor(
                            context,
                          ).withValues(alpha: 0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image placeholder
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.getSkeletonColor(context),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Product title
                                Container(
                                  width: double.infinity,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.getSkeletonColor(context),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Price
                                Container(
                                  width: 70,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.getSkeletonColor(context),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Progress bar
                                Container(
                                  width: double.infinity,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.getSkeletonColor(context),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: isRtl ? 0.0 : 8.0,
                      right: isRtl ? 8.0 : 0.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getCardBackgroundColor(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getSkeletonColor(
                            context,
                          ).withValues(alpha: 0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image placeholder
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.getSkeletonColor(context),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Product title
                                Container(
                                  width: double.infinity,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.getSkeletonColor(context),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Price
                                Container(
                                  width: 70,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.getSkeletonColor(context),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Progress bar
                                Container(
                                  width: double.infinity,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.getSkeletonColor(context),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySkeletonSection() {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 150,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        // Product slider
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: isRtl ? 0.0 : 12.0,
                  left: isRtl ? 12.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getSkeletonColor(
                        context,
                      ).withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image placeholder
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product title
                          Container(
                            width: double.infinity,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Product title second line
                          Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Price
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Rating
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyViewedSkeletonSection() {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recently viewed header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        // Recently viewed products
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: EdgeInsets.only(
                  right: isRtl ? 0.0 : 12.0,
                  left: isRtl ? 12.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getSkeletonColor(
                        context,
                      ).withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Product image placeholder
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Product title
                            Flexible(
                              child: Container(
                                width: double.infinity,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.getSkeletonColor(context),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Price
                            Flexible(
                              child: Container(
                                width: 50,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.getSkeletonColor(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Column(
      children: [
        Header(isCollapsed: _isHeaderCollapsed),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingState();
            }

            if (controller.error.value != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('home.error_loading'),
                      style: kAppTextStyle(
                        fontSize: 16,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      controller.error.value.toString(),
                      style: kAppTextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: controller.loadAllData,
                      child: Text(context.tr('common.retry')),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadAllData,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdsSection(context, controller),
                    _buildFeaturedCategoriesSection(context, controller),
                    const SizedBox(height: 16),
                    _buildFeaturedBrandsSection(context, controller),
                    const SizedBox(height: 16),
                    if (controller.flashSaleProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.flashSaleName.value,
                              style: kAppTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Obx(
                              () =>
                                  controller.flashSaleEndTime.value != null
                                      ? CountdownTimer(
                                        endTime:
                                            controller.flashSaleEndTime.value!,
                                      )
                                      : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      _buildFlashSaleSection(context, controller),
                    ],
                    Obx(
                      () => Column(
                        children:
                            controller.featuredCategories
                                .map(
                                  (category) => _buildCategorySection(
                                    context,
                                    controller,
                                    category,
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const RecentlyViewedSlider(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
