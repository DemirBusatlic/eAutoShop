import 'package:eautoshop_desktop/models/catalog/catalog_name_request.dart';
import 'package:eautoshop_desktop/models/city/city.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class CityProvider extends BaseProvider<City, CatalogNameRequest> {
  CityProvider() : super('City');

  List<City> cities = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getCities({
    String? name,
    int page = 1,
    int pageSize = 100,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<City> searchResult = await get(
        filter: {'name': name, 'page': page, 'pageSize': pageSize},
        fromJson: City.fromJson,
      );

      cities = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      cities = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> insertCity(CatalogNameRequest request) async {
    await insert(request, toJson: (item) => item.toJson());
    await getCities();
  }

  Future<void> updateCity(int id, CatalogNameRequest request) async {
    await update(id: id, item: request, toJson: (item) => item.toJson());

    await getCities();
  }

  Future<void> deleteCity(int id) async {
    await delete(id);
    await getCities();
  }
}
