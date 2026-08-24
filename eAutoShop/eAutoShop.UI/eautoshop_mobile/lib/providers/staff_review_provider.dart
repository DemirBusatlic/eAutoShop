import 'package:eautoshop_mobile/models/staff_review/staff_review_insert.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class StaffReviewProvider extends BaseProvider<Object, StaffReviewInsert> {
  bool isSubmitting = false;

  StaffReviewProvider() : super('StaffReview');

  Future<void> addReview(StaffReviewInsert review) async {
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
