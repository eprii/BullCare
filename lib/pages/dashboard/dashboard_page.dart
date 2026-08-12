import 'package:flutter/material.dart';

import '../../models/activity_record.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/bull_status.dart';
import '../../utils/app_feedback.dart';
import '../../utils/confirmation_dialog.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/bull_visual.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_header.dart';
import '../activities/activity_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.user,
    required this.onOpenBulls,
    required this.onOpenActivities,
    required this.onOpenReminders,
    this.revision = 0,
  });

  final UserModel user;
  final VoidCallback onOpenBulls;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenReminders;
  final int revision;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _service = DashboardService();
  late Future<DashboardData> _future;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _future = _service.load();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _future = _service.load();
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.load());
    await _future;
  }

  Future<void> _logout() async {
    if (_signingOut) return;

    final bool confirmed = await showConfirmationDialog(
      context,
      title: 'Keluar dari aplikasi?',
      message:
          'Sesi ${widget.user.nama} akan diakhiri. Pastikan seluruh data sudah tersimpan.',
      confirmLabel: 'Ya, keluar',
      cancelLabel: 'Batal',
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await AuthService().signOut();
      AppFeedback.showGlobalSuccess('Berhasil keluar dari aplikasi.');
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(context, 'Gagal keluar dari aplikasi: $error');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }

            final DashboardData data = snapshot.data!;
            final int healthyBulls = data.bulls
                .where((bull) => BullStatus.isSehat(bull.status))
                .length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: AppPageContainer(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                  children: <Widget>[
                    _TopBar(
                      user: widget.user,
                      signingOut: _signingOut,
                      onLogout: _logout,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Halo, ${_firstName(widget.user.nama)} 👋',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLabel(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const BullVisual(height: 168, showLabel: true),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.52,
                      children: <Widget>[
                        _SummaryCard(
                          icon: Icons.pets,
                          value: '${data.bulls.length}',
                          label: 'Total Bull',
                          accent: AppTheme.primary,
                          onTap: widget.onOpenBulls,
                        ),
                        _SummaryCard(
                          icon: Icons.health_and_safety_rounded,
                          value: '$healthyBulls',
                          label: 'Bull Sehat',
                          accent: const Color(0xFF4AAE59),
                          onTap: widget.onOpenBulls,
                        ),
                        _SummaryCard(
                          icon: Icons.notifications_active_outlined,
                          value: '${data.reminders.length}',
                          label: 'Reminder Aktif',
                          accent: const Color(0xFFFFA726),
                          onTap: widget.onOpenReminders,
                        ),
                        _SummaryCard(
                          icon: Icons.event_note_rounded,
                          value: '${data.recentActivities.length}',
                          label: 'Aktivitas Terbaru',
                          accent: const Color(0xFF2288C7),
                          onTap: widget.onOpenActivities,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Aktivitas Terbaru',
                      subtitle: 'Pencatatan pemeliharaan paling baru',
                      actionLabel: 'Lihat semua',
                      onAction: widget.onOpenActivities,
                    ),
                    const SizedBox(height: 10),
                    if (data.recentActivities.isEmpty)
                      const Card(
                        child: EmptyState(
                          icon: Icons.history_toggle_off,
                          title: 'Belum ada aktivitas',
                          message:
                              'Aktivitas pemeliharaan yang disimpan akan tampil di sini.',
                        ),
                      )
                    else
                      ...data.recentActivities.take(5).map((ActivityRecord record) {
                        return ActivityTile(
                          record: record,
                          bullName: data.bullNames[record.bull_id] ??
                              'Bull tidak ditemukan',
                          compact: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ActivityDetailPage(
                                  record: record,
                                  bull: data.bullById[record.bull_id],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _firstName(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return 'Pengguna';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String _dateLabel(DateTime date) {
    const List<String> days = <String>[
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const List<String> months = <String>[
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.user,
    required this.signingOut,
    required this.onLogout,
  });

  final UserModel user;
  final bool signingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.pets, color: AppTheme.primary, size: 28),
        const SizedBox(width: 8),
        const Text(
          'BullCare',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppTheme.divider),
          ),
          child: IconButton(
            tooltip: 'Keluar',
            onPressed: signingOut ? null : onLogout,
            icon: signingOut
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, size: 21),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.divider),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0B000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
