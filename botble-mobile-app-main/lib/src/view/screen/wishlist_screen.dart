import 'package:flutter/material.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/product_detail_screen.dart';
import 'dart:async';
import 'package:martfury/src/service/wishlist_service.dart';
import 'package:martfury/src/view/widget/product_card.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => WishlistScreenState();
}

class WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> _wishlistItems = [];
  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    loadWishlist();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      loadWishlist();
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      await _wishlistService.removeFromWishlist(productId);
      await loadWishlist();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'wishlist.item_removed_from_wishlist'.tr(),
            style: kAppTextStyle(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'wishlist.failed_to_remove_item'.tr(),
            style: kAppTextStyle(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addToCart(String productId) async {
    try {
      await _cartService.createCartItem(productId: productId, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'wishlist.item_added_to_cart'.tr(),
            style: kAppTextStyle(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'wishlist.failed_to_add_item_to_cart'.tr(),
            style: kAppTextStyle(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> loadWishlist() async {
    try {
      final response = await _wishlistService.getWishlist();

      if (mounted) {
        setState(() {
          _wishlistItems =
              response['items'].isNotEmpty
                  ? response['items'].values.toList()
                  : [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'wishlist.wishlist'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadWishlist,
              child:
                  _wishlistItems.isEmpty
                      ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite_border,
                                      size: 64,
                                      color: AppColors.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'wishlist.empty_wishlist'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getPrimaryTextColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'wishlist.add_products_to_wishlist'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 14,
                                        color: AppColors.getSecondaryTextColor(
                                          context,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.56,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _wishlistItems.length,
                        itemBuilder: (context, index) {
                          final item = _wishlistItems[index];
                          return Column(
                            children: [
                              Expanded(
                                child: ProductCard(
                                  imageUrl: item['image_url'],
                                  title: item['name'],
                                  price:
                                      (item['price'] as num?)?.toDouble() ??
                                      0.0,
                                  originalPrice:
                                      (item['original_price'] as num?)
                                          ?.toDouble() ??
                                      0.0,
                                  priceFormatted: item['price_formatted'],
                                  originalPriceFormatted:
                                      item['original_price_formatted'],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ProductDetailScreen(
                                              product: {'slug': item['slug']},
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _removeFromWishlist(
                                            item['id'].toString(),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.getBorderColor(
                                              context,
                                            ),
                                          ),
                                          backgroundColor:
                                              AppColors.getSurfaceColor(
                                                context,
                                              ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'wishlist.remove'.tr(),
                                          style: kAppTextStyle(
                                            color:
                                                AppColors.getPrimaryTextColor(
                                                  context,
                                                ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        _addToCart(item['id'].toString());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/icons/cart.svg',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
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
    );
  }
}
