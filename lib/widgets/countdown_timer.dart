import 'dart:async';

import 'package:flutter/material.dart';

import '../models/reminder_item.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.targetDate,
    this.recurrenceAnchor,
    this.recurrence = ReminderRecurrence.none,
    this.title = 'Sanitasi kandang',
    this.canEditTime = false,
    this.isSavingTime = false,
    this.onEditTime,
  });

  final DateTime targetDate;
  final DateTime? recurrenceAnchor;
  final ReminderRecurrence recurrence;
  final String title;
  final bool canEditTime;
  final bool isSavingTime;
  final VoidCallback? onEditTime;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDate != widget.targetDate ||
        oldWidget.recurrenceAnchor != widget.recurrenceAnchor ||
        oldWidget.recurrence != widget.recurrence ||
        oldWidget.title != widget.title) {
      _now = DateTime.now();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool recurring = widget.recurrence != ReminderRecurrence.none &&
        widget.recurrenceAnchor != null;
    final DateTime target = _targetForNow();
    final bool overdue = !recurring && _now.isAfter(target);
    final Duration difference =
        overdue ? _now.difference(target) : target.difference(_now);

    final int days = difference.inDays;
    final int hours = difference.inHours.remainder(24);
    final int minutes = difference.inMinutes.remainder(60);
    final int seconds = difference.inSeconds.remainder(60);

    final Color foreground =
        overdue ? Theme.of(context).colorScheme.error : AppTheme.primary;
    final Color background = overdue
        ? Theme.of(context).colorScheme.errorContainer
        : AppTheme.primarySoft;

    return Semantics(
      liveRegion: true,
      label: overdue
          ? '${widget.title} terlambat $days hari $hours jam $minutes menit $seconds detik'
          : '${widget.title} jatuh tempo dalam $days hari $hours jam $minutes menit $seconds detik',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    overdue
                        ? Icons.warning_amber_rounded
                        : Icons.timer_outlined,
                    size: 20,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        overdue
                            ? '${widget.title} terlambat'
                            : '${widget.title} berikutnya',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _scheduleLabel(target),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (recurring && widget.canEditTime) ...<Widget>[
                            const SizedBox(width: 6),
                            if (widget.isSavingTime)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Tooltip(
                                message: 'Edit jam pelaksanaan',
                                child: InkWell(
                                  onTap: widget.onEditTime,
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TimeBox(
                    value: days,
                    label: 'Hari',
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _TimeBox(
                    value: hours,
                    label: 'Jam',
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _TimeBox(
                    value: minutes,
                    label: 'Menit',
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _TimeBox(
                    value: seconds,
                    label: 'Detik',
                    color: foreground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _targetForNow() {
    final DateTime? anchor = widget.recurrenceAnchor;
    if (anchor == null) return widget.targetDate;

    switch (widget.recurrence) {
      case ReminderRecurrence.daily:
        return AppDateUtils.nextDailyOccurrence(anchor, _now);
      case ReminderRecurrence.monthly:
        return AppDateUtils.nextMonthlyOccurrence(anchor, _now);
      case ReminderRecurrence.none:
        return widget.targetDate;
    }
  }

  String _scheduleLabel(DateTime target) {
    switch (widget.recurrence) {
      case ReminderRecurrence.daily:
        return '${AppDateUtils.formatDateTime(target)} • berulang setiap hari';
      case ReminderRecurrence.monthly:
        return '${AppDateUtils.formatDateTime(target)} • berulang setiap bulan';
      case ReminderRecurrence.none:
        return AppDateUtils.formatDateTime(target);
    }
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
