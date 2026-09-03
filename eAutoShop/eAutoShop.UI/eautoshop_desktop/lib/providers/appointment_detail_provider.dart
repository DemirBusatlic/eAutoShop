import 'package:eautoshop_desktop/models/appointment_detail/appointment_detail.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class AppointmentDetailProvider
    extends BaseProvider<AppointmentDetail, AppointmentDetail> {
  AppointmentDetailProvider() : super('AppointmentDetail');

  List<AppointmentDetail> appointmentDetails = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getByAppointment({required int appointmentId}) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<AppointmentDetail> searchResult = await get(
        filter: {'AppointmentId': appointmentId},
        fromJson: AppointmentDetail.fromJson,
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

  void clear() {
    appointmentDetails = [];
    countOfItems = 0;
    notifyListeners();
  }
}
