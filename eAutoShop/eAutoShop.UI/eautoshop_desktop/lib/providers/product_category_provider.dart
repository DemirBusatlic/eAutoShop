import 'package:eautoshop_desktop/models/product_category/product_category.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class ProductCategoryProvider
    extends BaseProvider<ProductCategory, ProductCategory> {
  ProductCategoryProvider() : super('ProductCategory');

  List<ProductCategory> categories = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getCategories() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<ProductCategory> searchResult = await get(
        fromJson: ProductCategory.fromJson,
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
