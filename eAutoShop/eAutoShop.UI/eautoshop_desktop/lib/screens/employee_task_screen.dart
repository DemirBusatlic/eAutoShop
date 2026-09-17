import 'package:eautoshop_desktop/models/employee_task/employee_task.dart';
import 'package:eautoshop_desktop/models/employee_task/employee_task_insert.dart';
import 'package:eautoshop_desktop/models/employee_task/employee_task_search_object.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:eautoshop_desktop/providers/employee_task_provider.dart';
import 'package:eautoshop_desktop/providers/user_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EmployeeTaskScreen extends StatefulWidget {
  const EmployeeTaskScreen({super.key});

  @override
  State<EmployeeTaskScreen> createState() => _EmployeeTaskScreenState();
}

class _EmployeeTaskScreenState extends State<EmployeeTaskScreen> {
  static const int _pageSize = 10;
  static const Color _primaryBlue = Color(0xFF2848C7);

  final TextEditingController _titleController = TextEditingController();

  int _page = 1;
  String? _selectedState;
  bool _initialLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
      await _loadTasks();
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Zaduženja nisu mogla biti učitana.';
    }

    if (mounted) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadTasks({bool resetPage = false}) async {
    if (resetPage) {
      _page = 1;
    }

    final authProvider = context.read<AuthProvider>();

    await context.read<EmployeeTaskProvider>().getTasks(
      isManager: authProvider.isManager,
      page: _page,
      pageSize: _pageSize,
      search: EmployeeTaskSearchObject(
        titleFTS: _emptyToNull(_titleController.text),
        state: _selectedState,
      ),
    );
  }

  Future<void> _search() async {
    try {
      await _loadTasks(resetPage: true);
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Pretraga zaduženja nije uspjela.', isError: true);
    }
  }

  Future<void> _clearFilters() async {
    setState(() {
      _titleController.clear();
      _selectedState = null;
    });

    await _search();
  }

  Future<void> _changePage(int newPage) async {
    final previousPage = _page;

    setState(() => _page = newPage);

    try {
      await _loadTasks();
    } catch (_) {
      if (mounted) {
        setState(() => _page = previousPage);
      }

      _showMessage(
        'Stranica zaduženja nije mogla biti učitana.',
        isError: true,
      );
    }
  }

  Future<void> _openCreateDialog() async {
    final request = await showDialog<EmployeeTaskInsert>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _EmployeeTaskCreateDialog(),
    );

    if (request == null || !mounted) {
      return;
    }

    try {
      await context.read<EmployeeTaskProvider>().createTask(request);

      if (!mounted) {
        return;
      }

      await _loadTasks(resetPage: true);

      _showMessage('Zaduženje je uspješno kreirano.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Zaduženje nije moglo biti kreirano.', isError: true);
    }
  }

  Future<void> _completeTask(EmployeeTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Završavanje zaduženja'),
          content: Text(
            'Da li želite označiti zaduženje '
            '"${task.title}" kao završeno?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Završi'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await context.read<EmployeeTaskProvider>().completeTask(task.id);

      if (!mounted) {
        return;
      }

      await _loadTasks();

      _showMessage('Zaduženje je uspješno završeno.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Zaduženje nije moglo biti završeno.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<EmployeeTaskProvider>();

    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    final totalPages = provider.countOfItems == 0
        ? 1
        : (provider.countOfItems / _pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFilters(
            isLoading: provider.isLoading,
            isManager: authProvider.isManager,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.tasks.isEmpty
                ? const Center(child: Text('Nema pronađenih zaduženja.'))
                : ListView.separated(
                    itemCount: provider.tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildTaskCard(
                        provider.tasks[index],
                        isManager: authProvider.isManager,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          _buildPagination(
            totalPages: totalPages,
            totalItems: provider.countOfItems,
            isLoading: provider.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters({required bool isLoading, required bool isManager}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _titleController,
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
              labelText: 'Pretraga po naslovu',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String?>(
            initialValue: _selectedState,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Svi statusi'),
              ),
              DropdownMenuItem<String?>(
                value: 'active',
                child: Text('Aktivno'),
              ),
              DropdownMenuItem<String?>(
                value: 'completed',
                child: Text('Završeno'),
              ),
            ],
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() => _selectedState = value);
                  },
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: isLoading ? null : _search,
          icon: const Icon(Icons.search),
          label: const Text('Pretraži'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: isLoading ? null : _clearFilters,
          icon: const Icon(Icons.clear),
          label: const Text('Očisti'),
        ),
        if (isManager) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: isLoading ? null : _openCreateDialog,
            icon: const Icon(Icons.add_task),
            label: const Text('Novo zaduženje'),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskCard(EmployeeTask task, {required bool isManager}) {
    final isCompleted = task.state == 'completed';

    final isOverdue =
        !isCompleted &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isCompleted
                  ? Colors.green.shade50
                  : isOverdue
                  ? Colors.red.shade50
                  : const Color(0xFFF0F3FF),
              child: Icon(
                isCompleted
                    ? Icons.task_alt
                    : isOverdue
                    ? Icons.warning_amber
                    : Icons.assignment_outlined,
                color: isCompleted
                    ? Colors.green
                    : isOverdue
                    ? Colors.red
                    : _primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildStateChip(task.state),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(task.description),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _buildInfo(
                        Icons.person_outline,
                        'Radnik: ${task.employeeName}',
                      ),
                      _buildInfo(
                        Icons.supervisor_account_outlined,
                        'Kreirao: ${task.createdByName}',
                      ),
                      _buildInfo(
                        Icons.event_outlined,
                        task.dueDate == null
                            ? 'Bez roka'
                            : 'Rok: ${_formatDate(task.dueDate!)}',
                        color: isOverdue ? Colors.red : null,
                      ),
                      if (task.completedAt != null)
                        _buildInfo(
                          Icons.check_circle_outline,
                          'Završeno: ${_formatDate(task.completedAt!)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isManager && !isCompleted) ...[
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _completeTask(task),
                icon: const Icon(Icons.check),
                label: const Text('Završi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(String state) {
    final isCompleted = state == 'completed';

    return Chip(
      label: Text(isCompleted ? 'Završeno' : 'Aktivno'),
      backgroundColor: isCompleted
          ? Colors.green.shade50
          : const Color(0xFFF0F3FF),
      labelStyle: TextStyle(
        color: isCompleted ? Colors.green.shade800 : _primaryBlue,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
    );
  }

  Widget _buildInfo(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color ?? Colors.blueGrey),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color ?? Colors.blueGrey.shade700)),
      ],
    );
  }

  Widget _buildPagination({
    required int totalPages,
    required int totalItems,
    required bool isLoading,
  }) {
    return Row(
      children: [
        Text('Ukupno zaduženja: $totalItems'),
        const Spacer(),
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

  String _formatDate(DateTime value) {
    return DateFormat('dd.MM.yyyy. HH:mm').format(value.toLocal());
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }
}

class _EmployeeTaskCreateDialog extends StatefulWidget {
  const _EmployeeTaskCreateDialog();

  @override
  State<_EmployeeTaskCreateDialog> createState() =>
      _EmployeeTaskCreateDialogState();
}

class _EmployeeTaskCreateDialogState extends State<_EmployeeTaskCreateDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  int? _employeeId;
  DateTime? _dueDate;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployees();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await context.read<UserProvider>().getEmployees(active: true);
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Zaposlenici nisu mogli biti učitani.';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    final initialDate = _dueDate ?? now.add(const Duration(days: 1));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate == null
          ? const TimeOfDay(hour: 16, minute: 0)
          : TimeOfDay.fromDateTime(_dueDate!),
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _dueDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      EmployeeTaskInsert(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        employeeId: _employeeId!,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return AlertDialog(
      title: const Text('Novo zaduženje'),
      content: SizedBox(width: 560, child: _buildContent(userProvider)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        if (!_isLoading &&
            _loadError == null &&
            userProvider.employees.isNotEmpty)
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add_task),
            label: const Text('Kreiraj'),
          ),
      ],
    );
  }

  Widget _buildContent(UserProvider userProvider) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return SizedBox(
        height: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadEmployees,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    if (userProvider.employees.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Nema aktivnih prodavača ili tehničara.')),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Naslov',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Unesite naslov zaduženja.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLength: 1000,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Opis',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Unesite opis zaduženja.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _employeeId,
              decoration: const InputDecoration(
                labelText: 'Zaposlenik',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: userProvider.employees.map((employee) {
                final name =
                    '${employee.name ?? ''} '
                            '${employee.surname ?? ''}'
                        .trim();

                final role = employee.roleName == 'technician'
                    ? 'tehničar'
                    : 'prodavač';

                return DropdownMenuItem<int>(
                  value: employee.id,
                  child: Text('$name ($role)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _employeeId = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Odaberite zaposlenika.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'Rok nije postavljen'
                        : 'Rok: ${DateFormat('dd.MM.yyyy. HH:mm').format(_dueDate!)}',
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDueDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _dueDate == null ? 'Postavi rok' : 'Promijeni rok',
                  ),
                ),
                if (_dueDate != null)
                  IconButton(
                    tooltip: 'Ukloni rok',
                    onPressed: () {
                      setState(() => _dueDate = null);
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
