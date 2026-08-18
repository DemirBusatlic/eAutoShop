import 'package:eautoshop_mobile/models/product_category/product_category.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class ProductCategoryProvider
    extends BaseProvider<ProductCategory, ProductCategory> {
  List<ProductCategory> categories = [];
  int countOfItems = 0;
  bool isLoading = false;

  ProductCategoryProvider() : super('ProductCategory');

  Future<void> getCategories() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<ProductCategory> searchResult = await get(
        fromJson: (json) => ProductCategory.fromJson(json),
      );

      categories = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      categories = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
