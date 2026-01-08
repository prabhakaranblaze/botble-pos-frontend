import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:martfury/src/service/product_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/product_detail_screen.dart';

class RecentlyViewedSlider extends StatefulWidget {
  const RecentlyViewedSlider({super.key});

  @override
  State<RecentlyViewedSlider> createState() => RecentlyViewedSliderState();
}

class RecentlyViewedSliderState extends State<RecentlyViewedSlider> {
  List<Map<String, dynamic>> _recentlyViewed = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    loadRecentlyViewed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final itemWidth = (MediaQuery.of(context).size.width - 32 - 24) / 3;
    final page = (_scrollController.offset / (itemWidth + 12)).round();

    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Future<void> loadRecentlyViewed() async {
    final products = await ProductService.getRecentlyViewed();

    if (mounted) {
      setState(() {
        _recentlyViewed = products;
      });
    }
  }

  void _navigateToProduct(Map<String, dynamic> product) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ProductDetailScreen(product: {'slug': product['slug']}),
      ),
    );

    if (shouldRefresh == true && mounted) {
      loadRecentlyViewed();
    }
  }

  void _scrollToPage(int page) {
    if (!_scrollController.hasClients) return;

    final itemWidth = (MediaQuery.of(context).size.width - 32 - 24) / 3;
    final offset = page * (itemWidth + 12);

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_recentlyViewed.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate item width based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth =
        (screenWidth - 32 - 24) / 3; // Subtracting padding and spacing
    final totalPages = (_recentlyViewed.length / 3).ceil();
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'common.recently_viewed'.tr(),
                style: kAppTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: _recentlyViewed.length,
            itemBuilder: (context, index) {
              final product = _recentlyViewed[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: isRtl ? 0.0 : 12.0,
                  left: isRtl ? 12.0 : 0.0,
                ),
                child: GestureDetector(
                  onTap: () => _navigateToProduct(product),
                  child: Container(
                    width: itemWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.getBorderColor(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      product['image'],
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
              );
            },
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                return GestureDetector(
                  onTap: () => _scrollToPage(index),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentPage == index
                              ? AppColors.primary
                              : AppColors.getBorderColor(context),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
