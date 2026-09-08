import 'package:eautoshop_desktop/models/car_model/car_model.dart';
import 'package:eautoshop_desktop/models/car_model/car_model_insert_update.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';

class CarModelProvider extends BaseProvider<CarModel, CarModelInsertUpdate> {
  CarModelProvider() : super('CarModel');

  List<CarModel> models = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getModels({
    String? name,
    int? carManufacturerId,
    int page = 1,
    int pageSize = 100,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<CarModel> searchResult = await get(
        filter: {
          'name': name,
          'carManufacturerId': carManufacturerId,
          'page': page,
          'pageSize': pageSize,
        },
        fromJson: CarModel.fromJson,
      );

      models = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      models = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> insertModel(CarModelInsertUpdate request) async {
    await insert(request, toJson: (item) => item.toJson());
    await getModels();
  }

  Future<void> updateModel(int id, CarModelInsertUpdate request) async {
    await update(id: id, item: request, toJson: (item) => item.toJson());

    await getModels();
  }

  Future<void> deleteModel(int id) async {
    await delete(id);
    await getModels();
  }
}
