import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/models/service_type/service_type.dart';
import 'package:eautoshop_desktop/models/service_type/service_type_insert_update.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class ServiceTypeProvider
    extends BaseProvider<ServiceType, ServiceTypeInsertUpdate> {
  ServiceTypeProvider() : super('ServiceType');

  List<ServiceType> types = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getTypes({
    String? name,
    int page = 1,
    int pageSize = 100,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<ServiceType> searchResult = await get(
        filter: {'name': name, 'page': page, 'pageSize': pageSize},
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

  Future<void> insertType(ServiceTypeInsertUpdate request) async {
    await insert(request, toJson: (item) => item.toJson());
    await getTypes();
  }

  Future<void> updateType(int id, ServiceTypeInsertUpdate request) async {
    await update(id: id, item: request, toJson: (item) => item.toJson());

    await getTypes();
  }

  Future<void> deleteType(int id) async {
    await delete(id);
    await getTypes();
  }
}
