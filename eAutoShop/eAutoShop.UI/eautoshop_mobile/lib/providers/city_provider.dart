import 'package:eautoshop_mobile/models/city/city.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class CityProvider extends BaseProvider<City, City> {
  List<City> cities = [];
  int countOfItems = 0;
  bool isLoading = false;

  CityProvider() : super('City');

  Future<void> getCities() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<City> searchResult = await get(
        fromJson: (json) => City.fromJson(json),
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

  Future<void> getRegistrationCities() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<City> searchResult = await get(
        customEndpoint: 'RegistrationLookup',
        fromJson: (json) => City.fromJson(json),
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
