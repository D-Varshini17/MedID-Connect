import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/health_data_provider.dart';
import '../services/api_client.dart';
import '../services/appointment_service.dart';
import '../services/date_format_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key, this.showBackButton = false});

  static const route = '/appointments';

  final bool showBackButton;

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  late final AppointmentService _service = AppointmentService(ApiClient());
  List<Map<String, dynamic>> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _appointments = await _service.list();
    } catch (_) {
      _appointments = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final fallback = data.appointments
        .map(
          (item) => {
            'id': item.id,
            'appointment_type': 'Clinic visit',
            'scheduled_at': item.dateTime.toIso8601String(),
            'reason':
                '${item.title} with ${item.practitioner} at ${item.location}',
            'status': item.status,
            'meeting_url': null,
          },
        )
        .toList();
    final appointments = _appointments.isEmpty ? fallback : _appointments;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Appointments',
            subtitle:
                'Book doctor visits, track reminders, and keep consultation history ready.',
            icon: Icons.event_available_rounded,
            showBackButton: widget.showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_loading) const LinearProgressIndicator(),
                PremiumCard(
                  gradient: AppPalette.cyanGradient,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appointments.length} appointments',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Clinic and telemedicine readiness with local reminder support.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Add appointment',
                        onPressed: () => _showAddAppointment(context),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Upcoming'),
                if (appointments.isEmpty)
                  const PremiumCard(
                    child: Text('No appointments yet. Add your next visit.'),
                  )
                else
                  ...appointments.map(
                    (item) {
                      final when = DateTime.tryParse(
                            item['scheduled_at']?.toString() ?? '',
                          ) ??
                          DateTime.now();
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    AppPalette.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: AppPalette.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['reason']?.toString() ??
                                        'Doctor appointment',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${DateFormatService.shortDate(when)} • ${TimeOfDay.fromDateTime(when).format(context)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppPalette.muted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      StatusChip(
                                        label: item['status']?.toString() ??
                                            'scheduled',
                                        color: AppPalette.success,
                                        icon: Icons.check_circle_rounded,
                                      ),
                                      StatusChip(
                                        label: item['appointment_type']
                                                ?.toString() ??
                                            'visit',
                                        color: AppPalette.cyan,
                                        icon: Icons.video_call_rounded,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SectionHeader(title: 'History'),
                const PremiumCard(
                  child: Text(
                    'Consultation history is ready for doctor notes and video consultation logs.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAppointment(BuildContext context) async {
    final doctor = TextEditingController(text: 'Dr. Ananya Rao');
    final hospital = TextEditingController(text: 'MedID Virtual Care');
    final specialty = TextEditingController(text: 'Internal Medicine');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 30);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add appointment',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: doctor,
                    decoration: const InputDecoration(labelText: 'Doctor name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specialty,
                    decoration:
                        const InputDecoration(labelText: 'Specialization'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hospital,
                    decoration: const InputDecoration(labelText: 'Hospital'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded),
                          label:
                              Text(DateFormatService.shortDate(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setSheetState(() => selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final scheduled = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final item = {
                        'doctor_id': null,
                        'appointment_type': 'clinic_visit',
                        'scheduled_at': scheduled.toUtc().toIso8601String(),
                        'reason':
                            '${specialty.text.trim()} with ${doctor.text.trim()} at ${hospital.text.trim()}',
                      };
                      try {
                        await _service.create(item);
                        await _load();
                      } catch (_) {
                        setState(() => _appointments.insert(0, {
                              ...item,
                              'status': 'scheduled',
                              'meeting_url': null,
                            }));
                      }
                      await NotificationService.showDemoReminder();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save appointment'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
