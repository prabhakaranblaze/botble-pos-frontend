import 'package:get/get.dart';
import 'package:martfury/src/model/ad.dart';
import 'package:martfury/src/model/category.dart';
import 'package:martfury/src/model/product.dart';
import 'package:martfury/src/model/brand.dart';
import 'package:martfury/src/service/category_service.dart';
import 'package:martfury/src/service/product_service.dart';
import 'package:martfury/src/service/ad_service.dart';
import 'package:martfury/src/service/brand_service.dart';

class HomeController extends GetxController {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final AdService _adService = AdService();
  final BrandService _brandService = BrandService();

  // Reactive state variables
  final isLoading = true.obs;
  final adsLoading = true.obs;
  final error = RxnString(); // Rxn<String> for nullable string
  final adsError = RxnString(); // Added for ads error state
  final featuredCategories = <Category>[].obs;
  final featuredBrands = <Brand>[].obs;
  final flashSaleProducts = <Map<String, dynamic>>[].obs;
  final flashSaleEndTime =
      Rxn<DateTime>(); // Rxn<DateTime> for nullable DateTime
  final flashSaleName = ''.obs;
  final categoryProducts = <int, List<Product>>{}.obs;
  final ads = <Ad>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
    loadAds();
  }

  Future<void> loadAds() async {
    adsLoading.value = true;
    adsError.value = null;
    try {
      final fetchedAds = await _adService.getAds();

      ads.assignAll(fetchedAds);
    } catch (e) {
      adsError.value = e.toString();
      ads.assignAll([]); // Clear ads on error
    } finally {
      adsLoading.value = false;
    }
  }

  Future<void> loadAllData() async {
    isLoading.value = true;
    error.value = null;

    try {
      // Load flash sale products
      final flashSaleData = await _productService.getFlashSaleProducts();

      if (flashSaleData.isNotEmpty) {
        flashSaleEndTime.value = flashSaleData['endDate'] as DateTime?;
        flashSaleName.value = flashSaleData['name'] as String;
        flashSaleProducts.assignAll(
          (flashSaleData['products'] as List<dynamic>)
              .map((product) => product as Map<String, dynamic>)
              .toList(),
        );
      }

      // Load featured categories
      final categories = await _categoryService.getCategories(isFeatured: true);
      featuredCategories.assignAll(categories);

      // Load featured brands
      final brands = await _brandService.getBrands(isFeatured: true);
      featuredBrands.assignAll(brands);

      // Load products for each category concurrently
      await Future.wait(
        categories.map(
          (Category category) => loadProductsForCategory(category.id),
        ),
      );
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProductsForCategory(int categoryId) async {
    try {
      final products = await _productService.getAllProducts(
        filter: {
          'categories': [categoryId],
        },
        order: 'default_sorting',
      );

      categoryProducts[categoryId] = products['data'];
      categoryProducts.refresh();
    } catch (e) {
      categoryProducts[categoryId] = [];
      categoryProducts.refresh();
    }
  }
}
