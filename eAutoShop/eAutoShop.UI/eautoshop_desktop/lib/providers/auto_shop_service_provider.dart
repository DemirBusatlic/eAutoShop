import 'dart:convert';

import 'package:eautoshop_desktop/models/auto_shop_service/auto_shop_service.dart';
import 'package:eautoshop_desktop/models/auto_shop_service/auto_shop_service_insert_update.dart';
import 'package:eautoshop_desktop/models/auto_shop_service/auto_shop_service_search_object.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class AutoShopServiceProvider
    extends BaseProvider<AutoShopService, AutoShopServiceInsertUpdate> {
  AutoShopServiceProvider() : super('AutoShopService');

  List<AutoShopService> services = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getServices({
    required int page,
    required int pageSize,
    AutoShopServiceSearchObject? search,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<AutoShopService> searchResult = await get(
        filter: {
          'Page': page,
          'PageSize': pageSize,
          'ServiceTypeId': search?.serviceTypeId,
          'Name': search?.name?.trim(),
          'WithDiscount': search?.withDiscount,
          'State': search?.state?.trim(),
        },
        fromJson: AutoShopService.fromJson,
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

  Future<void> insertService(AutoShopServiceInsertUpdate request) async {
    await insert(request, toJson: (item) => item.toJson());
  }

  Future<void> updateService({
    required int id,
    required AutoShopServiceInsertUpdate request,
  }) async {
    await update(id: id, item: request, toJson: (item) => item.toJson());
  }

  Future<void> deleteService(int id) async {
    await delete(id);
  }

  Future<void> activateService(int id) async {
    await _changeServiceState(id: id, action: 'activate');
  }

  Future<void> hideService(int id) async {
    await _changeServiceState(id: id, action: 'hide');
  }

  Future<List<String>> getAllowedActions(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/$id/allowed-actions'),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        final data = jsonDecode(response.body) as List<dynamic>;

        return data.map((action) => action.toString()).toList();
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw const CustomException(
        'Nije moguće pristupiti serveru. '
        'Provjerite da li je API pokrenut.',
      );
    }
  }

  Future<void> _changeServiceState({
    required int id,
    required String action,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseProvider.baseUrl}/$endpoint/$id/$action'),
        headers: await createHeaders(),
      );

      if (_isSuccessful(response.statusCode)) {
        notifyListeners();
        return;
      }

      handleHttpError(response);
    } on CustomException {
      rethrow;
    } catch (_) {
      throw const CustomException(
        'Nije moguće pristupiti serveru. '
        'Provjerite da li je API pokrenut.',
      );
    }
  }

  bool _isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
