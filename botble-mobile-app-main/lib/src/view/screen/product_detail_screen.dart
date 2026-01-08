import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:martfury/src/service/product_service.dart';
import 'package:martfury/src/model/review.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/utils/back_button_handler.dart';
import 'package:martfury/src/view/screen/cart_screen.dart';
import 'package:martfury/src/view/screen/checkout_screen.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'package:martfury/src/service/wishlist_service.dart';
import 'package:martfury/src/service/currency_change_service.dart';
import 'package:martfury/src/service/language_change_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:martfury/src/view/screen/sign_in_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:martfury/src/service/compare_service.dart';
import 'package:martfury/src/view/screen/product_screen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:martfury/src/view/screen/main_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:martfury/src/service/analytics_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  final PageController _pageController = PageController();
  int _selectedRating = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsKey = GlobalKey();
  bool _isScrolled = false;
  bool _isLoading = true;
  final bool _isAttributeLoading = false;
  bool _isAddingToCart = false;
  bool _isBuyingNow = false;
  bool _isSubmittingReview = false;
  final TextEditingController _reviewCommentController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _isEditingQuantity = false;
  final FocusNode _quantityFocusNode = FocusNode();
  Map<String, dynamic> _productDetail = {};
  List<dynamic> _attributeSets = [];
  final Map<String, Map<String, dynamic>> _selectedAttributes = {};
  List<String> _productImages = [];
  Map<String, String> _attributeErrors = {};
  List<Map<String, dynamic>> _relatedProducts = [];
  String _error = '';
  int _cartCount = 0;
  List<int> _unavailableAttributeIds = [];
  StreamSubscription<String>? _currencyChangeSubscription;
  StreamSubscription<String>? _languageChangeSubscription;
  bool _isValidatingAttributes = false;
  final ProductService _productService = ProductService();
  List<Review> _reviews = [];
  bool _hasReviewed = false;
  bool _isWishlisted = false;
  bool _isLoadingReviews = true;
  String? _reviewError;
  final CartService _cartService = CartService();
  bool _isAddingToWishlist = false;
  bool _isRemovingFromWishlist = false;
  final WishlistService _wishlistService = WishlistService();
  final CompareService _compareService = CompareService();
  bool _isAddingToCompare = false;
  bool _isLoggedIn = false;
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _quantityController.text = _quantity.toString();
    _quantityFocusNode.addListener(_onQuantityFocusChanged);
    _loadProductDetail();
    _loadWishlist();
    _loadCartCount();
    _loadReviews();
    _checkLoginStatus();
    _setupCurrencyChangeListener();
    _setupLanguageChangeListener();

    _logProductView();
  }

  void _logProductView() {
    final product = widget.product;
    AnalyticsService.logViewItem(
      currency: product['currency'] ?? 'USD',
      value: double.tryParse(product['price']?.toString() ?? '0'),
      items: [
        AnalyticsService.createItem(
          itemId: product['id']?.toString(),
          itemName: product['name'],
          itemCategory: product['category']?['name'],
          price: double.tryParse(product['price']?.toString() ?? '0'),
          quantity: 1,
        ),
      ],
    );
    AnalyticsService.logScreenView(screenName: 'ProductDetail');
  }

  Future<void> _checkLoginStatus() async {
    final token = await TokenService.getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
      });
    }
  }

  Future<void> _loadCartCount() async {
    final count = await CartService.getCartCount();
    if (mounted) {
      setState(() {
        _cartCount = count;
      });
    }
  }

  void _setupCurrencyChangeListener() {
    _currencyChangeSubscription = CurrencyChangeService.currencyChangeStream
        .listen((newCurrency) {
          if (mounted) {
            _loadProductDetail();
          }
        });
  }

  void _setupLanguageChangeListener() {
    _languageChangeSubscription = LanguageChangeService.languageChangeStream
        .listen((newLanguage) {
          if (mounted) {
            _loadProductDetail();
          }
        });
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String productSlug = widget.product['slug'].toString();

      final productDetail = await _productService.getProductDetail(productSlug);

      final relatedProducts = await _productService.getRelatedProducts(
        productSlug,
      );

      if (mounted) {
        setState(() {
          if (productDetail['data'] != null) {
            _productDetail = productDetail['data'] as Map<String, dynamic>;

            if (productDetail['attribute_sets'] != null) {
              _attributeSets =
                  productDetail['attribute_sets'] as List<dynamic>? ?? [];
            } else if (_productDetail['attribute_sets'] != null) {
              _attributeSets =
                  _productDetail['attribute_sets'] as List<dynamic>? ?? [];
            } else {
              _attributeSets = [];
            }

            final imageWithSizes =
                _productDetail['image_with_sizes'] as Map<String, dynamic>?;
            if (imageWithSizes != null) {
              _productImages = List<String>.from(
                (imageWithSizes['origin'] as List<dynamic>?) ?? [],
              );
            }

            if (_productDetail['reviews_avg'] != null) {
              _productDetail['reviews_avg'] =
                  (_productDetail['reviews_avg'] is int)
                      ? (_productDetail['reviews_avg'] as int).toDouble()
                      : _productDetail['reviews_avg'] as double;
            }

            if (_productDetail['price'] != null) {
              _productDetail['price'] =
                  (_productDetail['price'] is int)
                      ? (_productDetail['price'] as int).toDouble()
                      : _productDetail['price'] as double;
            }

            if (_productDetail['original_price'] != null) {
              _productDetail['original_price'] =
                  (_productDetail['original_price'] is int)
                      ? (_productDetail['original_price'] as int).toDouble()
                      : _productDetail['original_price'] as double;
            }

            if (productDetail['unavailable_attribute_ids'] != null) {
              _unavailableAttributeIds = List<int>.from(
                productDetail['unavailable_attribute_ids'] as List<dynamic>,
              );
            }

            if (productDetail['selected_attributes'] != null) {
              for (final attribute
                  in productDetail['selected_attributes'] as List<dynamic>) {
                if (attribute['attribute_set'] != null) {
                  final setId =
                      attribute['attribute_set']['id']?.toString() ?? '';
                  if (setId.isNotEmpty) {
                    _selectedAttributes[setId] = {
                      'id': attribute['id'],
                      'title': attribute['title'],
                      'color': attribute['color'],
                      'image': attribute['image'],
                      'slug': attribute['slug'],
                    };
                  }
                }
              }
            }
          }
          _relatedProducts = relatedProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load product details: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadWishlist() async {
    final response = await _wishlistService.getWishlist();

    if (mounted) {
      setState(() {
        _isWishlisted =
            !response['items'].isEmpty &&
            response['items'].values
                .toList()
                .map((item) => item['slug'])
                .contains(widget.product['slug']);
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _reviewError = null;
    });

    try {
      final response = await _productService.getProductReviews(
        widget.product['slug'],
      );

      if (mounted) {
        setState(() {
          _reviews = List<Review>.from(
            response['reviews'].map((review) => Review.fromJson(review)),
          );
          _isLoadingReviews = false;
          _hasReviewed = response['has_reviewed'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviewError = e.toString();
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  void _onQuantityFocusChanged() {
    setState(() {
      _isEditingQuantity = _quantityFocusNode.hasFocus;
    });

    if (!_quantityFocusNode.hasFocus) {
      _validateAndUpdateQuantity();
    }
  }

  void _updateQuantity(int newQuantity) {
    final bool isOutOfStock =
        _productDetail['is_out_of_stock'] as bool? ?? false;
    final bool withStorehouseManagement =
        _productDetail['with_storehouse_management'] as bool? ?? false;
    final int maxQuantity = _productDetail['quantity'] as int? ?? 0;

    if (isOutOfStock) {
      return;
    }

    if (!withStorehouseManagement) {
      newQuantity = newQuantity.clamp(1, 1000);
    } else {
      if (maxQuantity == 0) {
        return;
      }
      newQuantity = newQuantity.clamp(1, maxQuantity);
    }

    setState(() {
      _quantity = newQuantity;
      _quantityController.text = _quantity.toString();
    });
  }

  void _onQuantityTextChanged(String value) {
    final String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanValue.isEmpty) {
      setState(() {
        _quantity = 1;
        _quantityController.text = '1';
        _quantityController.selection = TextSelection.fromPosition(
          TextPosition(offset: _quantityController.text.length),
        );
      });
      return;
    }

    final int? newQuantity = int.tryParse(cleanValue);
    if (newQuantity != null) {
      final int validQuantity = newQuantity < 1 ? 1 : newQuantity;

      setState(() {
        _quantity = validQuantity;
        if (cleanValue != value) {
          _quantityController.text = validQuantity.toString();
          _quantityController.selection = TextSelection.fromPosition(
            TextPosition(offset: _quantityController.text.length),
          );
        }
      });
    }
  }

  void _validateAndUpdateQuantity() {
    final bool isOutOfStock =
        _productDetail['is_out_of_stock'] as bool? ?? false;
    final bool withStorehouseManagement =
        _productDetail['with_storehouse_management'] as bool? ?? false;
    final int maxQuantity = _productDetail['quantity'] as int? ?? 0;

    if (isOutOfStock) return;

    int validQuantity = _quantity;

    if (_quantityController.text.isEmpty || _quantity < 1) {
      validQuantity = 1;
    }

    if (withStorehouseManagement) {
      if (maxQuantity == 0) return;
      if (_quantity > maxQuantity) {
        validQuantity = maxQuantity;
      }
    } else {
      if (_quantity > 1000) {
        validQuantity = 1000;
      }
    }

    final bool wasAdjusted = validQuantity != _quantity;

    setState(() {
      _quantity = validQuantity;
      _quantityController.text = _quantity.toString();
    });

    if (wasAdjusted) {
      String message;
      if (validQuantity == 1) {
        message = 'product.quantity_minimum_message'.tr();
      } else {
        message = 'product.quantity_adjusted_to_stock'.tr(
          namedArgs: {'quantity': validQuantity.toString()},
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.warning),
      );
    }
  }

  void _onQuantityTap() {
    final bool isOutOfStock =
        _productDetail['is_out_of_stock'] as bool? ?? false;

    if (isOutOfStock) return;

    setState(() {
      _isEditingQuantity = true;
    });
    _quantityFocusNode.requestFocus();
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _reviewCommentController.dispose();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    _currencyChangeSubscription?.cancel();
    _languageChangeSubscription?.cancel();
    super.dispose();
  }

  bool _validateAttributes() {
    final newErrors = <String, String>{};
    if (_attributeSets.isNotEmpty) {
      for (final attributeSet in _attributeSets) {
        final setId = attributeSet['id'].toString();
        if (!_selectedAttributes.containsKey(setId)) {
          newErrors[setId] = 'Please select ${attributeSet['title']}';
        }
      }
    }
    setState(() {
      _attributeErrors = newErrors;
    });
    return newErrors.isEmpty;
  }

  void _handleAttributeSelection(
    String setId,
    Map<String, dynamic> attribute,
  ) async {
    setState(() {
      _isValidatingAttributes = true;
    });

    try {
      if (_selectedAttributes[setId]?['id'] == attribute['id']) {
        _selectedAttributes.remove(setId);
      } else {
        _selectedAttributes[setId] = attribute;
      }
      _attributeErrors.remove(setId);

      if (_selectedAttributes.length == _attributeSets.length) {
        final productId = _productDetail['id'].toString();
        final attributes =
            _selectedAttributes.values
                .map((attr) => attr['id'] as int)
                .toList();

        final variation = await _productService.getProductVariation(
          int.parse(productId),
          attributes,
        );

        if (variation == null) {
          setState(() {
            _attributeErrors[setId] = 'product.out_of_stock'.tr();
          });
        } else {
          final updatedProductDetail = Map<String, dynamic>.from(
            _productDetail,
          );

          if (variation['sale_price'] != null) {
            updatedProductDetail['price'] =
                (variation['sale_price'] is int)
                    ? (variation['sale_price'] as int).toDouble()
                    : variation['sale_price'] as double;
          }

          if (variation['formatted_sale_price'] != null) {
            updatedProductDetail['price_formatted'] =
                variation['formatted_sale_price'];
          }

          if (variation['original_price'] != null) {
            updatedProductDetail['original_price'] =
                (variation['original_price'] is int)
                    ? (variation['original_price'] as int).toDouble()
                    : variation['original_price'] as double;
          }

          if (variation['formatted_original_price'] != null) {
            updatedProductDetail['original_price_formatted'] =
                variation['formatted_original_price'];
          }

          if (variation['original_price'] == null) {
            updatedProductDetail.remove('original_price');
            updatedProductDetail.remove('original_price_formatted');
          }

          if (updatedProductDetail['original_price'] != null &&
              updatedProductDetail['price'] != null) {
            final originalPrice =
                updatedProductDetail['original_price'] as double;
            final currentPrice = updatedProductDetail['price'] as double;
            if (originalPrice > currentPrice &&
                (originalPrice - currentPrice).abs() > 0.01) {
              updatedProductDetail['sale_percent'] =
                  ((originalPrice - currentPrice) / originalPrice * 100)
                      .round();
            } else {
              updatedProductDetail['sale_percent'] = null;
            }
          } else {
            updatedProductDetail['sale_percent'] = null;
          }

          List<String> updatedImages = _productImages;
          if (variation['image_with_sizes'] != null) {
            final imageWithSizes =
                variation['image_with_sizes'] as Map<String, dynamic>;
            if (imageWithSizes['origin'] != null) {
              updatedImages = List<String>.from(
                imageWithSizes['origin'] as List<dynamic>,
              );
            }
          }

          setState(() {
            _productDetail = updatedProductDetail;
            _productImages = updatedImages;
          });

          if (variation['unavailable_attribute_ids'] != null) {
            final newUnavailableIds = List<int>.from(
              variation['unavailable_attribute_ids'],
            );

            setState(() {
              _unavailableAttributeIds = newUnavailableIds;
            });

            for (final setId in _selectedAttributes.keys) {
              final selectedAttribute = _selectedAttributes[setId];
              if (selectedAttribute != null &&
                  _isAttributeUnavailable(selectedAttribute['id'] as int)) {
                final attributeSet = _attributeSets.firstWhere(
                  (set) => set['id'].toString() == setId,
                );
                final availableAttribute =
                    (attributeSet['attributes'] as List<dynamic>).firstWhere(
                      (attr) => !_isAttributeUnavailable(attr['id'] as int),
                      orElse: () => null,
                    );

                if (availableAttribute != null) {
                  _selectedAttributes[setId] = {
                    'id': availableAttribute['id'],
                    'title': availableAttribute['title'],
                    'color': availableAttribute['color'],
                    'slug': availableAttribute['slug'],
                  };
                } else {
                  _selectedAttributes.remove(setId);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update selection: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingAttributes = false;
        });
      }
    }
  }

  bool _isAttributeUnavailable(int attributeId) {
    return _unavailableAttributeIds.contains(attributeId);
  }

  String _getFormattedPrice() {
    if (_productDetail['price_formatted'] != null &&
        _productDetail['price_formatted'].toString().isNotEmpty) {
      return _productDetail['price_formatted'];
    }
    if (_productDetail['price'] != null) {
      final price = _productDetail['price'] as double;
      return '\$${price.toStringAsFixed(2)}';
    }
    return '';
  }

  String _getFormattedOriginalPrice() {
    if (_productDetail['original_price_formatted'] != null &&
        _productDetail['original_price_formatted'].toString().isNotEmpty) {
      return _productDetail['original_price_formatted'];
    }
    if (_productDetail['original_price'] != null) {
      final price = _productDetail['original_price'] as double;
      return '\$${price.toStringAsFixed(2)}';
    }
    return '';
  }

  bool _hasDiscount() {
    if (_productDetail['original_price'] == null ||
        _productDetail['price'] == null) {
      return false;
    }

    final currentPrice = _productDetail['price'] as double;
    final originalPrice = _productDetail['original_price'] as double;

    return (originalPrice - currentPrice).abs() > 0.01 &&
        originalPrice > currentPrice;
  }

  Future<void> _addToCart() async {
    if (!_validateAttributes()) {
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final productId = _productDetail['id'].toString();
      final attributes =
          _selectedAttributes.values.map((attr) => attr['id'] as int).toList();

      final variation = await _productService.getProductVariation(
        int.parse(productId),
        attributes,
      );

      if (variation == null) {
        throw Exception('product.out_of_stock'.tr());
      }

      await _cartService.createCartItem(
        productId: variation['id'].toString(),
        quantity: _quantity,
      );

      await _loadCartCount();

      await AnalyticsService.logAddToCart(
        currency: _productDetail['currency'] ?? 'USD',
        value:
            (double.tryParse(_productDetail['price']?.toString() ?? '0') ?? 0) *
            _quantity,
        items: [
          AnalyticsService.createItem(
            itemId: variation['id'].toString(),
            itemName: _productDetail['name'],
            itemCategory: _productDetail['category']?['name'],
            price: double.tryParse(_productDetail['price']?.toString() ?? '0'),
            quantity: _quantity,
          ),
        ],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.added_to_cart'.tr(), style: kAppTextStyle()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'product.failed_to_add_to_cart'.tr(),
              style: kAppTextStyle(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _buyNow() async {
    if (!_validateAttributes()) {
      return;
    }

    setState(() {
      _isBuyingNow = true;
    });

    try {
      final productId = _productDetail['id'].toString();
      final attributes =
          _selectedAttributes.values.map((attr) => attr['id'] as int).toList();
      final variation = await _productService.getProductVariation(
        int.parse(productId),
        attributes,
      );

      if (variation == null) {
        throw Exception('product.out_of_stock'.tr());
      }

      final result = await _cartService.createCartItem(
        productId: variation['id'].toString(),
        quantity: _quantity,
        skipCartCount: true,
      );

      if (result['id'] != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CheckoutScreen(cartId: result['id'].toString()),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'product.failed_to_process'.tr(),
              style: kAppTextStyle(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuyingNow = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final List<File> newImages =
            images
                .take(6 - _selectedImages.length)
                .map((xFile) => File(xFile.path))
                .toList();

        setState(() {
          _selectedImages.addAll(newImages);
        });

        if (images.length > (6 - _selectedImages.length + newImages.length)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('product.max_photos_reached'.tr()),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.failed_to_pick_images'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    FocusScope.of(context).unfocus();

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.please_select_rating'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_reviewCommentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.please_write_review'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      await _productService.submitProductReview(
        productId: _productDetail['id'] as int,
        rating: _selectedRating,
        comment: _reviewCommentController.text,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.review_submitted_successfully'.tr()),
            backgroundColor: AppColors.success,
          ),
        );

        setState(() {
          _selectedRating = 0;
          _reviewCommentController.clear();
          _selectedImages.clear();
        });

        await _loadReviews();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  Future<void> _addToWishlist() async {
    if (_productDetail.isEmpty) return;

    setState(() {
      _isAddingToWishlist = true;
    });

    try {
      await _wishlistService.createWishlist(_productDetail['id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.added_to_wishlist'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.failed_to_add_to_wishlist'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _loadWishlist();
      if (mounted) {
        setState(() {
          _isAddingToWishlist = false;
        });
      }
    }
  }

  Future<void> _removeFromWishlist() async {
    if (_productDetail.isEmpty) return;

    setState(() {
      _isRemovingFromWishlist = true;
    });

    try {
      await _wishlistService.removeFromWishlist(
        _productDetail['id'].toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.removed_from_wishlist'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.failed_to_remove_from_wishlist'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _loadWishlist();
      if (mounted) {
        setState(() {
          _isRemovingFromWishlist = false;
        });
      }
    }
  }

  Future<void> _addToCompare() async {
    if (_productDetail.isEmpty) return;

    setState(() {
      _isAddingToCompare = true;
    });

    try {
      await _compareService.createCompare(_productDetail['id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.added_to_compare'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product.failed_to_add_to_compare'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCompare = false;
        });
      }
    }
  }

  Widget _buildBottomAddToCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon:
                    _isAddingToCart
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                        : SvgPicture.asset(
                          'assets/images/icons/cart.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                label: Text(
                  'product.add_to_cart'.tr(),
                  style: kAppTextStyle(
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed:
                    _isAddingToCart ||
                            _isBuyingNow ||
                            _productDetail['is_out_of_stock'] == true
                        ? null
                        : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: AppColors.getBorderColor(context),
                    width: 1,
                  ),
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: AppColors.getSecondaryTextColor(
                    context,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isAddingToCart ||
                            _isBuyingNow ||
                            _productDetail['is_out_of_stock'] == true
                        ? null
                        : _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.getSecondaryTextColor(
                    context,
                  ),
                  disabledForegroundColor: AppColors.getSecondaryTextColor(
                    context,
                  ),
                ),
                child:
                    _isBuyingNow
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                        : Text(
                          'product.buy_now'.tr(),
                          style: kAppTextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagesSkeleton(),
              _buildProductInfoSkeleton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
        _buildBottomBarSkeleton(),
      ],
    );
  }

  Widget _buildImagesSkeleton() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.getSkeletonColor(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product title skeleton
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Brand info and action buttons row
          Row(
            children: [
              // Brand info and rating section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand skeleton
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.getSkeletonColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 5),
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
                    const SizedBox(height: 8),
                    // Rating skeleton
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: AppColors.getSkeletonColor(context),
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.getSkeletonColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons skeleton
              SizedBox(
                width: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Compare button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.getBorderColor(context),
                        ),
                        color: AppColors.getSkeletonColor(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Wishlist button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.getBorderColor(context),
                        ),
                        color: AppColors.getSkeletonColor(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Share button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.getBorderColor(context),
                        ),
                        color: AppColors.getSkeletonColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.getBorderColor(context),
          ),
          const SizedBox(height: 16),

          // Categories and SKU info rows
          _buildCategoriesSkeletonRow(),
          const SizedBox(height: 8),
          _buildInfoRowSkeleton('SKU', 120),
          const SizedBox(height: 10),

          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.getBorderColor(context),
          ),
          const SizedBox(height: 10),

          // Price skeleton
          Row(
            children: [
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stock status skeleton
          Row(
            children: [
              Container(
                width: 50,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
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

          // Short description skeleton
          const SizedBox(height: 16),
          Column(
            children: List.generate(
              3,
              (index) => Container(
                width: index == 2 ? 200 : double.infinity,
                height: 14,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.getBorderColor(context),
          ),
          const SizedBox(height: 10),

          // Attributes skeleton
          _buildAttributesSkeleton(),

          // Quantity and Add to Cart skeleton
          _buildQuantityAndCartSkeleton(),

          const SizedBox(height: 10),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.getBorderColor(context),
          ),
          const SizedBox(height: 16),

          // Store info skeleton
          _buildStoreInfoSkeleton(),

          const SizedBox(height: 16),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.getBorderColor(context),
          ),
          const SizedBox(height: 16),

          // Description section skeleton
          _buildDescriptionSkeleton(),

          const SizedBox(height: 10),

          // Reviews section skeleton
          _buildReviewsSkeleton(),
        ],
      ),
    );
  }

  Widget _buildInfoRowSkeleton(String label, double valueWidth) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: valueWidth,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSkeletonRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: List.generate(
              3,
              (index) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: [60.0, 80.0, 70.0][index],
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  if (index < 2)
                    Container(
                      width: 8,
                      height: 14,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First attribute set
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attribute title
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              // Attribute options
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  4,
                  (index) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.getBorderColor(context),
                      ),
                    ),
                    child: Container(
                      width: [50.0, 60.0, 45.0, 55.0][index],
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.getSkeletonColor(context),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Second attribute set
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attribute title
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              // Visual attribute options (circles)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.getBorderColor(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityAndCartSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantity label
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Quantity controls
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(context),
                border: Border.all(color: AppColors.getBorderColor(context)),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 20,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Add to Cart button
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreInfoSkeleton() {
    return Row(
      children: [
        // Store avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store name
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 4),
              // Store info
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
        ),
        // Visit store button
        Container(
          width: 80,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description title
        Container(
          width: 100,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        const SizedBox(height: 16),
        // Description content
        Column(
          children: List.generate(
            6,
            (index) => Container(
              width: index == 5 ? 150 : double.infinity,
              height: 14,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.getSkeletonColor(context),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews title
        Container(
          width: 120,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        const SizedBox(height: 10),
        // Divider
        Container(
          width: double.infinity,
          height: 1,
          color: AppColors.getBorderColor(context),
        ),
        const SizedBox(height: 10),
        // Rating summary
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Large rating number
            Container(
              width: 60,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.getSkeletonColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stars
                  Row(
                    children: List.generate(
                      5,
                      (index) => Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Review count
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBarSkeleton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualAttributeOption(
    Map<String, dynamic> attribute,
    bool isSelected,
    bool isUnavailable,
    bool hasError,
    String setId,
  ) {
    final String? imageUrl = attribute['image'] as String?;
    final colorString = attribute['color'] as String?;
    Color attributeColor = Colors.grey;

    if (colorString != null && colorString.isNotEmpty) {
      try {
        attributeColor = _parseColor(colorString);
      } catch (e) {
        attributeColor = Colors.grey;
      }
    }

    return Tooltip(
      message: attribute['title'] as String,
      child: GestureDetector(
        onTap:
            isUnavailable
                ? null
                : () => _handleAttributeSelection(setId, {
                  'id': attribute['id'],
                  'title': attribute['title'],
                  'color': attribute['color'],
                  'image': attribute['image'],
                  'slug': attribute['slug'],
                }),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                imageUrl == null || imageUrl.isEmpty
                    ? attributeColor.withValues(
                      alpha: isUnavailable ? 0.3 : 1.0,
                    )
                    : null,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.getPrimaryTextColor(context)
                      : isUnavailable
                      ? AppColors.getSecondaryTextColor(context)
                      : hasError
                      ? Colors.red
                      : AppColors.getBorderColor(context),
              width: isSelected ? 2 : 1,
            ),
            image:
                imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      opacity: isUnavailable ? 0.3 : 1.0,
                      onError: (exception, stackTrace) {},
                    )
                    : null,
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  )
                else if (isUnavailable)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    final trimmedColor = colorString.trim();

    if (trimmedColor.startsWith('#')) {
      return Color(int.parse('0xFF${trimmedColor.substring(1)}'));
    }

    if (trimmedColor.toLowerCase().startsWith('rgb(') &&
        trimmedColor.endsWith(')')) {
      final rgbValues =
          trimmedColor
              .substring(4, trimmedColor.length - 1) // Remove 'rgb(' and ')'
              .split(',')
              .map((value) => int.tryParse(value.trim()) ?? 0)
              .toList();

      if (rgbValues.length == 3) {
        return Color.fromRGBO(
          rgbValues[0].clamp(0, 255),
          rgbValues[1].clamp(0, 255),
          rgbValues[2].clamp(0, 255),
          1.0,
        );
      }
    }

    return Colors.grey;
  }

  Widget _buildTextAttributeOption(
    Map<String, dynamic> attribute,
    bool isSelected,
    bool isUnavailable,
    bool hasError,
    String setId,
  ) {
    return GestureDetector(
      onTap:
          isUnavailable
              ? null
              : () => _handleAttributeSelection(setId, {
                'id': attribute['id'],
                'title': attribute['title'],
                'color': attribute['color'],
                'image': attribute['image'],
                'slug': attribute['slug'],
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.getPrimaryTextColor(context)
                  : isUnavailable
                  ? AppColors.getSkeletonColor(context)
                  : AppColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.getPrimaryTextColor(context)
                    : isUnavailable
                    ? AppColors.getBorderColor(context)
                    : hasError
                    ? Colors.red
                    : AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Text(
          attribute['title'] as String,
          style: kAppTextStyle(
            color:
                isSelected
                    ? AppColors.getSurfaceColor(context)
                    : isUnavailable
                    ? AppColors.getSecondaryTextColor(context)
                    : AppColors.getPrimaryTextColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _scrollToReviews() {
    if (_reviewsKey.currentContext != null) {
      Scrollable.ensureVisible(
        _reviewsKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler.createModalPopScope(
      context: context,
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(context),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          title: Text(
            'product.back_to_shop'.tr(),
            style: kAppTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              child: Stack(
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
                    onPressed: null,
                  ),
                  if (_cartCount > 0)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getPrimaryTextColor(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _cartCount.toString(),
                          style: kAppTextStyle(
                            color: AppColors.getCardBackgroundColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        body:
            _isLoading
                ? _buildLoadingState()
                : _error.isNotEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'product.error_loading'.tr(),
                        style: kAppTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error,
                        style: kAppTextStyle(
                          fontSize: 14,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProductDetail,
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
                          'common.retry'.tr(),
                          style: kAppTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getPrimaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Images
                          AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _selectedImageIndex = index;
                                    });
                                  },
                                  itemCount: _productImages.length,
                                  itemBuilder: (context, index) {
                                    return Image.network(
                                      _productImages[index],
                                      fit: BoxFit.fitHeight,
                                    );
                                  },
                                ),

                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.getPrimaryTextColor(
                                        context,
                                      ).withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${_selectedImageIndex + 1} / ${_productImages.length}',
                                      style: kAppTextStyle(
                                        color: AppColors.getCardBackgroundColor(
                                          context,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product title
                                Text(
                                  _productDetail['name'] ?? '',
                                  style: kAppTextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getPrimaryTextColor(
                                      context,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Brand info and action buttons row
                                Row(
                                  children: [
                                    // Brand info and rating section
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_productDetail['brand']
                                                  .isNotEmpty &&
                                              _productDetail['brand']['name'] !=
                                                  null) ...[
                                            Row(
                                              children: [
                                                Text(
                                                  'product.brand'.tr(),
                                                  style: kAppTextStyle(
                                                    color:
                                                        AppColors.getSecondaryTextColor(
                                                          context,
                                                        ),
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => MainScreen(
                                                              initialIndex: 2,
                                                              productScreen:
                                                                  ProductScreen(
                                                                    brandId:
                                                                        _productDetail['brand']['id'],
                                                                    brandName:
                                                                        _productDetail['brand']['name'],
                                                                  ),
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    _productDetail['brand']['name']
                                                        .toString(),
                                                    style: kAppTextStyle(
                                                      color: AppColors.info,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          // Rating and reviews
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: _scrollToReviews,
                                                child: Row(
                                                  children: List.generate(
                                                    5,
                                                    (index) => Icon(
                                                      Icons.star,
                                                      size: 18,
                                                      color:
                                                          index <
                                                                  (_productDetail['reviews_avg'] ??
                                                                          0)
                                                                      .floor()
                                                              ? AppColors
                                                                  .primary
                                                              : AppColors.getBorderColor(
                                                                context,
                                                              ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: _scrollToReviews,
                                                child: Text(
                                                  '${_productDetail['reviews_count'] ?? 0}',
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.getSecondaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action buttons
                                    SizedBox(
                                      width:
                                          160, // Increased width for 3 buttons
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Compare button
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.getBorderColor(
                                                  context,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed:
                                                  _isAddingToCompare
                                                      ? null
                                                      : _addToCompare,
                                              icon:
                                                  _isAddingToCompare
                                                      ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.black87),
                                                        ),
                                                      )
                                                      : SvgPicture.asset(
                                                        'assets/images/icons/compare.svg',
                                                        width: 20,
                                                        height: 20,
                                                        colorFilter:
                                                            ColorFilter.mode(
                                                              AppColors.getSecondaryTextColor(
                                                                context,
                                                              ),
                                                              BlendMode.srcIn,
                                                            ),
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Wishlist button
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.getBorderColor(
                                                  context,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed:
                                                  _isAddingToWishlist ||
                                                          _isRemovingFromWishlist
                                                      ? null
                                                      : () {
                                                        if (_isWishlisted) {
                                                          _removeFromWishlist();
                                                        } else {
                                                          _addToWishlist();
                                                        }
                                                      },
                                              icon:
                                                  _isAddingToWishlist ||
                                                          _isRemovingFromWishlist
                                                      ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.red),
                                                        ),
                                                      )
                                                      : Icon(
                                                        _isWishlisted
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        color: AppColors.error,
                                                        size: 20,
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Share button
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.getBorderColor(
                                                  context,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                final String productUrl =
                                                    _productDetail['url'] ?? '';
                                                final String productName =
                                                    _productDetail['name'] ??
                                                    '';
                                                final String shareText =
                                                    '$productName\n$productUrl';

                                                await SharePlus.instance.share(
                                                  ShareParams(text: shareText),
                                                );
                                              },
                                              icon: Icon(
                                                Icons.share_outlined,
                                                color:
                                                    AppColors.getSecondaryTextColor(
                                                      context,
                                                    ),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Divider to separate top section from details
                                Divider(
                                  color: AppColors.getBorderColor(context),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 16),

                                // Additional product info (moved from top)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'product.categories'.tr(),
                                      style: kAppTextStyle(
                                        color: AppColors.getPrimaryTextColor(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        children:
                                            _productDetail['categories'].asMap().entries.map<
                                              Widget
                                            >((entry) {
                                              final index = entry.key;
                                              final category = entry.value;
                                              final isLast =
                                                  index ==
                                                  _productDetail['categories']
                                                          .length -
                                                      1;

                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => MainScreen(
                                                                initialIndex: 2,
                                                                productScreen: ProductScreen(
                                                                  categoryId:
                                                                      category['id'],
                                                                  categoryName:
                                                                      category['name'],
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                      category['name'],
                                                      style: kAppTextStyle(
                                                        color:
                                                            AppColors.primary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isLast)
                                                    Text(
                                                      ', ',
                                                      style: kAppTextStyle(
                                                        color:
                                                            AppColors.getSecondaryTextColor(
                                                              context,
                                                            ),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                ],
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'product.sku'.tr(),
                                      style: kAppTextStyle(
                                        color: AppColors.getPrimaryTextColor(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _productDetail['sku'] ?? '',
                                        style: kAppTextStyle(
                                          color:
                                              AppColors.getSecondaryTextColor(
                                                context,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                Divider(
                                  color: AppColors.getBorderColor(context),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 10),
                                // Price
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _getFormattedPrice(),
                                      style: kAppTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.priceColor,
                                      ),
                                    ),
                                    if (_hasDiscount()) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        _getFormattedOriginalPrice(),
                                        style: kAppTextStyle(
                                          fontSize: 16,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: AppColors.originalPriceColor,
                                        ),
                                      ),
                                    ],
                                    if (_productDetail['sale_percent'] !=
                                            null &&
                                        _productDetail['sale_percent'] > 0) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.priceColor.withAlpha(
                                            0x33,
                                          ), // Light red background
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'product.sale_off'.tr(
                                            namedArgs: {
                                              'percent':
                                                  _productDetail['sale_percent']
                                                      .toString(),
                                            },
                                          ),
                                          style: kAppTextStyle(
                                            fontSize:
                                                14, // Adjusted font size for badge
                                            color: AppColors.priceColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Stock status
                                Row(
                                  children: [
                                    Text(
                                      'product.status'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _productDetail['stock_status_label'] ??
                                          '',
                                      style: kAppTextStyle(
                                        fontSize: 16,
                                        color:
                                            _productDetail['is_out_of_stock'] ==
                                                    true
                                                ? AppColors.error
                                                : AppColors.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                HtmlWidget(
                                  _productDetail['description'] ?? '',
                                  customStylesBuilder: (element) {
                                    if (element.localName == 'img') {
                                      return {
                                        'max-width': '100%',
                                        'height': 'auto',
                                        'display': 'block',
                                      };
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Divider(
                                  color: AppColors.getBorderColor(context),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 10),
                                // Attribute Sets
                                if (_attributeSets.isNotEmpty) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ..._attributeSets.map<Widget>((
                                        attributeSet,
                                      ) {
                                        final setId =
                                            attributeSet['id'].toString();
                                        final isVisual =
                                            attributeSet['display_layout'] ==
                                            'visual';
                                        final hasError = _attributeErrors
                                            .containsKey(setId);
                                        final selectedAttribute =
                                            _selectedAttributes[setId];

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            opacity:
                                                _isAttributeLoading ? 0.6 : 1.0,
                                            child: IgnorePointer(
                                              ignoring: _isAttributeLoading,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Attribute title
                                                  Row(
                                                    children: [
                                                      Text(
                                                        attributeSet['title']
                                                            as String,
                                                        style: kAppTextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              hasError
                                                                  ? AppColors
                                                                      .error
                                                                  : AppColors.getPrimaryTextColor(
                                                                    context,
                                                                  ),
                                                        ),
                                                      ),
                                                      if (selectedAttribute !=
                                                          null) ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          ': ${selectedAttribute['title']}',
                                                          style: kAppTextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                AppColors.getSecondaryTextColor(
                                                                  context,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                      if (_isValidatingAttributes) ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                          height: 12,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth:
                                                                    1.5,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),

                                                  // Error message
                                                  if (hasError) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _attributeErrors[setId]!,
                                                      style: kAppTextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.error,
                                                      ),
                                                    ),
                                                  ],

                                                  const SizedBox(height: 8),
                                                  // Options grid
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children:
                                                        (attributeSet['attributes']
                                                                as List<
                                                                  dynamic
                                                                >)
                                                            .map<Widget>((
                                                              attribute,
                                                            ) {
                                                              final isSelected =
                                                                  _selectedAttributes[setId]?['id'] ==
                                                                  attribute['id'];
                                                              final isUnavailable =
                                                                  _isAttributeUnavailable(
                                                                    attribute['id']
                                                                        as int,
                                                                  );

                                                              if (isVisual) {
                                                                return _buildVisualAttributeOption(
                                                                  attribute,
                                                                  isSelected,
                                                                  isUnavailable,
                                                                  hasError,
                                                                  setId,
                                                                );
                                                              }

                                                              return _buildTextAttributeOption(
                                                                attribute,
                                                                isSelected,
                                                                isUnavailable,
                                                                hasError,
                                                                setId,
                                                              );
                                                            })
                                                            .toList(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Quantity selector with Add to Cart button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'product.quantity'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.getPrimaryTextColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        // Quantity controls
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0,
                                            vertical: 2.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.getSurfaceColor(
                                              context,
                                            ),
                                            border: Border.all(
                                              color: AppColors.getBorderColor(
                                                context,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    final bool isOutOfStock =
                                                        _productDetail['is_out_of_stock']
                                                            as bool? ??
                                                        false;

                                                    // Don't allow decrease if out of stock
                                                    if (isOutOfStock) return;

                                                    if (_quantity > 1) {
                                                      _updateQuantity(
                                                        _quantity - 1,
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.remove,
                                                        size: 20,
                                                        color:
                                                            AppColors.getPrimaryTextColor(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 60,
                                                child:
                                                    _isEditingQuantity
                                                        ? TextField(
                                                          controller:
                                                              _quantityController,
                                                          focusNode:
                                                              _quantityFocusNode,
                                                          textAlign:
                                                              TextAlign.center,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          style: kAppTextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                AppColors.getPrimaryTextColor(
                                                                  context,
                                                                ),
                                                          ),
                                                          decoration:
                                                              const InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                                contentPadding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                isDense: true,
                                                              ),
                                                          onChanged:
                                                              _onQuantityTextChanged,
                                                          onSubmitted: (value) {
                                                            _validateAndUpdateQuantity();
                                                            _quantityFocusNode
                                                                .unfocus();
                                                          },
                                                          onTapOutside: (
                                                            event,
                                                          ) {
                                                            _validateAndUpdateQuantity();
                                                            _quantityFocusNode
                                                                .unfocus();
                                                          },
                                                        )
                                                        : GestureDetector(
                                                          onTap: _onQuantityTap,
                                                          child: Container(
                                                            height: 40,
                                                            alignment:
                                                                Alignment
                                                                    .center,
                                                            child: Text(
                                                              _quantity
                                                                  .toString(),
                                                              style: kAppTextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    AppColors.getPrimaryTextColor(
                                                                      context,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                              ),
                                              SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    final bool isOutOfStock =
                                                        _productDetail['is_out_of_stock']
                                                            as bool? ??
                                                        false;
                                                    final bool
                                                    withStorehouseManagement =
                                                        _productDetail['with_storehouse_management']
                                                            as bool? ??
                                                        false;
                                                    final int maxQuantity =
                                                        _productDetail['quantity']
                                                            as int? ??
                                                        0;

                                                    // Don't allow increase if out of stock
                                                    if (isOutOfStock) return;

                                                    if (!withStorehouseManagement) {
                                                      // Allow increase up to 1000 for products without storehouse management
                                                      if (_quantity < 1000) {
                                                        _updateQuantity(
                                                          _quantity + 1,
                                                        );
                                                      }
                                                    } else {
                                                      // Check stock for products with storehouse management
                                                      if (maxQuantity == 0)
                                                        return;
                                                      if (_quantity <
                                                          maxQuantity) {
                                                        _updateQuantity(
                                                          _quantity + 1,
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.add,
                                                        size: 20,
                                                        color:
                                                            AppColors.getPrimaryTextColor(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Add to Cart button - matching Submit review button style
                                        Expanded(
                                          child: SizedBox(
                                            height: 52,
                                            child: ElevatedButton.icon(
                                              icon:
                                                  _isAddingToCart
                                                      ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.black),
                                                        ),
                                                      )
                                                      : SvgPicture.asset(
                                                        'assets/images/icons/cart.svg',
                                                        width: 18,
                                                        height: 18,
                                                        colorFilter:
                                                            const ColorFilter.mode(
                                                              Colors.black,
                                                              BlendMode.srcIn,
                                                            ),
                                                      ),
                                              label: Text(
                                                'product.add_to_cart'.tr(),
                                                style: kAppTextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              onPressed:
                                                  _isAddingToCart ||
                                                          _isBuyingNow ||
                                                          _productDetail['is_out_of_stock'] ==
                                                              true
                                                      ? null
                                                      : _addToCart,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.black,
                                                elevation: 0,
                                                shadowColor: Colors.transparent,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                disabledBackgroundColor:
                                                    AppColors.getSecondaryTextColor(
                                                      context,
                                                    ),
                                                disabledForegroundColor:
                                                    AppColors.getSecondaryTextColor(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                Divider(
                                  color: AppColors.getBorderColor(context),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 10),
                                // Store Info Section
                                if (_productDetail['store'] != null &&
                                    _productDetail['store']['name'] !=
                                        null) ...[
                                  _buildStoreInfo(),
                                  const SizedBox(height: 16),
                                  Divider(
                                    color: AppColors.getBorderColor(context),
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Description
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'product.description'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    HtmlWidget(
                                      _productDetail['content'] ?? '',
                                      customStylesBuilder: (element) {
                                        if (element.localName == 'img') {
                                          return {'max-width': '100%'};
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${'product.reviews'.tr()} (${_reviews.length})',
                                          key: _reviewsKey,
                                          style: kAppTextStyle(
                                            fontSize: 18,
                                            color:
                                                AppColors.getPrimaryTextColor(
                                                  context,
                                                ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(
                                      color: AppColors.getBorderColor(context),
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 10),
                                    // Insert the new rating display section here
                                    if (_productDetail['reviews_count'] !=
                                            null &&
                                        _productDetail['reviews_count'] > 0)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            (_productDetail['reviews_avg']
                                                        as double?)
                                                    ?.toStringAsFixed(2) ??
                                                '0.0',
                                            style: kAppTextStyle(
                                              fontSize:
                                                  48, // Large font for the score
                                              color: const Color(
                                                0xFF689F38,
                                              ), // Green color for the score
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children:
                                                    List.generate(5, (index) {
                                                      double avgRating =
                                                          (_productDetail['reviews_avg']
                                                              as double?) ??
                                                          0.0;
                                                      return Icon(
                                                        index < avgRating
                                                            ? Icons.star
                                                            : Icons
                                                                .star_border_outlined,
                                                        color:
                                                            index < avgRating
                                                                ? AppColors
                                                                    .primary
                                                                : AppColors.getBorderColor(
                                                                  context,
                                                                ),
                                                        size: 22,
                                                      );
                                                    }).toList(),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_reviews.length} ${'product.reviews'.tr()}',
                                                style: kAppTextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.getSecondaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 16),
                                    // Review form - Modern clean design
                                    if (_isLoggedIn && !_hasReviewed)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title
                                          Text(
                                            'SUBMIT YOUR REVIEW',
                                            style: kAppTextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  AppColors.getPrimaryTextColor(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // Rating section - clean design
                                          Text(
                                            'Your rating of this product:',
                                            style: kAppTextStyle(
                                              fontSize: 16,
                                              color:
                                                  AppColors.getPrimaryTextColor(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (index) => GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedRating = index + 1;
                                                  });
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                  child: Icon(
                                                    index < _selectedRating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    size: 32,
                                                    color:
                                                        index < _selectedRating
                                                            ? AppColors.primary
                                                            : AppColors.getSecondaryTextColor(
                                                              context,
                                                            ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          // Comment section - clean design
                                          TextField(
                                            controller:
                                                _reviewCommentController,
                                            decoration: InputDecoration(
                                              hintText: 'Write your review ...',
                                              hintStyle: kAppTextStyle(
                                                color:
                                                    AppColors.getHintTextColor(
                                                      context,
                                                    ),
                                                fontSize: 16,
                                              ),
                                              filled: true,
                                              fillColor:
                                                  AppColors.getSurfaceColor(
                                                    context,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color:
                                                      AppColors.getBorderColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color:
                                                      AppColors.getBorderColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppColors.primary,
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.all(16),
                                            ),
                                            maxLines: 6,
                                            minLines: 4,
                                          ),
                                          const SizedBox(height: 24),
                                          // Image upload section - simplified
                                          _buildImageUploadSection(),
                                          const SizedBox(height: 32),
                                          // Submit button - clean design
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed:
                                                  _isSubmittingReview
                                                      ? null
                                                      : _submitReview,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.black,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 18,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                elevation: 0,
                                              ),
                                              child:
                                                  _isSubmittingReview
                                                      ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Colors
                                                                        .black,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Text(
                                                            'Submitting...',
                                                            style: kAppTextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                      : Text(
                                                        'Submit Review',
                                                        style: kAppTextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (_isLoggedIn && _hasReviewed)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.getCardBackgroundColor(
                                                context,
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.success.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline,
                                              color: AppColors.success,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'product.you_already_reviewed'
                                                    .tr(),
                                                style: kAppTextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      AppColors.getPrimaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Column(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.getCardBackgroundColor(
                                                    context,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.getBorderColor(
                                                  context,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Sign in to review',
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.getPrimaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Share your experience with other customers',
                                                  style: kAppTextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.getSecondaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const SignInScreen(),
                                                  ),
                                                ).then((_) {
                                                  _checkLoginStatus();
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.black,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                'common.sign_in'.tr(),
                                                style: kAppTextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 24),
                                    // Top reviews
                                    Text(
                                      'product.top_reviews'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (_isLoadingReviews)
                                      const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                      )
                                    else if (_reviewError != null)
                                      Center(
                                        child: Text(
                                          _reviewError!,
                                          style: kAppTextStyle(
                                            color: AppColors.error,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    else if (_reviews.isEmpty)
                                      Center(
                                        child: Text(
                                          'No reviews yet',
                                          style: kAppTextStyle(
                                            color:
                                                AppColors.getSecondaryTextColor(
                                                  context,
                                                ),
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    else
                                      ..._reviews.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final review = entry.value;
                                        final isLast =
                                            index == _reviews.length - 1;

                                        return Column(
                                          children: [
                                            _buildReviewItem(
                                              avatar: review.userAvatar,
                                              name: review.userName,
                                              rating: review.star,
                                              date: review.createdAt,
                                              comment: review.comment,
                                              orderedAt: review.orderedAt ?? '',
                                              images:
                                                  review.images
                                                      .map(
                                                        (image) =>
                                                            image.fullUrl,
                                                      )
                                                      .toList(),
                                            ),
                                            if (!isLast) ...[
                                              const SizedBox(height: 16),
                                              Divider(
                                                color: AppColors.getBorderColor(
                                                  context,
                                                ),
                                                thickness: 1,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          ],
                                        );
                                      }).toList(),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Divider(
                                  color: AppColors.getBorderColor(context),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'product.related_products'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (_relatedProducts.isEmpty)
                                      Center(
                                        child: Text(
                                          'product.no_related_products'.tr(),
                                          style: kAppTextStyle(
                                            fontSize: 14,
                                            color:
                                                AppColors.getSecondaryTextColor(
                                                  context,
                                                ),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      )
                                    else
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children:
                                              _relatedProducts.map((product) {
                                                return Container(
                                                  width: 180,
                                                  margin: const EdgeInsets.only(
                                                    right: 16,
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      // Extract the required data with null safety
                                                      final Map<String, dynamic>
                                                      productData = {
                                                        'slug': product['slug'],
                                                        'url':
                                                            product['slug'], // Use slug as URL since that's what we need
                                                        'title':
                                                            product['name'],
                                                        'imageUrl':
                                                            (product['image_with_sizes']?['small']
                                                                    as List<
                                                                      dynamic
                                                                    >?)
                                                                ?.first ??
                                                            product['image_url'] ??
                                                            '',
                                                        'price':
                                                            (product['price']
                                                                    is int)
                                                                ? (product['price']
                                                                        as int)
                                                                    .toDouble()
                                                                : (product['price']
                                                                            as num?)
                                                                        ?.toDouble() ??
                                                                    0.0,
                                                        'reviews':
                                                            product['reviews_count'] ??
                                                            0,
                                                        'rating':
                                                            product['reviews_avg'] ??
                                                            0.0,
                                                      };

                                                      if (productData['slug'] !=
                                                          null) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => ProductDetailScreen(
                                                                  product:
                                                                      productData,
                                                                ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'product.missing_slug'
                                                                  .tr(),
                                                            ),
                                                            backgroundColor:
                                                                AppColors.error,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: _buildProductCard(
                                                      imageUrl:
                                                          (product['image_with_sizes']?['small']
                                                                      as List<
                                                                        dynamic
                                                                      >?)
                                                                  ?.first
                                                              as String? ??
                                                          product['image_url']
                                                              as String? ??
                                                          '',
                                                      title:
                                                          product['name']
                                                              as String? ??
                                                          '',
                                                      price:
                                                          (product['price']
                                                                  is int)
                                                              ? (product['price']
                                                                      as int)
                                                                  .toDouble()
                                                              : (product['price']
                                                                          as num?)
                                                                      ?.toDouble() ??
                                                                  0.0,
                                                      originalPrice:
                                                          (product['original_price']
                                                                  is int)
                                                              ? (product['original_price']
                                                                      as int)
                                                                  .toDouble()
                                                              : (product['original_price']
                                                                      as num?)
                                                                  ?.toDouble(),
                                                      rating:
                                                          (product['reviews_avg']
                                                                  as num?)
                                                              ?.toDouble(),
                                                      reviewCount:
                                                          product['reviews_count']
                                                                  is String
                                                              ? int.tryParse(
                                                                product['reviews_count']
                                                                    as String,
                                                              )
                                                              : product['reviews_count']
                                                                  as int?,
                                                      stockStatus:
                                                          product['stock_status_label']
                                                              as String?,
                                                      isOutOfStock:
                                                          product['is_out_of_stock']
                                                              as bool? ??
                                                          false,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isAttributeLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withAlpha(0x33),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        bottomNavigationBar: _buildBottomAddToCartBar(),
      ),
    );
  }

  Widget _buildReviewItem({
    required String avatar,
    required String name,
    required int rating,
    required String date,
    required String comment,
    required String orderedAt,
    required List<String> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.getSkeletonColor(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: kAppTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        orderedAt,
                        style: kAppTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 16,
                            color:
                                index < rating
                                    ? AppColors.primary
                                    : AppColors.getBorderColor(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: kAppTextStyle(
                          fontSize: 12,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          comment,
          style: kAppTextStyle(
            fontSize: 14,
            color: AppColors.getSecondaryTextColor(context),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder:
                  (context, index) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.black,
                                  iconTheme: const IconThemeData(
                                    color: Colors.white,
                                  ),
                                  title: Text(
                                    '${index + 1}/${images.length}',
                                    style: kAppTextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                body: PhotoViewGallery.builder(
                                  itemCount: images.length,
                                  builder: (context, index) {
                                    return PhotoViewGalleryPageOptions(
                                      imageProvider: NetworkImage(
                                        images[index],
                                      ),
                                      minScale:
                                          PhotoViewComputedScale.contained,
                                      maxScale:
                                          PhotoViewComputedScale.covered * 2,
                                      initialScale:
                                          PhotoViewComputedScale.contained,
                                    );
                                  },
                                  scrollPhysics: const BouncingScrollPhysics(),
                                  backgroundDecoration: const BoxDecoration(
                                    color: Colors.black,
                                  ),
                                  pageController: PageController(
                                    initialPage: index,
                                  ),
                                ),
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.getBorderColor(context),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          images[index],
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductCard({
    required String imageUrl,
    required String title,
    required dynamic price,
    dynamic originalPrice,
    dynamic rating,
    int? reviewCount,
    String? stockStatus,
    bool isOutOfStock = false,
  }) {
    // Convert numeric values to proper types
    final double priceValue =
        (price is int) ? price.toDouble() : (price as num).toDouble();
    final double? originalPriceValue =
        originalPrice != null
            ? (originalPrice is int)
                ? originalPrice.toDouble()
                : (originalPrice as num).toDouble()
            : null;
    final double? ratingValue =
        rating != null
            ? (rating is int)
                ? rating.toDouble()
                : (rating as num).toDouble()
            : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (isOutOfStock)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'product.out_of_stock'.tr(),
                      style: kAppTextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kAppTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (ratingValue != null) ...[
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < ratingValue.floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (reviewCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount)',
                          style: kAppTextStyle(
                            fontSize: 12,
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '\$${priceValue.toStringAsFixed(2)}',
                        style: kAppTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (originalPriceValue != null &&
                        originalPriceValue > priceValue) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '\$${originalPriceValue.toStringAsFixed(2)}',
                          style: kAppTextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.originalPriceColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (stockStatus != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    stockStatus,
                    style: kAppTextStyle(
                      fontSize: 12,
                      color: isOutOfStock ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    final store = _productDetail['store'] as Map<String, dynamic>?;
    if (store == null) return const SizedBox.shrink();

    final storeRating = store['reviews_avg']?.toDouble() ?? 5.0;
    final storeReviewCount = store['reviews_count'] ?? 0;
    final positiveRating = store['positive_rating'] ?? 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
      ),
      child: Row(
        children: [
          // Store Logo/Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.getPrimaryTextColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                store['name']?.toString().substring(0, 2).toUpperCase() ?? 'ST',
                style: kAppTextStyle(
                  color: AppColors.getBackgroundColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Store Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Name
                Text(
                  store['name']?.toString().toUpperCase() ?? '',
                  style: kAppTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getPrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                // Positive Rating
                Text(
                  '$positiveRating% Positive customer\'s rating',
                  style: kAppTextStyle(
                    fontSize: 14,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                // Rating Stars and Count
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 16,
                          color:
                              index < storeRating.floor()
                                  ? AppColors.primary
                                  : AppColors.getBorderColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$storeReviewCount ratings',
                      style: kAppTextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload photos section - matching the attached image design
        GestureDetector(
          onTap: _selectedImages.length < 6 ? _pickImages : null,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.getBorderColor(context),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: AppColors.getBorderColor(context),
                strokeWidth: 2,
                dashLength: 8,
                dashSpace: 4,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 32,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload photos',
                      style: kAppTextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Info section - matching the attached image
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can upload up to 6 photos, each photo maximum size is 2 MB.',
                  style: kAppTextStyle(
                    fontSize: 12,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Selected images - clean display
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(image, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(8),
          ),
        );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashLength;
        final extractPath = pathMetric.extractPath(
          distance,
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
