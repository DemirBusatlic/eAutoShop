import 'package:eautoshop_mobile/models/appointment_detail/appointment_detail.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class AppointmentDetailProvider
    extends BaseProvider<AppointmentDetail, AppointmentDetail> {
  List<AppointmentDetail> appointmentDetails = [];
  int countOfItems = 0;
  bool isLoading = false;

  AppointmentDetailProvider() : super('AppointmentDetail');

  Future<void> getByAppointment({required int appointmentId}) async {
    isLoading = true;
    notifyListeners();

    final Map<String, dynamic> queryParams = {
      'AppointmentId': appointmentId,
      'Page': 1,
      'PageSize': 100,
    };

    try {
      final SearchResult<AppointmentDetail> searchResult = await get(
        filter: queryParams,
        fromJson: (json) => AppointmentDetail.fromJson(json),
      );

      appointmentDetails = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      appointmentDetails = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
