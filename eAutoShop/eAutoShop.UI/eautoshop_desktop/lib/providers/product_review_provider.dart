import 'package:eautoshop_desktop/models/product_review/product_review.dart';
import 'package:eautoshop_desktop/models/product_review/product_review_search_object.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class ProductReviewProvider extends BaseProvider<ProductReview, Object?> {
  ProductReviewProvider() : super('ProductReview');

  List<ProductReview> productReviews = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getProductReviews({
    required int page,
    required int pageSize,
    ProductReviewSearchObject? search,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final queryParameters = <String, dynamic>{
        if (search != null) ...search.toJson(),
        'Page': page,
        'PageSize': pageSize,
      };

      final SearchResult<ProductReview> searchResult = await get(
        filter: queryParameters,
        fromJson: ProductReview.fromJson,
      );

      productReviews = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      productReviews = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProductReview(int id) async {
    await delete(id);
  }
}
