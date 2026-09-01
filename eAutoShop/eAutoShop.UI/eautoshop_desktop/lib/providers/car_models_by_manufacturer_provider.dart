import 'package:eautoshop_desktop/models/car_model/car_models_by_manufacturer.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class CarModelsByManufacturerProvider
    extends BaseProvider<CarModelsByManufacturer, CarModelsByManufacturer> {
  CarModelsByManufacturerProvider() : super('GetByManufacturerAll');

  List<CarModelsByManufacturer> modelsByManufacturer = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getCarModelsByManufacturer() async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<CarModelsByManufacturer> searchResult = await get(
        fromJson: CarModelsByManufacturer.fromJson,
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
