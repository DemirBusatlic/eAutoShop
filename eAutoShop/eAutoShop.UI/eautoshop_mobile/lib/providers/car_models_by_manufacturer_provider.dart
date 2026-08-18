import 'package:eautoshop_mobile/models/car_model/car_models_by_manufacturer.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class CarModelsByManufacturerProvider
    extends BaseProvider<CarModelsByManufacturer, CarModelsByManufacturer> {
  List<CarModelsByManufacturer> modelsByManufacturer = [];
  int countOfItems = 0;
  bool isLoading = false;

  CarModelsByManufacturerProvider() : super('GetByManufacturerAll');

  Future<void> getCarModelsByManufacturer() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<CarModelsByManufacturer> searchResult = await get(
        fromJson: (json) => CarModelsByManufacturer.fromJson(json),
      );

      modelsByManufacturer = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      modelsByManufacturer = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
