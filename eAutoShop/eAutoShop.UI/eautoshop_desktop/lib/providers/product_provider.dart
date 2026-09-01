import 'dart:convert';

import 'package:eautoshop_desktop/models/product/product.dart';
import 'package:eautoshop_desktop/models/product/product_insert_update.dart';
import 'package:eautoshop_desktop/models/search_result.dart';
import 'package:eautoshop_desktop/providers/base_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:http/http.dart' as http;

class ProductProvider extends BaseProvider<Product, ProductInsertUpdate> {
  ProductProvider() : super('Product');

  List<Product> products = [];
  int countOfItems = 0;
  bool isLoading = false;

  Future<void> getProducts({
    required int page,
    required int pageSize,
    String? name,
    bool? withDiscount,
    String? state,
    int? productCategoryId,
    int? carManufacturerId,
    List<int>? carModelIds,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final SearchResult<Product> searchResult = await get(
        filter: {
          'Page': page,
          'PageSize': pageSize,
          'Contains': name,
          'WithDiscount': withDiscount,
          'State': state,
          'ProductCategoryId': productCategoryId,
          'CarManufacturerId': carManufacturerId,
          'CarModelIds': carModelIds,
        },
        fromJson: Product.fromJson,
      );

      products = searchResult.result;
      countOfItems = searchResult.count;
    } catch (_) {
      products = [];
      countOfItems = 0;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> insertProduct(ProductInsertUpdate request) async {
    await insert(request, toJson: (item) => item.toJson());
  }

  Future<void> updateProduct({
    required int id,
    required ProductInsertUpdate request,
  }) async {
    await update(id: id, item: request, toJson: (item) => item.toJson());
  }

  Future<void> deleteProduct(int id) async {
    await delete(id);
  }

  Future<void> activateProduct(int id) async {
    await _changeProductState(id: id, action: 'activate');
  }

  Future<void> hideProduct(int id) async {
    await _changeProductState(id: id, action: 'hide');
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

  Future<void> _changeProductState({
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
