import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:martfury/src/model/product.dart';
import 'package:martfury/src/service/product_service.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/filter_screen.dart';
import 'package:martfury/src/view/screen/product_detail_screen.dart';
import 'package:martfury/src/view/screen/main_screen.dart';
import 'package:martfury/src/view/screen/cart_screen.dart';
import 'package:martfury/src/view/widget/product_card.dart';

class ProductScreen extends StatefulWidget {
  final int? categoryId;
  final int? brandId;

  final String? categoryName;
  final String? brandName;

  const ProductScreen({
    super.key,
    this.categoryId,
    this.brandId,
    this.categoryName,
    this.brandName,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final Map<String, String> _sortOptions = {
    'default_sorting': 'explorer.default_sorting'.tr(),
    'price_asc': 'explorer.price_asc'.tr(),
    'price_desc': 'explorer.price_desc'.tr(),
    'date_desc': 'explorer.date_desc'.tr(),
    'date_asc': 'explorer.date_asc'.tr(),
    'name_asc': 'explorer.name_asc'.tr(),
    'name_desc': 'explorer.name_desc'.tr(),
    'rating_asc': 'explorer.rating_asc'.tr(),
    'rating_desc': 'explorer.rating_desc'.tr(),
  };
  bool _isGridView = true;
  String _sortBy = 'default_sorting';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<Product> _products = [];
  final ProductService _productService = ProductService();
  Map<String, dynamic> _filterParams = {};
  String? _title;
  int _totalProducts = 0;
  int _cartCount = 0;
  StreamSubscription<int>? _cartCountSubscription;
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _filterParams['categories'] = [widget.categoryId];
    }
    if (widget.brandId != null) {
      _filterParams['brands'] = [widget.brandId];
    }

    _fetchProducts();
    _title = widget.categoryName ?? widget.brandName ?? 'explorer.title'.tr();
    _loadCartCount();
    _setupCartCountListener();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _cartCountSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    final count = await CartService.getCartCount();
    if (mounted) {
      setState(() {
        _cartCount = count;
      });
    }
  }

  void _setupCartCountListener() {
    _cartCountSubscription = CartService.cartCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _cartCount = count;
        });
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more when user is 200px from bottom
        _loadMoreProducts();
      }
    });
  }

  Future<void> _fetchProducts({bool reset = true}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 1;
        });
      }

      Map<String, dynamic> response = await _productService.getAllProducts(
        filter: _filterParams,
        order: _sortBy,
        page: reset ? 1 : _currentPage,
      );

      List<Product> products = response['data'];

      Map<String, dynamic> meta = response['meta'];
      int totalProducts = meta['total'] ?? products.length;
      int lastPage = meta['last_page'] ?? 1;

      if (mounted) {
        setState(() {
          if (reset) {
            _products = products;
          } else {
            _products.addAll(products);
          }
          _totalProducts = totalProducts;
          _lastPage = lastPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _fetchProducts(reset: false);
  }

  /// Check if any filters are currently active (excluding initial category/brand)
  bool get _hasActiveFilters {
    if (_filterParams.isEmpty) return false;

    // Count active filter types
    int activeFilters = 0;

    // Check for price filters
    if (_filterParams.containsKey('min_price') ||
        _filterParams.containsKey('max_price')) {
      activeFilters++;
    }

    // Check for other filter types
    _filterParams.forEach((key, value) {
      if (key != 'min_price' && key != 'max_price') {
        if (value is List && value.isNotEmpty) {
          // Don't count initial category/brand as active filters
          if (key == 'categories' &&
              widget.categoryId != null &&
              value.length == 1 &&
              value[0] == widget.categoryId) {
            return;
          }
          if (key == 'brands' &&
              widget.brandId != null &&
              value.length == 1 &&
              value[0] == widget.brandId) {
            return;
          }
          activeFilters++;
        }
      }
    });

    return activeFilters > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading:
            (widget.categoryId != null || widget.brandId != null)
                ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    // Try to pop first, if that fails, navigate to home
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const MainScreen(initialIndex: 0),
                        ),
                      );
                    }
                  },
                )
                : null,
        title: Text(
          _title ?? 'explorer.title'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          // Cart icon with badge
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/images/icons/cart.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: isRtl ? null : 6,
                  left: isRtl ? 6 : null,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _cartCount.toString(),
                      style: kAppTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Notification bell icon
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/icons/bell-solid.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notifications feature coming soon!',
                    style: kAppTextStyle(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Main filter and sort bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.getSurfaceColor(context),
            child: Column(
              children: [
                Row(
                  children: [
                    // Filter button with indicator
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final categoryId =
                              _filterParams['categories'] != null
                                  ? int.parse(
                                    _filterParams['categories'][0].toString(),
                                  )
                                  : widget.categoryId;

                          final filterParams = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FilterScreen(
                                    categoryId: categoryId,
                                    brandId: widget.brandId,
                                  ),
                            ),
                          );

                          if (filterParams != null) {
                            setState(() {
                              _filterParams = filterParams;
                              _title = 'explorer.title'.tr();
                            });
                            _fetchProducts();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/icons/filter-solid.svg',
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                Colors.grey.shade600,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter',
                              style: kAppTextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort dropdown
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            isDense: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            items:
                                _sortOptions.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Sort by: ${entry.value}',
                                        style: kAppTextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                          height: 1.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortBy = newValue;
                                });
                                _fetchProducts();
                              }
                            },
                            selectedItemBuilder: (BuildContext context) {
                              return _sortOptions.entries.map((entry) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Sort by: ${entry.value}',
                                    style: kAppTextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // View toggle buttons
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Grid view button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isGridView = true;
                              });
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/icons/th-solid.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  _isGridView
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          // List view button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isGridView = false;
                              });
                            },
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/icons/bars-solid.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  !_isGridView
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Results count
                if (!_isLoading && _error == null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'explorer.results_count'.tr(
                          namedArgs: {'count': _totalProducts.toString()},
                        ),
                        style: kAppTextStyle(
                          fontSize: 13,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                      if (_hasActiveFilters)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              // Keep only initial category/brand filters
                              _filterParams.clear();
                              if (widget.categoryId != null) {
                                _filterParams['categories'] = [
                                  widget.categoryId,
                                ];
                              }
                              if (widget.brandId != null) {
                                _filterParams['brands'] = [widget.brandId];
                              }
                              _title =
                                  widget.categoryName ??
                                  widget.brandName ??
                                  'explorer.title'.tr();
                            });
                            _fetchProducts();
                          },
                          child: Text(
                            'explorer.clear_filters'.tr(),
                            style: kAppTextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchProducts(),
              child:
                  _isLoading
                      ? _buildLoadingState()
                      : _error != null
                      ? _buildErrorState()
                      : _products.isEmpty
                      ? _buildEmptyState()
                      : _isGridView
                      ? _buildGridView()
                      : _buildListView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'explorer.error_loading'.tr(),
                style: kAppTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: kAppTextStyle(
                  fontSize: 14,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'explorer.retry'.tr(),
                  style: kAppTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Text(
            'explorer.no_products'.tr(),
            style: kAppTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.getSecondaryTextColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62, // Adjusted for better content display
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount:
          _products.length +
          (_isLoadingMore ? 2 : 0), // Add 2 skeleton items when loading more
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          // Show skeleton loading for additional items
          return _buildProductCardSkeleton();
        }

        final product = _products[index];

        return ProductCard(
          imageUrl: product.imageUrl,
          title: product.name,
          price: product.price,
          priceFormatted: product.priceFormatted,
          originalPriceFormatted: product.originalPriceFormatted,
          originalPrice: product.originalPrice ?? 0,
          seller: product.store?.name,
          rating: product.reviewsAvg,
          reviewsCount: product.reviewsCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ProductDetailScreen(product: {'slug': product.slug}),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          _products.length +
          (_isLoadingMore ? 1 : 0), // Add 1 skeleton item when loading more
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          // Show skeleton loading for additional items
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildProductCardSkeleton(),
          );
        }

        final product = _products[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ProductCard(
            imageUrl: product.imageUrl,
            title: product.name,
            price: product.price,
            originalPrice: product.originalPrice ?? 0,
            priceFormatted: product.priceFormatted,
            originalPriceFormatted: product.originalPriceFormatted,
            rating: product.reviewsAvg,
            reviewsCount: product.reviewsCount,
            seller: product.store?.name,
            layout: ProductCardLayout.list,
            height: 120,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ProductDetailScreen(product: {'slug': product.slug}),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return _isGridView ? _buildGridSkeleton() : _buildListSkeleton();
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62, // Match the actual grid aspect ratio
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) => _buildProductCardSkeleton(),
    );
  }

  Widget _buildListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4, // Show 4 skeleton items
      itemBuilder:
          (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildProductCardSkeleton(),
          ),
    );
  }

  Widget _buildProductCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Container(
              width: double.infinity,
              height: _isGridView ? 120 : 100,
              color: AppColors.getSkeletonColor(context),
            ),
          ),
          // Content skeleton
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                // Price skeleton
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                // Original price skeleton
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                // Rating skeleton
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 30,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Seller skeleton
                Container(
                  width: 70,
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
  }
}
