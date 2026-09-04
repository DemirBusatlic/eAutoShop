import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/report/monthly_revenue_item.dart';
import 'package:eautoshop_desktop/models/report/product_report_item.dart';
import 'package:eautoshop_desktop/models/report/product_report_request.dart';
import 'package:eautoshop_desktop/models/report/report_request.dart';
import 'package:eautoshop_desktop/models/report/sales_by_category_item.dart';
import 'package:eautoshop_desktop/models/report/top_customer_item.dart';
import 'package:eautoshop_desktop/models/report/top_selling_product_item.dart';

class ReportProvider with ChangeNotifier {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  String get _baseUrl => 'http://${ApiHost.address}:${ApiHost.port}/Report';

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> generateProductReport(ProductReportRequest request) async {
    await _generate('GenerateProductReport', request.toJson());
  }

  Future<List<ProductReportItem>> getProductReport() async {
    final csv = await _getCsv('GetProductReport');

    return _parseProductReport(csv);
  }

  Future<void> generateTopSellingProductsReport(
    ProductReportRequest request,
  ) async {
    await _generate('GenerateTopSellingProductsReport', request.toJson());
  }

  Future<List<TopSellingProductItem>> getTopSellingProductsReport() async {
    final csv = await _getCsv('GetTopSellingProductsReport');

    return _parseTopSellingProductsReport(csv);
  }

  Future<void> generateSalesByCategoryReport(ReportRequest request) async {
    await _generate('GenerateSalesByCategoryReport', request.toJson());
  }

  Future<List<SalesByCategoryItem>> getSalesByCategoryReport() async {
    final csv = await _getCsv('GetSalesByCategoryReport');

    return _parseSalesByCategoryReport(csv);
  }

  Future<void> generateMonthlyRevenueReport(ReportRequest request) async {
    await _generate('GenerateMonthlyRevenueReport', request.toJson());
  }

  Future<List<MonthlyRevenueItem>> getMonthlyRevenueReport() async {
    final csv = await _getCsv('GetMonthlyRevenueReport');

    return _parseMonthlyRevenueReport(csv);
  }

  Future<void> generateTopCustomersReport(ReportRequest request) async {
    await _generate('GenerateTopCustomersReport', request.toJson());
  }

  Future<List<TopCustomerItem>> getTopCustomersReport() async {
    final csv = await _getCsv('GetTopCustomersReport');

    return _parseTopCustomersReport(csv);
  }

  Future<void> _generate(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _getErrorMessage(response, 'Greška prilikom generisanja izvještaja.'),
      );
    }
  }

  Future<String> _getCsv(String endpoint) async {
    final headers = await _headers();

    headers['Accept'] = 'text/csv';

    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_getErrorMessage(response, 'Izvještaj nije pronađen.'));
    }

    return utf8.decode(response.bodyBytes);
  }

  String _getErrorMessage(http.Response response, String fallback) {
    if (response.body.trim().isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['Message'];

        if (message != null) {
          return message.toString();
        }
      }
    } catch (_) {
      return response.body;
    }

    return fallback;
  }

  List<List<String>> _parseCsv(String csvContent) {
    if (csvContent.trim().isEmpty) {
      return [];
    }

    final normalizedCsv = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalizedCsv);

    if (rows.length <= 1) {
      return [];
    }

    return rows
        .skip(1)
        .where(
          (row) =>
              row.isNotEmpty &&
              row.any((value) => value.toString().trim().isNotEmpty),
        )
        .map((row) => row.map((value) => value.toString().trim()).toList())
        .toList();
  }

  List<ProductReportItem> _parseProductReport(String csv) {
    final rows = _parseCsv(csv);

    return rows
        .where((row) => row.length >= 8)
        .map(
          (row) => ProductReportItem(
            productId: int.parse(row[0]),
            productName: row[1],
            category: row[2],
            price: double.parse(row[3]),
            discount: double.parse(row[4]),
            discountedPrice: double.parse(row[5]),
            totalSold: int.parse(row[6]),
            totalRevenue: double.parse(row[7]),
          ),
        )
        .toList();
  }

  List<TopSellingProductItem> _parseTopSellingProductsReport(String csv) {
    final rows = _parseCsv(csv);

    return rows
        .where((row) => row.length >= 5)
        .map(
          (row) => TopSellingProductItem(
            productId: int.parse(row[0]),
            productName: row[1],
            category: row[2],
            totalSold: int.parse(row[3]),
            totalRevenue: double.parse(row[4]),
          ),
        )
        .toList();
  }

  List<SalesByCategoryItem> _parseSalesByCategoryReport(String csv) {
    final rows = _parseCsv(csv);

    return rows
        .where((row) => row.length >= 4)
        .map(
          (row) => SalesByCategoryItem(
            categoryId: int.parse(row[0]),
            categoryName: row[1],
            totalSold: int.parse(row[2]),
            totalRevenue: double.parse(row[3]),
          ),
        )
        .toList();
  }

  List<MonthlyRevenueItem> _parseMonthlyRevenueReport(String csv) {
    final rows = _parseCsv(csv);

    return rows
        .where((row) => row.length >= 2)
        .map(
          (row) => MonthlyRevenueItem(
            date: DateTime.parse(row[0]),
            revenue: double.parse(row[1]),
          ),
        )
        .toList();
  }

  List<TopCustomerItem> _parseTopCustomersReport(String csv) {
    final rows = _parseCsv(csv);

    return rows
        .where((row) => row.length >= 5)
        .map(
          (row) => TopCustomerItem(
            customerId: int.parse(row[0]),
            username: row[1],
            customerName: row[2],
            ordersCount: int.parse(row[3]),
            totalSpent: double.parse(row[4]),
          ),
        )
        .toList();
  }
}
