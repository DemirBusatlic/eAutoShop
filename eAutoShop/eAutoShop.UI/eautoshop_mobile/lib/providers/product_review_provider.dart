import 'package:eautoshop_mobile/models/product_review/product_review_insert.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class ProductReviewProvider extends BaseProvider<Object, ProductReviewInsert> {
  bool isSubmitting = false;

  ProductReviewProvider() : super('ProductReview');

  Future<void> addReview(ProductReviewInsert review) async {
    isSubmitting = true;
    notifyListeners();

    try {
      await insert(review, toJson: (value) => value.toJson());
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
