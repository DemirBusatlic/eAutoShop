import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/models/staff_review/staff_review.dart';
import 'package:eautoshop_desktop/models/staff_review/staff_review_search_object.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class StaffReviewProvider extends BaseProvider<StaffReview, Object?> {
  StaffReviewProvider() : super('StaffReview');

  List<StaffReview> staffReviews = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getStaffReviews({
    required int page,
    required int pageSize,
    StaffReviewSearchObject? search,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final queryParameters = <String, dynamic>{
        if (search != null) ...search.toJson(),
        'Page': page,
        'PageSize': pageSize,
      };

      final SearchResult<StaffReview> searchResult = await get(
        filter: queryParameters,
        fromJson: StaffReview.fromJson,
      );

      staffReviews = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      staffReviews = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStaffReview(int id) async {
    await delete(id);
  }
}
