import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/product_review/product_review.dart';
import 'package:eautoshop_desktop/models/product_review/product_review_search_object.dart';
import 'package:eautoshop_desktop/models/staff_review/staff_review.dart';
import 'package:eautoshop_desktop/models/staff_review/staff_review_search_object.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:eautoshop_desktop/providers/product_review_provider.dart';
import 'package:eautoshop_desktop/providers/staff_review_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.showStaffReviews});

  final bool showStaffReviews;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryBlue = Color(0xFF2848C7);
  static const int _pageSize = 10;

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  late final TabController _tabController;

  int _selectedTab = 0;
  int _page = 1;
  int _rating = 0;

  bool _initialLoading = true;
  String? _loadError;

  bool get _isProductTab => _selectedTab == 0;

  bool get _hasFilters =>
      _rating != 0 || _commentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: widget.showStaffReviews ? 2 : 1,
      vsync: this,
    );

    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _commentController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == _selectedTab) {
      return;
    }

    setState(() {
      _selectedTab = _tabController.index;
      _page = 1;
      _rating = 0;
      _commentController.clear();
      _loadError = null;
    });

    _loadCurrentReviews(showErrorMessage: true);
  }

  Future<void> _loadInitialData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _initialLoading = true;
      _loadError = null;
    });

    try {
      await _loadCurrentReviews();
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Recenzije nisu mogle biti učitane.';
    }

    if (mounted) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadCurrentReviews({
    bool resetPage = false,
    bool showErrorMessage = false,
  }) async {
    if (resetPage) {
      _page = 1;
    }

    try {
      if (_isProductTab) {
        await context.read<ProductReviewProvider>().getProductReviews(
          page: _page,
          pageSize: _pageSize,
          search: ProductReviewSearchObject(
            rating: _rating == 0 ? null : _rating,
            commentFTS: _emptyToNull(_commentController.text),
          ),
        );
      } else {
        await context.read<StaffReviewProvider>().getStaffReviews(
          page: _page,
          pageSize: _pageSize,
          search: StaffReviewSearchObject(
            rating: _rating == 0 ? null : _rating,
            commentFTS: _emptyToNull(_commentController.text),
          ),
        );
      }
    } on CustomException catch (error) {
      if (showErrorMessage) {
        _showMessage(error.message, isError: true);
        return;
      }

      rethrow;
    } catch (_) {
      if (showErrorMessage) {
        _showMessage('Recenzije nisu mogle biti učitane.', isError: true);
        return;
      }

      rethrow;
    }
  }

  Future<void> _search() async {
    await _loadCurrentReviews(resetPage: true, showErrorMessage: true);
  }

  Future<void> _clearFilters() async {
    setState(() {
      _commentController.clear();
      _rating = 0;
    });

    await _loadCurrentReviews(resetPage: true, showErrorMessage: true);
  }

  Future<void> _changePage(int newPage) async {
    final previousPage = _page;

    setState(() => _page = newPage);

    try {
      await _loadCurrentReviews();
    } on CustomException catch (error) {
      if (mounted) {
        setState(() => _page = previousPage);
      }

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) {
        setState(() => _page = previousPage);
      }

      _showMessage(
        'Stranica recenzija nije mogla biti učitana.',
        isError: true,
      );
    }
  }

  Future<void> _deleteProductReview(ProductReview review) async {
    final confirmed = await _confirmDelete(
      title: 'Brisanje recenzije proizvoda',
      message:
          'Da li želite izbrisati recenziju proizvoda '
          '"${review.productName ?? 'Nepoznat proizvod'}"?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final provider = context.read<ProductReviewProvider>();
    final shouldGoBack = _page > 1 && provider.productReviews.length == 1;

    try {
      await provider.deleteProductReview(review.id);

      if (shouldGoBack) {
        _page--;
      }

      if (!mounted) {
        return;
      }

      await _loadCurrentReviews();
      _showMessage('Recenzija proizvoda je izbrisana.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Brisanje recenzije proizvoda nije uspjelo.', isError: true);
    }
  }

  Future<void> _deleteStaffReview(StaffReview review) async {
    final confirmed = await _confirmDelete(
      title: 'Brisanje recenzije zaposlenika',
      message:
          'Da li želite izbrisati recenziju zaposlenika '
          '"${review.employeeName ?? 'Nepoznat zaposlenik'}"?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final provider = context.read<StaffReviewProvider>();
    final shouldGoBack = _page > 1 && provider.staffReviews.length == 1;

    try {
      await provider.deleteStaffReview(review.id);

      if (shouldGoBack) {
        _page--;
      }

      if (!mounted) {
        return;
      }

      await _loadCurrentReviews();
      _showMessage('Recenzija zaposlenika je izbrisana.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage(
        'Brisanje recenzije zaposlenika nije uspjelo.',
        isError: true,
      );
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB3261E),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Izbriši'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF1B7F3A),
      ),
    );
  }

  int _totalPages(int count) {
    final total = (count / _pageSize).ceil();
    return total < 1 ? 1 : total;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _LoadError(message: _loadError!, onRetry: _loadInitialData);
    }

    final productProvider = context.watch<ProductReviewProvider>();
    final staffProvider = context.watch<StaffReviewProvider>();
    final canDelete = context.watch<AuthProvider>().isManager;

    final isLoading = _isProductTab
        ? productProvider.isLoading
        : staffProvider.isLoading;

    final count = _isProductTab
        ? productProvider.countOfItems
        : staffProvider.countOfItems;

    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              side: const BorderSide(color: Color(0xFFE2E7F0)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _primaryBlue,
              unselectedLabelColor: const Color(0xFF687385),
              indicatorColor: _primaryBlue,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                const Tab(
                  icon: Icon(Icons.inventory_2_outlined),
                  text: 'Recenzije proizvoda',
                ),
                if (widget.showStaffReviews)
                  const Tab(
                    icon: Icon(Icons.badge_outlined),
                    text: 'Recenzije zaposlenika',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          _buildToolbar(isLoading: isLoading, count: count),
          const SizedBox(height: AppPadding.medium),
          Expanded(
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isProductTab
                  ? _buildProductTable(
                      reviews: productProvider.productReviews,
                      canDelete: canDelete,
                    )
                  : _buildStaffTable(
                      reviews: staffProvider.staffReviews,
                      canDelete: canDelete,
                    ),
            ),
          ),
          const SizedBox(height: AppPadding.small),
          _buildPagination(
            isLoading: isLoading,
            totalPages: _totalPages(count),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar({required bool isLoading, required int count}) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _commentController,
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Pretraga komentara',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _commentController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Poništi unos',
                      onPressed: () {
                        setState(() => _commentController.clear());
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        SizedBox(
          width: 170,
          height: 52,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Ocjena',
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _rating,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Sve ocjene')),
                  DropdownMenuItem(value: 5, child: Text('5 zvjezdica')),
                  DropdownMenuItem(value: 4, child: Text('4 zvjezdice')),
                  DropdownMenuItem(value: 3, child: Text('3 zvjezdice')),
                  DropdownMenuItem(value: 2, child: Text('2 zvjezdice')),
                  DropdownMenuItem(value: 1, child: Text('1 zvjezdica')),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() => _rating = value ?? 0);
                      },
              ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        FilledButton.icon(
          onPressed: isLoading ? null : _search,
          icon: const Icon(Icons.search),
          label: const Text('Pretraži'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 52),
            backgroundColor: _primaryBlue,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        OutlinedButton.icon(
          onPressed: isLoading || !_hasFilters ? null : _clearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Očisti'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(110, 52)),
        ),
        const Spacer(),
        Text(
          'Ukupno: $count',
          style: const TextStyle(
            color: Color(0xFF687385),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProductTable({
    required List<ProductReview> reviews,
    required bool canDelete,
  }) {
    if (reviews.isEmpty) {
      return const _EmptyReviews(
        message: 'Nema pronađenih recenzija proizvoda.',
      );
    }

    return _ReviewTableContainer(
      horizontalScrollController: _horizontalScrollController,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F3FF)),
        horizontalMargin: 20,
        columnSpacing: 30,
        columns: [
          const DataColumn(label: Text('Kupac')),
          const DataColumn(label: Text('Proizvod')),
          const DataColumn(label: Text('Ocjena')),
          const DataColumn(label: Text('Komentar')),
          const DataColumn(label: Text('Datum')),
          if (canDelete) const DataColumn(label: Text('Akcije')),
        ],
        rows: reviews.map((review) {
          return DataRow(
            cells: [
              DataCell(Text(review.userName ?? 'Nepoznat kupac')),
              DataCell(
                Text(
                  review.productName ?? 'Nepoznat proizvod',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(_RatingStars(rating: review.rating)),
              DataCell(_ReviewComment(comment: review.comment)),
              DataCell(Text(_formatDateTime(review.createdAt))),
              if (canDelete)
                DataCell(
                  IconButton(
                    tooltip: 'Izbriši recenziju',
                    onPressed: () => _deleteProductReview(review),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB3261E),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStaffTable({
    required List<StaffReview> reviews,
    required bool canDelete,
  }) {
    if (reviews.isEmpty) {
      return const _EmptyReviews(
        message: 'Nema pronađenih recenzija zaposlenika.',
      );
    }

    return _ReviewTableContainer(
      horizontalScrollController: _horizontalScrollController,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F3FF)),
        horizontalMargin: 20,
        columnSpacing: 30,
        columns: [
          const DataColumn(label: Text('Kupac')),
          const DataColumn(label: Text('Zaposlenik')),
          const DataColumn(label: Text('Ocjena')),
          const DataColumn(label: Text('Komentar')),
          const DataColumn(label: Text('Datum')),
          if (canDelete) const DataColumn(label: Text('Akcije')),
        ],
        rows: reviews.map((review) {
          return DataRow(
            cells: [
              DataCell(Text(review.userName ?? 'Nepoznat kupac')),
              DataCell(
                Text(
                  review.employeeName ?? 'Nepoznat zaposlenik',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(_RatingStars(rating: review.rating)),
              DataCell(_ReviewComment(comment: review.comment)),
              DataCell(Text(_formatDateTime(review.createdAt))),
              if (canDelete)
                DataCell(
                  IconButton(
                    tooltip: 'Izbriši recenziju',
                    onPressed: () => _deleteStaffReview(review),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB3261E),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination({required bool isLoading, required int totalPages}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Prethodna stranica',
          onPressed: !isLoading && _page > 1
              ? () => _changePage(_page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Stranica $_page od $totalPages'),
        IconButton(
          tooltip: 'Sljedeća stranica',
          onPressed: !isLoading && _page < totalPages
              ? () => _changePage(_page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _ReviewTableContainer extends StatelessWidget {
  const _ReviewTableContainer({
    required this.horizontalScrollController,
    required this.child,
  });

  final ScrollController horizontalScrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1000
            ? 1000.0
            : constraints.maxWidth;

        return Scrollbar(
          controller: horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: SingleChildScrollView(child: child),
            ),
          ),
        );
      },
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int? rating;

  @override
  Widget build(BuildContext context) {
    final currentRating = (rating ?? 0).clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < currentRating ? Icons.star : Icons.star_border,
          size: 18,
          color: const Color(0xFFFFB300),
        );
      }),
    );
  }
}

class _ReviewComment extends StatelessWidget {
  const _ReviewComment({required this.comment});

  final String? comment;

  @override
  Widget build(BuildContext context) {
    final value = comment?.trim();

    return SizedBox(
      width: 330,
      child: Text(
        value == null || value.isEmpty ? 'Bez komentara' : value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.reviews_outlined,
            size: 52,
            color: Color(0xFF8B95A5),
          ),
          const SizedBox(height: AppPadding.medium),
          Text(message, style: const TextStyle(color: Color(0xFF687385))),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.extraLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: Color(0xFFB3261E),
              ),
              const SizedBox(height: AppPadding.medium),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppPadding.large),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? date) {
  if (date == null) {
    return '—';
  }

  final localDate = date.toLocal();

  String twoDigits(int value) => value.toString().padLeft(2, '0');

  return '${twoDigits(localDate.day)}.'
      '${twoDigits(localDate.month)}.'
      '${localDate.year}. '
      '${twoDigits(localDate.hour)}:'
      '${twoDigits(localDate.minute)}';
}
