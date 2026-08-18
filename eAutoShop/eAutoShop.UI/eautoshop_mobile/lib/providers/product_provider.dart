import 'package:eautoshop_mobile/models/products/product.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class ProductProvider extends BaseProvider<Product, Product> {
  List<Product> products = [];
  int countOfItems = 0;
  bool isLoading = false;

  ProductProvider() : super('Product');

  Future<void> getProducts({
    required int pageNumber,
    required int pageSize,
    String? nameFilter,
    bool? withDiscount,
    int? categoryFilter,
    int? carManufacturerId,
    List<int>? carModelsFilter,
  }) async {
    isLoading = true;
    notifyListeners();

    final Map<String, dynamic> queryParams = {
      'Page': pageNumber,
      'PageSize': pageSize,
    };

    if (nameFilter != null && nameFilter.trim().isNotEmpty) {
      queryParams['Contains'] = nameFilter.trim();
    }

    if (withDiscount != null) {
      queryParams['WithDiscount'] = withDiscount;
    }

    if (categoryFilter != null) {
      queryParams['ProductCategoryId'] = categoryFilter;
    }

    if (carManufacturerId != null) {
      queryParams['CarManufacturerId'] = carManufacturerId;
    }

    if (carModelsFilter != null && carModelsFilter.isNotEmpty) {
      queryParams['CarModelIds'] = carModelsFilter;
    }

    try {
      final SearchResult<Product> searchResult = await get(
        customEndpoint: 'active',
        filter: queryParams,
        fromJson: (json) => Product.fromJson(json),
      );

      products = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      products = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
