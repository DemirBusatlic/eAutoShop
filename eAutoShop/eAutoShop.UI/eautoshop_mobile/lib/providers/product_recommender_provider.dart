import 'package:eautoshop_mobile/models/products/product.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class ProductRecommenderProvider extends BaseProvider<Product, Product> {
  List<Product> recommendedProducts = [];
  int countOfItems = 0;
  bool isLoading = false;

  ProductRecommenderProvider() : super('Recommender');

  Future<void> getProductRecommendations({required int productId}) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<Product> searchResult = await get(
        customEndpoint: 'RecommendProducts/$productId',
        fromJson: (json) => Product.fromJson(json),
      );

      recommendedProducts = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      recommendedProducts = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
