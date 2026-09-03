import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/models/service_type/service_type.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class ServiceTypeProvider extends BaseProvider<ServiceType, ServiceType> {
  ServiceTypeProvider() : super('ServiceType');

  List<ServiceType> types = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getTypes() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<ServiceType> searchResult = await get(
        fromJson: ServiceType.fromJson,
      );

      types = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      types = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
