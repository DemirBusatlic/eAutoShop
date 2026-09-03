import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/appointment/appointment.dart';
import 'package:eautoshop_desktop/models/appointment/appointment_confirm.dart';
import 'package:eautoshop_desktop/models/appointment_detail/appointment_detail.dart';
import 'package:eautoshop_desktop/models/appointment/appointment_search_object.dart';
import 'package:eautoshop_desktop/models/user/user.dart';
import 'package:eautoshop_desktop/providers/appointment_detail_provider.dart';
import 'package:eautoshop_desktop/providers/appointment_provider.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:eautoshop_desktop/providers/user_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  static const int _pageSize = 10;

  final TextEditingController _usernameController = TextEditingController();

  int _page = 1;
  String? _state;
  bool? _hasOrder;
  double? _minAmount;
  double? _maxAmount;
  DateTime? _minReservationDate;
  DateTime? _maxReservationDate;
  String? _employeeUsername;
  bool _initialLoading = true;
  String? _loadError;

  bool get _isManager => context.read<AuthProvider>().isManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
      _loadError = null;
    });

    try {
      final futures = <Future<void>>[_loadAppointments()];
      if (_isManager) {
        futures.add(context.read<UserProvider>().getTechnicians());
      }
      await Future.wait(futures);
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Rezervacije nije moguće učitati.';
    }

    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _loadAppointments({bool resetPage = false}) async {
    if (resetPage) _page = 1;

    await context.read<AppointmentProvider>().getAppointments(
      isManager: _isManager,
      page: _page,
      pageSize: _pageSize,
      search: AppointmentSearchObject(
        customerUsername: _isManager
            ? _emptyToNull(_usernameController.text)
            : null,
        employeeUsername: _isManager ? _employeeUsername : null,
        state: _state,
        minTotalAmount: _minAmount,
        maxTotalAmount: _maxAmount,
        hasOrder: _hasOrder,
        minReservationDate: _minReservationDate,
        maxReservationDate: _maxReservationDate == null
            ? null
            : _endOfDay(_maxReservationDate!),
      ),
    );
  }

  Future<void> _search() async {
    try {
      await _loadAppointments(resetPage: true);
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Rezervacije nije moguće učitati.', isError: true);
    }
  }

  Future<void> _clearSearch() async {
    _usernameController.clear();
    setState(() {});
    await _search();
  }

  Future<void> _openFilters() async {
    final result = await showDialog<_AppointmentFilters>(
      context: context,
      builder: (_) => _AppointmentFilterDialog(
        initial: _AppointmentFilters(
          state: _state,
          hasOrder: _hasOrder,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
          minReservationDate: _minReservationDate,
          maxReservationDate: _maxReservationDate,
          employeeUsername: _employeeUsername,
        ),
        showEmployeeFilter: _isManager,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _state = result.state;
      _hasOrder = result.hasOrder;
      _minAmount = result.minAmount;
      _maxAmount = result.maxAmount;
      _minReservationDate = result.minReservationDate;
      _maxReservationDate = result.maxReservationDate;
      _employeeUsername = result.employeeUsername;
    });
    await _search();
  }

  Future<void> _assignAppointment(Appointment appointment) async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.technicians.isEmpty) {
      _showMessage(
        'Nema aktivnih tehničara kojima se rezervacija može dodijeliti.',
        isError: true,
      );
      return;
    }

    final request = await showDialog<AppointmentConfirm>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignmentDialog(
        appointment: appointment,
        technicians: userProvider.technicians,
      ),
    );

    if (request == null || !mounted) return;

    try {
      await context.read<AppointmentProvider>().confirmAppointment(
        id: appointment.id,
        request: request,
      );
      await _loadAppointments();
      _showMessage('Rezervacija je potvrđena i dodijeljena tehničaru.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _rejectAppointment(Appointment appointment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );
    if (reason == null || !mounted) return;

    try {
      await context.read<AppointmentProvider>().rejectAppointment(
        id: appointment.id,
        reason: reason,
      );
      await _loadAppointments();
      _showMessage('Rezervacija je odbijena.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _startAppointment(Appointment appointment) async {
    final confirmed = await _confirm(
      title: 'Pokretanje rezervacije',
      message: 'Da li želite označiti da je rad na rezervaciji započeo?',
      confirmLabel: 'Pokreni',
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<AppointmentProvider>().startAppointment(
        appointment.id,
      );
      await _loadAppointments();
      _showMessage('Rad na rezervaciji je započet.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _updateEstimatedCompletion(Appointment appointment) async {
    final initial =
        appointment.estimatedCompletionDate?.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (_) => _DateTimeDialog(
        title: 'Procijenjeni završetak',
        initialValue: initial,
      ),
    );
    if (selected == null || !mounted) return;

    try {
      await context.read<AppointmentProvider>().updateEstimatedCompletion(
        id: appointment.id,
        estimatedCompletion: selected,
      );
      await _loadAppointments();
      _showMessage('Procijenjeno vrijeme završetka je ažurirano.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _completeAppointment(Appointment appointment) async {
    final confirmed = await _confirm(
      title: 'Završetak rezervacije',
      message: 'Da li je rad na ovoj rezervaciji završen?',
      confirmLabel: 'Završi',
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<AppointmentProvider>().completeAppointment(
        appointment.id,
      );
      await _loadAppointments();
      _showMessage('Rezervacija je označena kao završena.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _softDeleteAppointment(Appointment appointment) async {
    final confirmed = await _confirm(
      title: 'Uklanjanje rezervacije',
      message: 'Da li želite ukloniti rezervaciju iz prikaza autoservisa?',
      confirmLabel: 'Ukloni',
    );
    if (!confirmed || !mounted) return;

    try {
      final provider = context.read<AppointmentProvider>();
      await provider.softDeleteAppointment(appointment.id);
      if (_page > 1 && provider.appointments.length == 1) _page--;
      await _loadAppointments();
      _showMessage('Rezervacija je uklonjena iz prikaza.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _showDetails(Appointment appointment) async {
    final provider = context.read<AppointmentDetailProvider>();
    provider.clear();
    final detailsFuture = provider.getByAppointment(
      appointmentId: appointment.id,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<void>(
          future: detailsFuture,
          builder: (context, snapshot) {
            return AlertDialog(
              title: Text('Rezervacija #${appointment.id}'),
              content: SizedBox(
                width: 620,
                child: snapshot.connectionState != ConnectionState.done
                    ? const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : snapshot.hasError
                    ? const Padding(
                        padding: EdgeInsets.all(AppPadding.large),
                        child: Text('Detalje rezervacije nije moguće učitati.'),
                      )
                    : Consumer<AppointmentDetailProvider>(
                        builder: (context, detailsProvider, _) {
                          return _AppointmentDetails(
                            appointment: appointment,
                            details: detailsProvider.appointmentDetails,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Zatvori'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Odustani'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF1B7F3A),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  int _totalPages(int count) {
    final pages = (count / _pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  bool get _hasFilters =>
      _state != null ||
      _hasOrder != null ||
      _minAmount != null ||
      _maxAmount != null ||
      _minReservationDate != null ||
      _maxReservationDate != null ||
      _employeeUsername != null;

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(AppPadding.large),
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
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: AppPadding.large),
                FilledButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final provider = context.watch<AppointmentProvider>();
    final totalPages = _totalPages(provider.countOfItems);

    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(provider),
          const SizedBox(height: AppPadding.medium),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.appointments.isEmpty
                  ? const _EmptyAppointments()
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      itemCount: provider.appointments.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppPadding.small),
                      itemBuilder: (context, index) {
                        final appointment = provider.appointments[index];
                        return _AppointmentCard(
                          appointment: appointment,
                          isManager: _isManager,
                          onDetails: () => _showDetails(appointment),
                          onAssign: () => _assignAppointment(appointment),
                          onReject: () => _rejectAppointment(appointment),
                          onStart: () => _startAppointment(appointment),
                          onUpdateEstimated: () =>
                              _updateEstimatedCompletion(appointment),
                          onComplete: () => _completeAppointment(appointment),
                          onDelete: () => _softDeleteAppointment(appointment),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          _PaginationBar(
            page: _page,
            totalPages: totalPages,
            itemCount: provider.countOfItems,
            onPrevious: _page > 1 && !provider.isLoading
                ? () async {
                    setState(() => _page--);
                    await _loadAppointments();
                  }
                : null,
            onNext: _page < totalPages && !provider.isLoading
                ? () async {
                    setState(() => _page++);
                    await _loadAppointments();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppointmentProvider provider) {
    return Wrap(
      spacing: AppPadding.small,
      runSpacing: AppPadding.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_isManager)
          SizedBox(
            width: 300,
            child: TextField(
              controller: _usernameController,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Korisničko ime klijenta',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _usernameController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Očisti pretragu',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
              ),
            ),
          ),
        if (_isManager)
          FilledButton.icon(
            onPressed: provider.isLoading ? null : _search,
            icon: const Icon(Icons.search),
            label: const Text('Pretraži'),
          ),
        OutlinedButton.icon(
          onPressed: provider.isLoading ? null : _openFilters,
          icon: Badge(
            isLabelVisible: _hasFilters,
            smallSize: 8,
            child: const Icon(Icons.filter_alt_outlined),
          ),
          label: const Text('Filteri'),
        ),
        OutlinedButton.icon(
          onPressed: provider.isLoading ? null : _loadAppointments,
          icon: const Icon(Icons.refresh),
          label: const Text('Osvježi'),
        ),
        const SizedBox(width: AppPadding.small),
        Text(
          _isManager
              ? 'Sve rezervacije autoservisa'
              : 'Moje dodijeljene rezervacije',
          style: const TextStyle(
            color: Color(0xFF566174),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isManager,
    required this.onDetails,
    required this.onAssign,
    required this.onReject,
    required this.onStart,
    required this.onUpdateEstimated,
    required this.onComplete,
    required this.onDelete,
  });

  final Appointment appointment;
  final bool isManager;
  final VoidCallback onDetails;
  final VoidCallback onAssign;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onUpdateEstimated;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = appointment.state.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF2848C7),
            ),
          ),
          const SizedBox(width: AppPadding.medium),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${appointment.customerUsername} · ${appointment.carModel}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1B2430),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppPadding.small),
                    _StateChip(state: state),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Termin: ${_formatDateTime(appointment.reservationDate)}',
                  style: const TextStyle(color: Color(0xFF566174)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _InfoBlock(
              label: 'Tehničar',
              value: appointment.employeeUsername ?? 'Nije dodijeljen',
              icon: Icons.engineering_outlined,
            ),
          ),
          Expanded(
            flex: 2,
            child: _InfoBlock(
              label: 'Iznos i trajanje',
              value:
                  '${appointment.totalAmount.toStringAsFixed(2)} € · ${_formatDuration(appointment.totalDuration)}',
              icon: Icons.payments_outlined,
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Detalji',
                onPressed: onDetails,
                icon: const Icon(Icons.visibility_outlined),
              ),
              if (isManager && state == 'pending') ...[
                IconButton(
                  tooltip: 'Potvrdi i dodijeli',
                  onPressed: onAssign,
                  color: const Color(0xFF1B7F3A),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                ),
                IconButton(
                  tooltip: 'Odbij',
                  onPressed: onReject,
                  color: const Color(0xFFB3261E),
                  icon: const Icon(Icons.block_outlined),
                ),
              ],
              if (!isManager && state == 'confirmed')
                IconButton(
                  tooltip: 'Pokreni rad',
                  onPressed: onStart,
                  color: const Color(0xFF2848C7),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              if (!isManager && state == 'ongoing') ...[
                IconButton(
                  tooltip: 'Promijeni procijenjeni završetak',
                  onPressed: onUpdateEstimated,
                  color: const Color(0xFFE07A18),
                  icon: const Icon(Icons.schedule_outlined),
                ),
                IconButton(
                  tooltip: 'Označi završenom',
                  onPressed: onComplete,
                  color: const Color(0xFF1B7F3A),
                  icon: const Icon(Icons.task_alt_outlined),
                ),
              ],
              if (isManager &&
                  (state == 'completed' ||
                      state == 'rejected' ||
                      state == 'cancelled'))
                IconButton(
                  tooltip: 'Ukloni iz prikaza',
                  onPressed: onDelete,
                  color: const Color(0xFFB3261E),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF697386)),
        const SizedBox(width: AppPadding.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF7A8496), fontSize: 12),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1B2430),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _stateLabel(state),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({
    required this.appointment,
    required this.technicians,
  });

  final Appointment appointment;
  final List<User> technicians;

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _employeeId;
  DateTime? _estimatedCompletion;

  @override
  void initState() {
    super.initState();
    final minimum = widget.appointment.reservationDate.toLocal();
    final nowPlusHour = DateTime.now().add(const Duration(hours: 1));
    _estimatedCompletion = minimum.isAfter(nowPlusHour)
        ? minimum.add(const Duration(hours: 1))
        : nowPlusHour;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Potvrdi i dodijeli rezervaciju'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.appointment.customerUsername} · ${widget.appointment.carModel}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppPadding.large),
              DropdownButtonFormField<int>(
                initialValue: _employeeId,
                decoration: const InputDecoration(
                  labelText: 'Tehničar',
                  prefixIcon: Icon(Icons.engineering_outlined),
                  border: OutlineInputBorder(),
                ),
                items: widget.technicians.map((user) {
                  final fullName = '${user.name ?? ''} ${user.surname ?? ''}'
                      .trim();
                  final displayName = fullName.isEmpty
                      ? (user.username ?? 'Tehničar #${user.id}')
                      : '$fullName (${user.username ?? '-'})';
                  return DropdownMenuItem(
                    value: user.id,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _employeeId = value),
                validator: (value) =>
                    value == null ? 'Odaberite tehničara.' : null,
              ),
              const SizedBox(height: AppPadding.medium),
              InkWell(
                onTap: _pickEstimatedCompletion,
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Procijenjeni završetak',
                    prefixIcon: Icon(Icons.schedule_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatDateTime(_estimatedCompletion!)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('Potvrdi'),
        ),
      ],
    );
  }

  Future<void> _pickEstimatedCompletion() async {
    final result = await _pickDateTime(context, _estimatedCompletion!);
    if (result != null && mounted) {
      setState(() => _estimatedCompletion = result);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_estimatedCompletion!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procijenjeni završetak mora biti u budućnosti.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      AppointmentConfirm(
        employeeId: _employeeId!,
        estimatedCompletionDate: _estimatedCompletion,
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odbij rezervaciju'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Razlog odbijanja',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Unesite razlog odbijanja.'
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Odbij'),
        ),
      ],
    );
  }
}

class _DateTimeDialog extends StatefulWidget {
  const _DateTimeDialog({required this.title, required this.initialValue});

  final String title;
  final DateTime initialValue;

  @override
  State<_DateTimeDialog> createState() => _DateTimeDialogState();
}

class _DateTimeDialogState extends State<_DateTimeDialog> {
  late DateTime _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: InkWell(
          onTap: _pick,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Datum i vrijeme',
              prefixIcon: Icon(Icons.event_outlined),
              border: OutlineInputBorder(),
            ),
            child: Text(_formatDateTime(_value)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (!_value.isAfter(DateTime.now())) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datum mora biti u budućnosti.')),
              );
              return;
            }
            Navigator.pop(context, _value);
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Future<void> _pick() async {
    final result = await _pickDateTime(context, _value);
    if (result != null && mounted) setState(() => _value = result);
  }
}

class _AppointmentFilterDialog extends StatefulWidget {
  const _AppointmentFilterDialog({
    required this.initial,
    required this.showEmployeeFilter,
  });

  final _AppointmentFilters initial;
  final bool showEmployeeFilter;

  @override
  State<_AppointmentFilterDialog> createState() =>
      _AppointmentFilterDialogState();
}

class _AppointmentFilterDialogState extends State<_AppointmentFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  String? _state;
  bool? _hasOrder;
  DateTime? _minDate;
  DateTime? _maxDate;
  String? _employeeUsername;

  @override
  void initState() {
    super.initState();
    _state = widget.initial.state;
    _hasOrder = widget.initial.hasOrder;
    _minDate = widget.initial.minReservationDate;
    _maxDate = widget.initial.maxReservationDate;
    _employeeUsername = widget.initial.employeeUsername;
    _minController = TextEditingController(
      text: widget.initial.minAmount?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initial.maxAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final technicians = context.watch<UserProvider>().technicians;

    return AlertDialog(
      title: const Text('Filteri rezervacija'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _state,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Na čekanju'),
                    ),
                    DropdownMenuItem(
                      value: 'confirmed',
                      child: Text('Potvrđena'),
                    ),
                    DropdownMenuItem(value: 'ongoing', child: Text('U toku')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Završena'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Odbijena'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Otkazana'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _state = value),
                ),
                const SizedBox(height: AppPadding.medium),
                if (widget.showEmployeeFilter) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _employeeUsername,
                    decoration: const InputDecoration(
                      labelText: 'Dodijeljeni tehničar',
                      border: OutlineInputBorder(),
                    ),
                    items: technicians
                        .where((user) => user.username != null)
                        .map(
                          (user) => DropdownMenuItem(
                            value: user.username,
                            child: Text(
                              '${user.name ?? ''} ${user.surname ?? ''} (${user.username})'
                                  .trim(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _employeeUsername = value),
                  ),
                  const SizedBox(height: AppPadding.medium),
                ],
                DropdownButtonFormField<bool>(
                  initialValue: _hasOrder,
                  decoration: const InputDecoration(
                    labelText: 'Povezana narudžba',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Da')),
                    DropdownMenuItem(value: false, child: Text('Ne')),
                  ],
                  onChanged: (value) => setState(() => _hasOrder = value),
                ),
                const SizedBox(height: AppPadding.medium),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Minimalni iznos',
                          suffixText: '€',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateAmount,
                      ),
                    ),
                    const SizedBox(width: AppPadding.medium),
                    Expanded(
                      child: TextFormField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Maksimalni iznos',
                          suffixText: '€',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateAmount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.medium),
                Row(
                  children: [
                    Expanded(
                      child: _DateFilterField(
                        label: 'Termin od',
                        value: _minDate,
                        onTap: () => _pickDate(isMinimum: true),
                        onClear: () => setState(() => _minDate = null),
                      ),
                    ),
                    const SizedBox(width: AppPadding.medium),
                    Expanded(
                      child: _DateFilterField(
                        label: 'Termin do',
                        value: _maxDate,
                        onTap: () => _pickDate(isMinimum: false),
                        onClear: () => setState(() => _maxDate = null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _clear, child: const Text('Očisti filtere')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(onPressed: _apply, child: const Text('Primijeni')),
      ],
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Unesite ispravan iznos.';
    return null;
  }

  Future<void> _pickDate({required bool isMinimum}) async {
    final initial = isMinimum ? _minDate : _maxDate;
    final result = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null && mounted) {
      setState(() {
        if (isMinimum) {
          _minDate = result;
        } else {
          _maxDate = result;
        }
      });
    }
  }

  void _clear() {
    setState(() {
      _state = null;
      _hasOrder = null;
      _minDate = null;
      _maxDate = null;
      _employeeUsername = null;
      _minController.clear();
      _maxController.clear();
    });
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;

    final min = _parseAmount(_minController.text);
    final max = _parseAmount(_maxController.text);
    if (min != null && max != null && min > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimalni iznos ne može biti veći od maksimalnog.'),
        ),
      );
      return;
    }
    if (_minDate != null && _maxDate != null && _minDate!.isAfter(_maxDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Početni datum mora biti prije završnog.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _AppointmentFilters(
        state: _state,
        hasOrder: _hasOrder,
        minAmount: min,
        maxAmount: max,
        minReservationDate: _minDate,
        maxReservationDate: _maxDate,
        employeeUsername: _employeeUsername,
      ),
    );
  }

  double? _parseAmount(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Očisti datum',
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                ),
          border: const OutlineInputBorder(),
        ),
        child: Text(value == null ? 'Nije odabrano' : _formatDate(value!)),
      ),
    );
  }
}

class _AppointmentDetails extends StatelessWidget {
  const _AppointmentDetails({required this.appointment, required this.details});

  final Appointment appointment;
  final List<AppointmentDetail> details;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppPadding.large,
            runSpacing: AppPadding.small,
            children: [
              _DetailText(
                label: 'Klijent',
                value: appointment.customerUsername,
              ),
              _DetailText(label: 'Vozilo', value: appointment.carModel),
              _DetailText(
                label: 'Tehničar',
                value: appointment.employeeUsername ?? 'Nije dodijeljen',
              ),
              _DetailText(
                label: 'Termin',
                value: _formatDateTime(appointment.reservationDate),
              ),
              _DetailText(
                label: 'Procijenjeni završetak',
                value: appointment.estimatedCompletionDate == null
                    ? 'Nije određeno'
                    : _formatDateTime(appointment.estimatedCompletionDate!),
              ),
              _DetailText(
                label: 'Ukupno',
                value: '${appointment.totalAmount.toStringAsFixed(2)} €',
              ),
            ],
          ),
          if (appointment.rejectionReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppPadding.medium),
            _ReasonBox(
              title: 'Razlog odbijanja',
              value: appointment.rejectionReason!,
            ),
          ],
          if (appointment.cancellationReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppPadding.medium),
            _ReasonBox(
              title: 'Razlog otkazivanja',
              value: appointment.cancellationReason!,
            ),
          ],
          const SizedBox(height: AppPadding.large),
          const Text(
            'Odabrane usluge',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppPadding.small),
          if (details.isEmpty)
            const Text('Nema evidentiranih usluga.')
          else
            ...details.map(
              (detail) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.build_outlined, size: 19),
                ),
                title: Text(detail.serviceName.toString()),
                subtitle: detail.serviceDiscount > 0
                    ? Text('Popust: ${detail.serviceDiscount}%')
                    : null,
                trailing: Text(
                  '${detail.serviceDiscountedPrice.toStringAsFixed(2)} €',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF7A8496))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Text('$title: $value'),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.itemCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int itemCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Ukupno rezervacija: $itemCount',
          style: const TextStyle(color: Color(0xFF566174)),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Prethodna stranica',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          'Stranica $page od $totalPages',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        IconButton(
          tooltip: 'Sljedeća stranica',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined, size: 58, color: Color(0xFF9AA4B2)),
          SizedBox(height: AppPadding.medium),
          Text(
            'Nema rezervacija za odabrane kriterije.',
            style: TextStyle(color: Color(0xFF566174), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _AppointmentFilters {
  const _AppointmentFilters({
    this.state,
    this.hasOrder,
    this.minAmount,
    this.maxAmount,
    this.minReservationDate,
    this.maxReservationDate,
    this.employeeUsername,
  });

  final String? state;
  final bool? hasOrder;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? minReservationDate;
  final DateTime? maxReservationDate;
  final String? employeeUsername;
}

Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.'
      '${local.month.toString().padLeft(2, '0')}.'
      '${local.year}.';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_formatDate(local)} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatDuration(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

String _stateLabel(String state) {
  switch (state.toLowerCase()) {
    case 'pending':
      return 'Na čekanju';
    case 'confirmed':
      return 'Potvrđena';
    case 'ongoing':
      return 'U toku';
    case 'completed':
      return 'Završena';
    case 'rejected':
      return 'Odbijena';
    case 'cancelled':
      return 'Otkazana';
    default:
      return state;
  }
}

Color _stateColor(String state) {
  switch (state.toLowerCase()) {
    case 'pending':
      return const Color(0xFFE07A18);
    case 'confirmed':
      return const Color(0xFF2848C7);
    case 'ongoing':
      return const Color(0xFF7B3FC6);
    case 'completed':
      return const Color(0xFF1B7F3A);
    case 'rejected':
    case 'cancelled':
      return const Color(0xFFB3261E);
    default:
      return const Color(0xFF566174);
  }
}
