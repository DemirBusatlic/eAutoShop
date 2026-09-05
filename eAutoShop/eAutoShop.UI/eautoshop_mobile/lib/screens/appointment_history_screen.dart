import 'package:eautoshop_mobile/models/appointment/appointment.dart';
import 'package:eautoshop_mobile/models/appointment/appointment_search_object.dart';
import 'package:eautoshop_mobile/models/appointment/appointment_update.dart';
import 'package:eautoshop_mobile/models/staff_review/staff_review.dart';
import 'package:eautoshop_mobile/models/staff_review/staff_review_insert.dart';
import 'package:eautoshop_mobile/models/staff_review/staff_review_update.dart';
import 'package:eautoshop_mobile/providers/appointment_detail_provider.dart';
import 'package:eautoshop_mobile/providers/appointment_provider.dart';
import 'package:eautoshop_mobile/providers/staff_review_provider.dart';
import 'package:eautoshop_mobile/screens/master_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<AppointmentHistoryScreen> {
  static const int _pageSize = 10;

  final TextEditingController _minAmountController = TextEditingController();

  final TextEditingController _maxAmountController = TextEditingController();

  int _pageNumber = 1;
  int _totalPages = 1;

  String? _selectedState;
  bool? _hasOrder;
  DateTime? _minReservationDate;
  DateTime? _maxReservationDate;

  String? _appointmentsError;
  bool _filtersApplied = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  AppointmentSearchObject _createSearchObject() {
    final minAmount = double.tryParse(_minAmountController.text.trim());

    final maxAmount = double.tryParse(_maxAmountController.text.trim());

    DateTime? maxReservationDate;

    if (_maxReservationDate != null) {
      maxReservationDate = DateTime(
        _maxReservationDate!.year,
        _maxReservationDate!.month,
        _maxReservationDate!.day,
        23,
        59,
        59,
      );
    }

    return AppointmentSearchObject(
      state: _selectedState,
      minTotalAmount: minAmount,
      maxTotalAmount: maxAmount,
      hasOrder: _hasOrder,
      minReservationDate: _minReservationDate,
      maxReservationDate: maxReservationDate,
    );
  }

  Future<void> _loadAppointments() async {
    if (mounted) {
      setState(() {
        _appointmentsError = null;
      });
    }

    try {
      final provider = context.read<AppointmentProvider>();

      await provider.getByCustomer(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        appointmentSearch: _createSearchObject(),
      );

      if (!mounted) {
        return;
      }

      final calculatedPages = (provider.countOfItems / _pageSize).ceil();

      setState(() {
        _totalPages = calculatedPages < 1 ? 1 : calculatedPages;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _appointmentsError = error.toString();
        _totalPages = 1;
      });
    }
  }

  Future<void> _changePage(int page) async {
    if (page < 1 || page > _totalPages || page == _pageNumber) {
      return;
    }

    setState(() {
      _pageNumber = page;
    });

    await _loadAppointments();
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd.MM.yyyy. HH:mm').format(value.toLocal());
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd.MM.yyyy.').format(value.toLocal());
  }

  String _statusText(String state) {
    switch (state) {
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

  Color _statusColor(String state) {
    switch (state) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'ongoing':
        return Colors.deepOrange;
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    String? draftState = _selectedState;
    String draftOrderFilter = _hasOrder == null
        ? 'all'
        : _hasOrder!
        ? 'withOrder'
        : 'withoutOrder';

    DateTime? draftMinDate = _minReservationDate;
    DateTime? draftMaxDate = _maxReservationDate;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Filteri rezervacija'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: draftState,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Svi statusi'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Na čekanju'),
                          ),
                          DropdownMenuItem(
                            value: 'confirmed',
                            child: Text('Potvrđene'),
                          ),
                          DropdownMenuItem(
                            value: 'ongoing',
                            child: Text('U toku'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Završene'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Odbijene'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Otkazane'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftState = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: draftOrderFilter,
                        decoration: const InputDecoration(
                          labelText: 'Povezana narudžba',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Sve rezervacije'),
                          ),
                          DropdownMenuItem(
                            value: 'withOrder',
                            child: Text('S narudžbom'),
                          ),
                          DropdownMenuItem(
                            value: 'withoutOrder',
                            child: Text('Bez narudžbe'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftOrderFilter = value ?? 'all';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _minAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Minimalan iznos',
                          suffixText: '€',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _maxAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Maksimalan iznos',
                          suffixText: '€',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Datum od'),
                        subtitle: Text(
                          draftMinDate == null
                              ? 'Nije odabran'
                              : _formatDate(draftMinDate!),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            draftMinDate == null
                                ? Icons.calendar_month
                                : Icons.clear,
                          ),
                          onPressed: () async {
                            if (draftMinDate != null) {
                              setModalState(() {
                                draftMinDate = null;
                              });
                              return;
                            }

                            final selected = await showDatePicker(
                              context: dialogContext,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (selected != null) {
                              setModalState(() {
                                draftMinDate = selected;

                                if (draftMaxDate != null &&
                                    draftMaxDate!.isBefore(selected)) {
                                  draftMaxDate = null;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Datum do'),
                        subtitle: Text(
                          draftMaxDate == null
                              ? 'Nije odabran'
                              : _formatDate(draftMaxDate!),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            draftMaxDate == null
                                ? Icons.calendar_month
                                : Icons.clear,
                          ),
                          onPressed: () async {
                            if (draftMaxDate != null) {
                              setModalState(() {
                                draftMaxDate = null;
                              });
                              return;
                            }

                            final selected = await showDatePicker(
                              context: dialogContext,
                              initialDate: draftMinDate ?? DateTime.now(),
                              firstDate: draftMinDate ?? DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (selected != null) {
                              setModalState(() {
                                draftMaxDate = selected;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _minAmountController.clear();
                    _maxAmountController.clear();

                    setModalState(() {
                      draftState = null;
                      draftOrderFilter = 'all';
                      draftMinDate = null;
                      draftMaxDate = null;
                    });
                  },
                  child: const Text('Očisti'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  onPressed: () {
                    final minAmount = double.tryParse(
                      _minAmountController.text.trim(),
                    );

                    final maxAmount = double.tryParse(
                      _maxAmountController.text.trim(),
                    );

                    if (_minAmountController.text.trim().isNotEmpty &&
                        minAmount == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Minimalan iznos nije ispravan.'),
                        ),
                      );
                      return;
                    }

                    if (_maxAmountController.text.trim().isNotEmpty &&
                        maxAmount == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Maksimalan iznos nije ispravan.'),
                        ),
                      );
                      return;
                    }

                    if (minAmount != null &&
                        maxAmount != null &&
                        minAmount > maxAmount) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Minimalan iznos ne može biti veći od maksimalnog.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _selectedState = draftState;
                      _hasOrder = draftOrderFilter == 'all'
                          ? null
                          : draftOrderFilter == 'withOrder';

                      _minReservationDate = draftMinDate;
                      _maxReservationDate = draftMaxDate;
                      _pageNumber = 1;

                      _filtersApplied =
                          _selectedState != null ||
                          _hasOrder != null ||
                          _minAmountController.text.trim().isNotEmpty ||
                          _maxAmountController.text.trim().isNotEmpty ||
                          _minReservationDate != null ||
                          _maxReservationDate != null;
                    });

                    Navigator.pop(dialogContext);
                    _loadAppointments();
                  },
                  child: const Text('Primijeni'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showUpdateDialog(Appointment appointment) async {
    final current = appointment.reservationDate.toLocal();

    DateTime selectedDate = DateTime(current.year, current.month, current.day);

    TimeOfDay selectedTime = TimeOfDay.fromDateTime(current);
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Promjena termina'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text(_formatDate(selectedDate)),
                    onPressed: submitting
                        ? null
                        : () async {
                            final result = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(DateTime.now().year + 2),
                            );

                            if (result != null) {
                              setModalState(() {
                                selectedDate = result;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(selectedTime.format(context)),
                    onPressed: submitting
                        ? null
                        : () async {
                            final result = await showTimePicker(
                              context: dialogContext,
                              initialTime: selectedTime,
                            );

                            if (result != null) {
                              setModalState(() {
                                selectedTime = result;
                              });
                            }
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final localDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          if (!localDateTime.isAfter(DateTime.now())) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Termin mora biti u budućnosti.'),
                              ),
                            );
                            return;
                          }

                          setModalState(() {
                            submitting = true;
                          });

                          try {
                            await this.context
                                .read<AppointmentProvider>()
                                .updateAppointment(
                                  id: appointment.id,
                                  appointment: AppointmentUpdate(
                                    reservationDate: localDateTime.toUtc(),
                                  ),
                                );

                            if (!mounted || !dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(dialogContext);
                            await _loadAppointments();

                            if (!mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Termin je uspješno promijenjen.',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );

                            if (dialogContext.mounted) {
                              setModalState(() {
                                submitting = false;
                              });
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sačuvaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showStaffReviewDialog(
    Appointment appointment, {
    StaffReview? existingReview,
  }) async {
    if (appointment.employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rezervaciji nije dodijeljen zaposlenik.'),
        ),
      );
      return false;
    }

    final isEditing = existingReview != null;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _StaffReviewDialog(
          appointment: appointment,
          existingReview: existingReview,
        );
      },
    );

    if (saved == true && mounted) {
      await _loadAppointments();

      if (!mounted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Recenzija zaposlenika je uspješno izmijenjena.'
                : 'Hvala! Recenzija zaposlenika je uspješno sačuvana.',
          ),
        ),
      );
    }

    return saved == true;
  }

  Future<bool> _editStaffReview(Appointment appointment) async {
    try {
      final review = await context.read<StaffReviewProvider>().getByAppointment(
        appointment.id,
      );

      if (!mounted) {
        return false;
      }

      if (review == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recenzija nije pronađena.')),
        );
        return false;
      }

      return await _showStaffReviewDialog(appointment, existingReview: review);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }

      return false;
    }
  }

  Future<bool> _deleteStaffReview(Appointment appointment) async {
    try {
      final review = await context.read<StaffReviewProvider>().getByAppointment(
        appointment.id,
      );

      if (!mounted) {
        return false;
      }

      if (review == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recenzija nije pronađena.')),
        );
        return false;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Brisanje recenzije'),
            content: const Text(
              'Da li ste sigurni da želite obrisati recenziju zaposlenika?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Odustani'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Obriši'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return false;
      }

      await context.read<StaffReviewProvider>().deleteReview(review.id);
      await _loadAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recenzija zaposlenika je uspješno obrisana.'),
          ),
        );
      }

      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }

      return false;
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    var reasonValue = '';

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Otkazivanje rezervacije'),
          content: TextFormField(
            initialValue: reasonValue,
            maxLength: 500,
            maxLines: 3,
            onChanged: (value) {
              reasonValue = value;
            },
            decoration: const InputDecoration(
              labelText: 'Razlog otkazivanja',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: () {
                final value = reasonValue.trim();

                if (value.isEmpty) {
                  return;
                }

                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Otkaži rezervaciju'),
            ),
          ],
        );
      },
    );

    if (reason == null || !mounted) {
      return;
    }

    try {
      await context.read<AppointmentProvider>().cancel(
        id: appointment.id,
        reason: reason,
      );

      await _loadAppointments();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rezervacija je otkazana.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Brisanje iz historije'),
          content: const Text(
            'Da li želite ukloniti ovu rezervaciju iz historije?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Ne'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Da'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await context.read<AppointmentProvider>().softDelete(appointment.id);

      await _loadAppointments();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija je uklonjena iz historije.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showDetails(Appointment appointment) async {
    try {
      final provider = context.read<AppointmentDetailProvider>();

      await provider.getByAppointment(appointmentId: appointment.id);

      if (!mounted) {
        return;
      }

      final details = List.of(provider.appointmentDetails);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Rezervacija #${appointment.id}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _detailRow('Status', _statusText(appointment.state)),
                    _detailRow(
                      'Termin',
                      _formatDateTime(appointment.reservationDate),
                    ),
                    _detailRow('Vozilo', appointment.carModel),
                    _detailRow(
                      'Ukupan iznos',
                      '${appointment.totalAmount.toStringAsFixed(2)} €',
                    ),
                    _detailRow('Trajanje', appointment.totalDuration),
                    _detailRow(
                      'Zaposlenik',
                      appointment.employeeUsername ?? 'Još nije dodijeljen',
                    ),
                    if (appointment.orderId != null)
                      _detailRow('Narudžba', '#${appointment.orderId}'),
                    if (appointment.estimatedCompletionDate != null)
                      _detailRow(
                        'Procijenjeni završetak',
                        _formatDateTime(appointment.estimatedCompletionDate!),
                      ),
                    if (appointment.completionDate != null)
                      _detailRow(
                        'Završeno',
                        _formatDateTime(appointment.completionDate!),
                      ),
                    if (appointment.rejectionReason?.trim().isNotEmpty == true)
                      _detailRow(
                        'Razlog odbijanja',
                        appointment.rejectionReason!,
                      ),
                    if (appointment.cancellationReason?.trim().isNotEmpty ==
                        true)
                      _detailRow(
                        'Razlog otkazivanja',
                        appointment.cancellationReason!,
                      ),
                    const Divider(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Usluge',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (details.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Detalji usluga nisu dostupni.'),
                      )
                    else
                      ...details.map(
                        (detail) => Card(
                          child: ListTile(
                            title: Text(detail.serviceName),
                            subtitle: Text(
                              detail.serviceDiscount > 0
                                  ? 'Popust: ${(detail.serviceDiscount * 100).toStringAsFixed(0)}%'
                                  : 'Bez popusta',
                            ),
                            trailing: Text(
                              '${detail.serviceDiscountedPrice.toStringAsFixed(2)} €',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              if (appointment.state.toLowerCase() == 'completed' &&
                  appointment.employeeId != null &&
                  !appointment.hasStaffReview)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showStaffReviewDialog(appointment);
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Ocijeni zaposlenika'),
                ),
              if (appointment.state.toLowerCase() == 'completed' &&
                  appointment.employeeId != null &&
                  appointment.hasStaffReview)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _editStaffReview(appointment);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Uredi recenziju'),
                ),
              if (appointment.state.toLowerCase() == 'completed' &&
                  appointment.employeeId != null &&
                  appointment.hasStaffReview)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _deleteStaffReview(appointment);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Obriši recenziju'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (appointment.state == 'pending')
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showUpdateDialog(appointment);
                  },
                  child: const Text('Promijeni termin'),
                ),
              if (appointment.state == 'pending')
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _cancelAppointment(appointment);
                  },
                  child: const Text('Otkaži'),
                ),
              if (appointment.state == 'completed' ||
                  appointment.state == 'rejected' ||
                  appointment.state == 'cancelled')
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _deleteAppointment(appointment);
                  },
                  child: const Text('Ukloni'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Zatvori'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list),
                      label: Text(
                        _filtersApplied ? 'Filteri aktivni' : 'Filteri',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _loadAppointments,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AppointmentProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_appointmentsError != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _appointmentsError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadAppointments,
                              child: const Text('Pokušaj ponovo'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.appointments.isEmpty) {
                    return Center(
                      child: Text(
                        _filtersApplied
                            ? 'Nema rezervacija koje odgovaraju filterima.'
                            : 'Još nemate rezervacija.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.appointments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final appointment = provider.appointments[index];

                      return Card(
                        child: ListTile(
                          onTap: () => _showDetails(appointment),
                          leading: CircleAvatar(
                            child: Text(appointment.id.toString()),
                          ),
                          title: Text(
                            'Rezervacija #${appointment.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(appointment.reservationDate),
                              ),
                              Text(
                                appointment.carModel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${appointment.totalAmount.toStringAsFixed(2)} €',
                              ),
                              Text(
                                _statusText(appointment.state),
                                style: TextStyle(
                                  color: _statusColor(appointment.state),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.info_outline),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading || provider.appointments.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _pageNumber > 1
                            ? () => _changePage(_pageNumber - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Stranica $_pageNumber od $_totalPages'),
                      IconButton(
                        onPressed: _pageNumber < _totalPages
                            ? () => _changePage(_pageNumber + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }
}

class _StaffReviewDialog extends StatefulWidget {
  final Appointment appointment;
  final StaffReview? existingReview;

  const _StaffReviewDialog({required this.appointment, this.existingReview});

  @override
  State<_StaffReviewDialog> createState() => _StaffReviewDialogState();
}

class _StaffReviewDialogState extends State<_StaffReviewDialog> {
  late final TextEditingController _commentController;

  int _rating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();

    _rating = widget.existingReview?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Izaberite ocjenu od 1 do 5.';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<StaffReviewProvider>();
      final comment = _commentController.text.trim();

      if (_isEditing) {
        await provider.updateReview(
          widget.existingReview!.id,
          StaffReviewUpdate(
            rating: _rating,
            comment: comment.isEmpty ? null : comment,
          ),
        );
      } else {
        await provider.addReview(
          StaffReviewInsert(
            appointmentId: widget.appointment.id,
            rating: _rating,
            comment: comment.isEmpty ? null : comment,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Uredi recenziju' : 'Ocijeni zaposlenika',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.appointment.employeeUsername ?? 'Zaposlenik',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;

                return IconButton(
                  tooltip: '$value/5',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _rating = value;
                            _errorMessage = null;
                          });
                        },
                  iconSize: 36,
                  color: Colors.amber.shade700,
                  icon: Icon(value <= _rating ? Icons.star : Icons.star_border),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Komentar (nije obavezan)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop(false);
                },
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isEditing ? Icons.save_outlined : Icons.send_outlined),
          label: Text(
            _isSubmitting
                ? 'Spremam...'
                : _isEditing
                ? 'Sačuvaj'
                : 'Pošalji',
          ),
        ),
      ],
    );
  }
}
