import 'package:eautoshop_mobile/models/autoshop_service/autoshop_service.dart';
import 'package:eautoshop_mobile/models/autoshop_service/autoshop_service_search_object.dart';
import 'package:eautoshop_mobile/models/search_result.dart';
import 'package:eautoshop_mobile/providers/base_provider.dart';

class AutoShopServiceProvider
    extends BaseProvider<AutoShopService, AutoShopService> {
  List<AutoShopService> services = [];
  int countOfItems = 0;
  bool isLoading = false;

  AutoShopServiceProvider() : super('AutoShopService');

  Future<void> getServices({
    required int pageNumber,
    required int pageSize,
    AutoShopServiceSearchObject? serviceSearch,
  }) async {
    isLoading = true;
    notifyListeners();

    final Map<String, dynamic> queryParams = {
      'State': 'active',
      'Page': pageNumber,
      'PageSize': pageSize,
    };

    if (serviceSearch?.name != null && serviceSearch!.name!.trim().isNotEmpty) {
      queryParams['Name'] = serviceSearch.name!.trim();
    }

    if (serviceSearch?.serviceType != null &&
        serviceSearch!.serviceType!.trim().isNotEmpty) {
      queryParams['ServiceType'] = serviceSearch.serviceType!.trim();
    }

    if (serviceSearch?.withDiscount != null) {
      queryParams['WithDiscount'] = serviceSearch!.withDiscount;
    }

    try {
      final SearchResult<AutoShopService> searchResult = await get(
        filter: queryParams,
        fromJson: (json) => AutoShopService.fromJson(json),
      );

      services = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      services = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
