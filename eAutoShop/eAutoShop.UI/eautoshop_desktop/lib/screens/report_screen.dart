import 'dart:math' as math;
import 'dart:typed_data';

import 'package:eautoshop_desktop/models/product/product.dart';
import 'package:eautoshop_desktop/models/product_category/product_category.dart';
import 'package:eautoshop_desktop/models/report/monthly_revenue_item.dart';
import 'package:eautoshop_desktop/models/report/product_report_item.dart';
import 'package:eautoshop_desktop/models/report/product_report_request.dart';
import 'package:eautoshop_desktop/models/report/report_request.dart';
import 'package:eautoshop_desktop/models/report/sales_by_category_item.dart';
import 'package:eautoshop_desktop/models/report/top_customer_item.dart';
import 'package:eautoshop_desktop/models/report/top_selling_product_item.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:eautoshop_desktop/providers/product_category_provider.dart';
import 'package:eautoshop_desktop/providers/product_provider.dart';
import 'package:eautoshop_desktop/providers/report_provider.dart';
import 'package:eautoshop_desktop/services/report_notification_service.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum ReportType {
  products,
  topSellingProducts,
  salesByCategory,
  monthlyRevenue,
  topCustomers,
}

extension ReportTypeExtension on ReportType {
  String get label {
    switch (this) {
      case ReportType.products:
        return 'Izvještaj proizvoda';
      case ReportType.topSellingProducts:
        return 'Najprodavaniji proizvodi';
      case ReportType.salesByCategory:
        return 'Prodaja po kategorijama';
      case ReportType.monthlyRevenue:
        return 'Prihod po periodu';
      case ReportType.topCustomers:
        return 'Top kupci';
    }
  }

  String get notificationType {
    switch (this) {
      case ReportType.products:
        return 'productreport';
      case ReportType.topSellingProducts:
        return 'topsellingproductsreport';
      case ReportType.salesByCategory:
        return 'salesbycategoryreport';
      case ReportType.monthlyRevenue:
        return 'monthlyrevenuereport';
      case ReportType.topCustomers:
        return 'topcustomersreport';
    }
  }

  bool get supportsProductFilters {
    return this == ReportType.products || this == ReportType.topSellingProducts;
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const Color _primaryBlue = Color(0xFF2848C7);

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _moneyFormat = NumberFormat('#,##0.00');

  final ProductProvider _filterProductProvider = ProductProvider();
  final ProductCategoryProvider _filterCategoryProvider =
      ProductCategoryProvider();

  late final ReportNotificationService _notificationService;

  ReportType _selectedReport = ReportType.products;

  DateTime? _startDate;
  DateTime? _endDate;

  int? _selectedCategoryId;
  int? _selectedProductId;

  List<ProductCategory> _categories = [];
  List<Product> _products = [];

  bool _filterDataLoading = true;
  bool _productsLoading = false;
  String? _filterLoadError;

  bool _isGenerating = false;
  bool _isDownloading = false;

  String? _expectedNotificationType;

  List<ProductReportItem> _productReport = [];
  List<TopSellingProductItem> _topSellingProducts = [];
  List<SalesByCategoryItem> _salesByCategory = [];
  List<MonthlyRevenueItem> _monthlyRevenue = [];
  List<TopCustomerItem> _topCustomers = [];

  @override
  void initState() {
    super.initState();

    _notificationService = context
        .read<AuthProvider>()
        .reportNotificationService;

    _notificationService.onNotificationReceived = _onReportNotification;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilterData();
    });
  }

  @override
  void dispose() {
    _notificationService.onNotificationReceived = null;

    _filterProductProvider.dispose();
    _filterCategoryProvider.dispose();

    super.dispose();
  }

  Future<void> _loadFilterData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _filterDataLoading = true;
      _filterLoadError = null;
    });

    try {
      await _filterCategoryProvider.getCategories();

      final products = await _fetchProducts();

      final categories = [..._filterCategoryProvider.categories]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _products = products;
      });
    } on CustomException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _filterLoadError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _filterLoadError = 'Kategorije i proizvodi nisu mogli biti učitani.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _filterDataLoading = false;
        });
      }
    }
  }

  Future<List<Product>> _fetchProducts({int? categoryId}) async {
    const int pageSize = 100;

    final List<Product> products = [];

    int page = 1;

    while (true) {
      await _filterProductProvider.getProducts(
        page: page,
        pageSize: pageSize,
        productCategoryId: categoryId,
      );

      final pageItems = [..._filterProductProvider.products];

      products.addAll(pageItems);

      if (pageItems.isEmpty ||
          products.length >= _filterProductProvider.countOfItems) {
        break;
      }

      page++;
    }

    products.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return products;
  }

  Future<void> _onCategoryChanged(int? categoryId) async {
    if (_isGenerating) {
      return;
    }

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedProductId = null;
      _productsLoading = true;
    });

    try {
      final products = await _fetchProducts(categoryId: categoryId);

      if (!mounted || _selectedCategoryId != categoryId) {
        return;
      }

      setState(() {
        _products = products;
      });
    } on CustomException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Proizvodi nisu mogli biti učitani.', isError: true);
    } finally {
      if (mounted && _selectedCategoryId == categoryId) {
        setState(() {
          _productsLoading = false;
        });
      }
    }
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate != null && _endDate!.isBefore(selected)) {
        _endDate = selected;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _clearFilters() async {
    if (_isGenerating) {
      return;
    }

    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedProductId = null;
    });

    if (_selectedCategoryId != null) {
      await _onCategoryChanged(null);
    }
  }

  Future<void> _generateReport() async {
    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      _showMessage(
        'Početni datum ne može biti nakon završnog datuma.',
        isError: true,
      );

      return;
    }

    if (!_notificationService.isInitialized) {
      _showMessage(
        'Veza za obavijesti o izvještajima nije aktivna. '
        'Odjavite se i ponovo prijavite.',
        isError: true,
      );

      return;
    }

    final reportProvider = context.read<ReportProvider>();

    setState(() {
      _clearCurrentReportData();

      _isGenerating = true;
      _expectedNotificationType = _selectedReport.notificationType;
    });

    try {
      switch (_selectedReport) {
        case ReportType.products:
          await reportProvider.generateProductReport(
            ProductReportRequest(
              startDate: _startDate,
              endDate: _endDate,
              productCategoryId: _selectedCategoryId,
              productId: _selectedProductId,
            ),
          );

          break;

        case ReportType.topSellingProducts:
          await reportProvider.generateTopSellingProductsReport(
            ProductReportRequest(
              startDate: _startDate,
              endDate: _endDate,
              productCategoryId: _selectedCategoryId,
              productId: _selectedProductId,
            ),
          );

          break;

        case ReportType.salesByCategory:
          await reportProvider.generateSalesByCategoryReport(
            ReportRequest(startDate: _startDate, endDate: _endDate),
          );

          break;

        case ReportType.monthlyRevenue:
          await reportProvider.generateMonthlyRevenueReport(
            ReportRequest(startDate: _startDate, endDate: _endDate),
          );

          break;

        case ReportType.topCustomers:
          await reportProvider.generateTopCustomersReport(
            ReportRequest(startDate: _startDate, endDate: _endDate),
          );

          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGenerating = false;
        _expectedNotificationType = null;
      });

      _showMessage(_cleanError(error), isError: true);
    }
  }

  void _onReportNotification(String notificationType, String message) {
    if (!mounted ||
        !_isGenerating ||
        notificationType != _expectedNotificationType) {
      return;
    }

    final normalizedMessage = message.toLowerCase();

    if (!normalizedMessage.contains('uspješno')) {
      setState(() {
        _isGenerating = false;
        _expectedNotificationType = null;
      });

      _showMessage(message, isError: true);

      return;
    }

    _loadGeneratedReport(message);
  }

  Future<void> _loadGeneratedReport(String notificationMessage) async {
    final provider = context.read<ReportProvider>();

    try {
      switch (_selectedReport) {
        case ReportType.products:
          final data = await provider.getProductReport();

          if (!mounted) {
            return;
          }

          setState(() {
            _productReport = data;
          });

          break;

        case ReportType.topSellingProducts:
          final data = await provider.getTopSellingProductsReport();

          if (!mounted) {
            return;
          }

          setState(() {
            _topSellingProducts = data;
          });

          break;

        case ReportType.salesByCategory:
          final data = await provider.getSalesByCategoryReport();

          if (!mounted) {
            return;
          }

          setState(() {
            _salesByCategory = data;
          });

          break;

        case ReportType.monthlyRevenue:
          final data = await provider.getMonthlyRevenueReport();

          if (!mounted) {
            return;
          }

          setState(() {
            _monthlyRevenue = data;
          });

          break;

        case ReportType.topCustomers:
          final data = await provider.getTopCustomersReport();

          if (!mounted) {
            return;
          }

          setState(() {
            _topCustomers = data;
          });

          break;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isGenerating = false;
        _expectedNotificationType = null;
      });

      _showMessage(notificationMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGenerating = false;
        _expectedNotificationType = null;
      });

      _showMessage(_cleanError(error), isError: true);
    }
  }

  Future<void> _downloadReport() async {
    if (!_hasData || _isDownloading) {
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final provider = context.read<ReportProvider>();

      late final Uint8List bytes;
      late final String fileName;

      switch (_selectedReport) {
        case ReportType.products:
          bytes = await provider.downloadProductReport();
          fileName = 'product_report.csv';
          break;

        case ReportType.topSellingProducts:
          bytes = await provider.downloadTopSellingProductsReport();
          fileName = 'top_selling_products_report.csv';
          break;

        case ReportType.salesByCategory:
          bytes = await provider.downloadSalesByCategoryReport();
          fileName = 'sales_by_category_report.csv';
          break;

        case ReportType.monthlyRevenue:
          bytes = await provider.downloadMonthlyRevenueReport();
          fileName = 'monthly_revenue_report.csv';
          break;

        case ReportType.topCustomers:
          bytes = await provider.downloadTopCustomersReport();
          fileName = 'top_customers_report.csv';
          break;
      }

      const csvType = XTypeGroup(label: 'CSV', extensions: ['csv']);

      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [csvType],
      );

      if (location == null) {
        return;
      }

      final file = XFile.fromData(bytes, mimeType: 'text/csv', name: fileName);

      await file.saveTo(location.path);

      if (!mounted) {
        return;
      }

      _showMessage('Izvještaj je uspješno sačuvan.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_cleanError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _clearCurrentReportData() {
    switch (_selectedReport) {
      case ReportType.products:
        _productReport = [];
        break;

      case ReportType.topSellingProducts:
        _topSellingProducts = [];
        break;

      case ReportType.salesByCategory:
        _salesByCategory = [];
        break;

      case ReportType.monthlyRevenue:
        _monthlyRevenue = [];
        break;

      case ReportType.topCustomers:
        _topCustomers = [];
        break;
    }
  }

  bool get _hasData {
    switch (_selectedReport) {
      case ReportType.products:
        return _productReport.isNotEmpty;

      case ReportType.topSellingProducts:
        return _topSellingProducts.isNotEmpty;

      case ReportType.salesByCategory:
        return _salesByCategory.isNotEmpty;

      case ReportType.monthlyRevenue:
        return _monthlyRevenue.isNotEmpty;

      case ReportType.topCustomers:
        return _topCustomers.isNotEmpty;
    }
  }

  String _cleanError(Object error) {
    if (error is CustomException) {
      return error.message;
    }

    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : const Color(0xFF1B7F3A),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildFilters(),
          if (_filterLoadError != null &&
              _selectedReport.supportsProductFilters) ...[
            const SizedBox(height: 12),
            _buildFilterError(),
          ],
          const SizedBox(height: 20),
          if (_isGenerating)
            _buildGeneratingCard()
          else if (!_hasData)
            _buildEmptyState()
          else ...[
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildChartCard(),
            const SizedBox(height: 20),
            _buildTableCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _primaryBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bar_chart_outlined,
            color: _primaryBlue,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Izvještaji',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202124),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Generisanje i pregled izvještaja poslovanja',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, size: 21, color: _primaryBlue),
              SizedBox(width: 8),
              Text(
                'Filteri izvještaja',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<ReportType>(
                  initialValue: _selectedReport,
                  isExpanded: true,
                  decoration: _inputDecoration('Vrsta izvještaja'),
                  items: ReportType.values
                      .map(
                        (type) => DropdownMenuItem<ReportType>(
                          value: type,
                          child: Text(
                            type.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isGenerating
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedReport = value;
                          });
                        },
                ),
              ),
              _buildDateField(
                label: 'Od datuma',
                value: _startDate,
                onPressed: _isGenerating ? null : _pickStartDate,
              ),
              _buildDateField(
                label: 'Do datuma',
                value: _endDate,
                onPressed: _isGenerating ? null : _pickEndDate,
              ),
              if (_selectedReport.supportsProductFilters)
                _buildCategoryDropdown(),
              if (_selectedReport.supportsProductFilters)
                _buildProductDropdown(),
              OutlinedButton.icon(
                onPressed: _isGenerating ? null : _clearFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Očisti'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 56),
                  foregroundColor: _primaryBlue,
                  side: const BorderSide(color: _primaryBlue),
                ),
              ),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(
                  _isGenerating ? 'Generisanje...' : 'Generiši izvještaj',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(190, 56),
                  backgroundColor: _primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<int>(
        key: ValueKey('category-${_selectedCategoryId ?? 'all'}'),
        initialValue: _selectedCategoryId,
        isExpanded: true,
        menuMaxHeight: 350,
        decoration: _inputDecoration('Kategorija').copyWith(
          suffixIcon: _filterDataLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        hint: const Text('Sve kategorije'),
        items: _categories
            .map(
              (category) => DropdownMenuItem<int>(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _isGenerating || _filterDataLoading
            ? null
            : _onCategoryChanged,
      ),
    );
  }

  Widget _buildProductDropdown() {
    return SizedBox(
      width: 240,
      child: DropdownButtonFormField<int>(
        key: ValueKey(
          'product-${_selectedCategoryId ?? 'all'}-'
          '${_selectedProductId ?? 'all'}',
        ),
        initialValue: _selectedProductId,
        isExpanded: true,
        menuMaxHeight: 350,
        decoration: _inputDecoration('Proizvod').copyWith(
          suffixIcon: _productsLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        hint: const Text('Svi proizvodi'),
        items: _products
            .map(
              (product) => DropdownMenuItem<int>(
                value: product.id,
                child: Text(product.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _isGenerating || _productsLoading || _filterDataLoading
            ? null
            : (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 190,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: _inputDecoration(
            label,
          ).copyWith(suffixIcon: const Icon(Icons.calendar_month_outlined)),
          child: Text(
            value == null ? 'Svi datumi' : _dateFormat.format(value),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
      ),
    );
  }

  Widget _buildFilterError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD5D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB3261E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _filterLoadError!,
              style: const TextStyle(color: Color(0xFF8A1C15)),
            ),
          ),
          TextButton.icon(
            onPressed: _filterDataLoading ? null : _loadFilterData,
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingCard() {
    return _sectionCard(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 45, horizontal: 20),
        child: Column(
          children: [
            CircularProgressIndicator(color: _primaryBlue),
            SizedBox(height: 18),
            Text(
              'Generisanje izvještaja je u toku...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Izvještaj se obrađuje putem RabbitMQ servisa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _sectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.query_stats, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nema učitanog izvještaja',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            const Text(
              'Odaberite vrstu izvještaja, podesite filtere '
              'i kliknite „Generiši izvještaj“.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summaries = _getSummaryData();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 600
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: summaries
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: _buildSummaryCard(
                    title: item.title,
                    value: item.value,
                    icon: item.icon,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return _sectionCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primaryBlue.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryBlue, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_SummaryItem> _getSummaryData() {
    switch (_selectedReport) {
      case ReportType.products:
        final best = _productReport.reduce(
          (a, b) => a.totalSold >= b.totalSold ? a : b,
        );

        final totalSold = _productReport.fold<int>(
          0,
          (sum, item) => sum + item.totalSold,
        );

        final revenue = _productReport.fold<double>(
          0,
          (sum, item) => sum + item.totalRevenue,
        );

        return [
          _SummaryItem(
            'Najprodavaniji proizvod',
            best.productName,
            Icons.emoji_events_outlined,
          ),
          _SummaryItem(
            'Ukupno prodano',
            totalSold.toString(),
            Icons.shopping_cart_checkout_outlined,
          ),
          _SummaryItem(
            'Ukupan prihod',
            '${_moneyFormat.format(revenue)} KM',
            Icons.payments_outlined,
          ),
        ];

      case ReportType.topSellingProducts:
        final best = _topSellingProducts.first;

        final totalSold = _topSellingProducts.fold<int>(
          0,
          (sum, item) => sum + item.totalSold,
        );

        final revenue = _topSellingProducts.fold<double>(
          0,
          (sum, item) => sum + item.totalRevenue,
        );

        return [
          _SummaryItem(
            'Najprodavaniji proizvod',
            best.productName,
            Icons.emoji_events_outlined,
          ),
          _SummaryItem(
            'Ukupno prodano',
            totalSold.toString(),
            Icons.inventory_2_outlined,
          ),
          _SummaryItem(
            'Ukupan prihod',
            '${_moneyFormat.format(revenue)} KM',
            Icons.payments_outlined,
          ),
        ];

      case ReportType.salesByCategory:
        final best = _salesByCategory.reduce(
          (a, b) => a.totalRevenue >= b.totalRevenue ? a : b,
        );

        final totalSold = _salesByCategory.fold<int>(
          0,
          (sum, item) => sum + item.totalSold,
        );

        final revenue = _salesByCategory.fold<double>(
          0,
          (sum, item) => sum + item.totalRevenue,
        );

        return [
          _SummaryItem(
            'Najuspješnija kategorija',
            best.categoryName,
            Icons.category_outlined,
          ),
          _SummaryItem(
            'Ukupno prodano',
            totalSold.toString(),
            Icons.inventory_2_outlined,
          ),
          _SummaryItem(
            'Ukupan prihod',
            '${_moneyFormat.format(revenue)} KM',
            Icons.payments_outlined,
          ),
        ];

      case ReportType.monthlyRevenue:
        final best = _monthlyRevenue.reduce(
          (a, b) => a.revenue >= b.revenue ? a : b,
        );

        final total = _monthlyRevenue.fold<double>(
          0,
          (sum, item) => sum + item.revenue,
        );

        final average = total / _monthlyRevenue.length;

        return [
          _SummaryItem(
            'Najbolji dan',
            _dateFormat.format(best.date),
            Icons.calendar_month_outlined,
          ),
          _SummaryItem(
            'Ukupan prihod',
            '${_moneyFormat.format(total)} KM',
            Icons.payments_outlined,
          ),
          _SummaryItem(
            'Prosječno dnevno',
            '${_moneyFormat.format(average)} KM',
            Icons.show_chart,
          ),
        ];

      case ReportType.topCustomers:
        final best = _topCustomers.first;

        final totalOrders = _topCustomers.fold<int>(
          0,
          (sum, item) => sum + item.ordersCount,
        );

        final totalSpent = _topCustomers.fold<double>(
          0,
          (sum, item) => sum + item.totalSpent,
        );

        return [
          _SummaryItem(
            'Najbolji kupac',
            best.customerName,
            Icons.person_outline,
          ),
          _SummaryItem(
            'Broj narudžbi',
            totalOrders.toString(),
            Icons.receipt_long_outlined,
          ),
          _SummaryItem(
            'Ukupna potrošnja',
            '${_moneyFormat.format(totalSpent)} KM',
            Icons.payments_outlined,
          ),
        ];
    }
  }

  Widget _buildChartCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_chart_outlined, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                _chartTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 360, child: _buildChart()),
        ],
      ),
    );
  }

  String get _chartTitle {
    switch (_selectedReport) {
      case ReportType.products:
        return 'Prodaja proizvoda';

      case ReportType.topSellingProducts:
        return 'Najprodavaniji proizvodi';

      case ReportType.salesByCategory:
        return 'Prihod po kategorijama';

      case ReportType.monthlyRevenue:
        return 'Kretanje prihoda';

      case ReportType.topCustomers:
        return 'Potrošnja top kupaca';
    }
  }

  Widget _buildChart() {
    switch (_selectedReport) {
      case ReportType.products:
        final sorted = [..._productReport]
          ..sort((a, b) => b.totalSold.compareTo(a.totalSold));

        final items = sorted.take(10).toList();

        return _buildBarChart(
          labels: items.map((item) => item.productName).toList(),
          values: items.map((item) => item.totalSold.toDouble()).toList(),
          axisLabel: 'Prodano',
        );

      case ReportType.topSellingProducts:
        return _buildBarChart(
          labels: _topSellingProducts.map((item) => item.productName).toList(),
          values: _topSellingProducts
              .map((item) => item.totalSold.toDouble())
              .toList(),
          axisLabel: 'Prodano',
        );

      case ReportType.salesByCategory:
        return _buildBarChart(
          labels: _salesByCategory.map((item) => item.categoryName).toList(),
          values: _salesByCategory.map((item) => item.totalRevenue).toList(),
          axisLabel: 'Prihod (KM)',
        );

      case ReportType.monthlyRevenue:
        return _buildRevenueLineChart();

      case ReportType.topCustomers:
        return _buildBarChart(
          labels: _topCustomers.map((item) => item.customerName).toList(),
          values: _topCustomers.map((item) => item.totalSpent).toList(),
          axisLabel: 'Potrošnja (KM)',
        );
    }
  }

  Widget _buildBarChart({
    required List<String> labels,
    required List<double> values,
    required String axisLabel,
  }) {
    if (labels.isEmpty || values.isEmpty) {
      return const Center(child: Text('Nema podataka za prikaz grafikona.'));
    }

    final maxValue = values.reduce(math.max);

    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    final interval = maxY > 5 ? maxY / 5 : 1.0;

    final chartWidth = math.max(700.0, labels.length * 115.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(
                  axisLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 58,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 75,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();

                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: SizedBox(
                        width: 100,
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(
              values.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index],
                    width: 30,
                    color: _primaryBlue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart() {
    if (_monthlyRevenue.isEmpty) {
      return const Center(child: Text('Nema podataka za prikaz grafikona.'));
    }

    final sorted = [..._monthlyRevenue]
      ..sort((a, b) => a.date.compareTo(b.date));

    final maxValue = sorted.map((item) => item.revenue).reduce(math.max);

    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    final interval = maxY > 5 ? maxY / 5 : 1.0;

    final labelInterval = math.max(1, (sorted.length / 7).ceil());

    final chartWidth = math.max(700.0, sorted.length * 55.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (sorted.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Prihod (KM)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 58,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();

                    if (index < 0 || index >= sorted.length) {
                      return const SizedBox.shrink();
                    }

                    if (index % labelInterval != 0 &&
                        index != sorted.length - 1) {
                      return const SizedBox.shrink();
                    }

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        DateFormat('dd.MM').format(sorted[index].date),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: _primaryBlue,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: _primaryBlue.withAlpha(18),
                ),
                spots: List.generate(
                  sorted.length,
                  (index) => FlSpot(index.toDouble(), sorted[index].revenue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_outlined, color: _primaryBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detalji izvještaja',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isDownloading ? null : _downloadReport,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(_isDownloading ? 'Preuzimanje...' : 'Preuzmi CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: const BorderSide(color: _primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    switch (_selectedReport) {
      case ReportType.products:
        return DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Proizvod')),
            DataColumn(label: Text('Kategorija')),
            DataColumn(label: Text('Cijena')),
            DataColumn(label: Text('Popust')),
            DataColumn(label: Text('Cijena s popustom')),
            DataColumn(label: Text('Prodano')),
            DataColumn(label: Text('Prihod')),
          ],
          rows: _productReport
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.productName)),
                    DataCell(Text(item.category)),
                    DataCell(Text('${_moneyFormat.format(item.price)} KM')),
                    DataCell(
                      Text('${(item.discount * 100).toStringAsFixed(0)}%'),
                    ),
                    DataCell(
                      Text('${_moneyFormat.format(item.discountedPrice)} KM'),
                    ),
                    DataCell(Text(item.totalSold.toString())),
                    DataCell(
                      Text('${_moneyFormat.format(item.totalRevenue)} KM'),
                    ),
                  ],
                ),
              )
              .toList(),
        );

      case ReportType.topSellingProducts:
        return DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Proizvod')),
            DataColumn(label: Text('Kategorija')),
            DataColumn(label: Text('Prodano')),
            DataColumn(label: Text('Prihod')),
          ],
          rows: _topSellingProducts
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.productName)),
                    DataCell(Text(item.category)),
                    DataCell(Text(item.totalSold.toString())),
                    DataCell(
                      Text('${_moneyFormat.format(item.totalRevenue)} KM'),
                    ),
                  ],
                ),
              )
              .toList(),
        );

      case ReportType.salesByCategory:
        return DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Kategorija')),
            DataColumn(label: Text('Prodano')),
            DataColumn(label: Text('Prihod')),
          ],
          rows: _salesByCategory
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.categoryName)),
                    DataCell(Text(item.totalSold.toString())),
                    DataCell(
                      Text('${_moneyFormat.format(item.totalRevenue)} KM'),
                    ),
                  ],
                ),
              )
              .toList(),
        );

      case ReportType.monthlyRevenue:
        final sorted = [..._monthlyRevenue]
          ..sort((a, b) => a.date.compareTo(b.date));

        return DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Datum')),
            DataColumn(label: Text('Prihod')),
          ],
          rows: sorted
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(_dateFormat.format(item.date))),
                    DataCell(Text('${_moneyFormat.format(item.revenue)} KM')),
                  ],
                ),
              )
              .toList(),
        );

      case ReportType.topCustomers:
        return DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Kupac')),
            DataColumn(label: Text('Korisničko ime')),
            DataColumn(label: Text('Broj narudžbi')),
            DataColumn(label: Text('Ukupno potrošeno')),
          ],
          rows: _topCustomers
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.customerName)),
                    DataCell(Text(item.username)),
                    DataCell(Text(item.ordersCount.toString())),
                    DataCell(
                      Text('${_moneyFormat.format(item.totalSpent)} KM'),
                    ),
                  ],
                ),
              )
              .toList(),
        );
    }
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryItem(this.title, this.value, this.icon);
}
