import 'package:eautoshop_desktop/models/city/city.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class CityProvider extends BaseProvider<City, City> {
  CityProvider() : super('City');

  List<City> cities = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getCities() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<City> searchResult = await get(
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
}
