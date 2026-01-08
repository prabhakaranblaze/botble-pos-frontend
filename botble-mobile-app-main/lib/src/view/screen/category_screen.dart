import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:martfury/src/model/category.dart';
import 'package:martfury/src/service/category_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/product_screen.dart';
import 'package:martfury/src/view/screen/search_screen.dart';
import 'package:martfury/src/view/screen/main_screen.dart';
import 'dart:ui' as ui;

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Category> _allCategories = [];
  List<Category> _parentCategories = [];
  int _selectedIndex = 0;
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _parentCategories = categories.where((c) => 
            c.parentId == null || 
            c.parentId == 0 || 
            c.parentId == '0'
          ).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Category> _getChildCategories() {
    if (_parentCategories.isEmpty) return [];
    final selectedParentId = _parentCategories[_selectedIndex].id;
    return _allCategories.where((c) {
      // Handle comparison for different types of parentId
      if (c.parentId == null) return false;
      if (c.parentId is int) return c.parentId == selectedParentId;
      if (c.parentId is String) return c.parentId == selectedParentId.toString();
      return false;
    }).toList();
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        // Left side - Categories list skeleton
        _buildLeftPanelSkeleton(),
        // Right side - Subcategories grid skeleton
        _buildRightPanelSkeleton(),
      ],
    );
  }

  Widget _buildLeftPanelSkeleton() {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.getBorderColor(context), width: 1),
        ),
      ),
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) {
          final isSelected = index == 0; // First item appears selected
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(context),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.getBorderColor(context),
                  width: 1,
                ),
                left: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              children: [
                // Category image placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                // Category name placeholder
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                // Category name second line placeholder
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
          );
        },
      ),
    );
  }

  Widget _buildRightPanelSkeleton() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          // Grid skeleton
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category image placeholder
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Category name placeholder
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Featured badge placeholder (for some items)
                      if (index % 3 == 0)
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (Directionality.of(context) == ui.TextDirection.rtl) ...[
                      // In RTL: text first, then search button on the left
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            'common.search_placeholder'.tr(),
                            style: kAppTextStyle(
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 48,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkCardBackground
                                  : Colors.black,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset(
                            'assets/images/icons/search.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // In LTR: text first, then search button on the right
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            'common.search_placeholder'.tr(),
                            style: kAppTextStyle(
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 48,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkCardBackground
                                  : Colors.black,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset(
                            'assets/images/icons/search.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading categories',
                      style: kAppTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: kAppTextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCategories,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadCategories,
                child: Row(
                  children: [
                    // Left side - Categories list
                    Container(
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border(
                          right:
                              Directionality.of(context) == ui.TextDirection.ltr
                                  ? BorderSide(
                                    color: AppColors.getBorderColor(context),
                                    width: 1,
                                  )
                                  : BorderSide.none,
                          left:
                              Directionality.of(context) == ui.TextDirection.rtl
                                  ? BorderSide(
                                    color: AppColors.getBorderColor(context),
                                    width: 1,
                                  )
                                  : BorderSide.none,
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _parentCategories.length,
                        itemBuilder: (context, index) {
                          final category = _parentCategories[index];
                          final isSelected = _selectedIndex == index;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.getSurfaceColor(context),
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.getBorderColor(context),
                                    width: 1,
                                  ),

                                  left:
                                      Directionality.of(context) ==
                                              ui.TextDirection.ltr
                                          ? BorderSide(
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : Colors.transparent,
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                  right:
                                      Directionality.of(context) ==
                                              ui.TextDirection.rtl
                                          ? BorderSide(
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : Colors.transparent,
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                ),
                              ),
                              child: Column(
                                children: [
                                  if (category.imageWithSizes != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        category.imageWithSizes!.thumb,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Icon(
                                              Icons.category,
                                              color:
                                                  isSelected
                                                      ? AppColors.primary
                                                      : AppColors.getSecondaryTextColor(
                                                        context,
                                                      ),
                                              size: 24,
                                            ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.category,
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : AppColors.getSecondaryTextColor(
                                                context,
                                              ),
                                      size: 24,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category.name,
                                    style: kAppTextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : AppColors.getSecondaryTextColor(
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
                          );
                        },
                      ),
                    ),
                    // Right side - Subcategories grid
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_parentCategories.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MainScreen(
                                            initialIndex: 2,
                                            productScreen: ProductScreen(
                                              categoryId:
                                                  _parentCategories[_selectedIndex]
                                                      .id,
                                              categoryName:
                                                  _parentCategories[_selectedIndex]
                                                      .name,
                                            ),
                                          ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _parentCategories[_selectedIndex].name,
                                      style: kAppTextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getPrimaryTextColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: _getChildCategories().length,
                              itemBuilder: (context, index) {
                                final category = _getChildCategories()[index];
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
                                      color: AppColors.getCardBackgroundColor(
                                        context,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (category.imageWithSizes != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              category.imageWithSizes!.small,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) => Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.getSkeletonColor(
                                                            context,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.category,
                                                      size: 32,
                                                      color:
                                                          AppColors.getSecondaryTextColor(
                                                            context,
                                                          ),
                                                    ),
                                                  ),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: AppColors.getSkeletonColor(
                                                context,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.category,
                                              size: 32,
                                              color:
                                                  AppColors.getSecondaryTextColor(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            category.name,
                                            style: kAppTextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  AppColors.getPrimaryTextColor(
                                                    context,
                                                  ),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (category.isFeatured) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withAlpha(10),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'category.featured'.tr(),
                                              style: kAppTextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
