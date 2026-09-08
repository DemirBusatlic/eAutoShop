import 'package:eautoshop_desktop/models/car_manufacturer/car_manufacturer.dart';
import 'package:eautoshop_desktop/models/catalog/catalog_name_request.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class CarManufacturerProvider
    extends BaseProvider<CarManufacturer, CatalogNameRequest> {
  CarManufacturerProvider() : super('CarManufacturer');

  List<CarManufacturer> manufacturers = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getManufacturers({
    String? name,
    int page = 1,
    int pageSize = 100,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<CarManufacturer> searchResult = await get(
        filter: {'name': name, 'page': page, 'pageSize': pageSize},
        fromJson: CarManufacturer.fromJson,
      );

      manufacturers = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      manufacturers = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> insertManufacturer(CatalogNameRequest request) async {
    await insert(request, toJson: (item) => item.toJson());
    await getManufacturers();
  }

  Future<void> updateManufacturer(int id, CatalogNameRequest request) async {
    await update(id: id, item: request, toJson: (item) => item.toJson());

    await getManufacturers();
  }

  Future<void> deleteManufacturer(int id) async {
    await delete(id);
    await getManufacturers();
  }
}
