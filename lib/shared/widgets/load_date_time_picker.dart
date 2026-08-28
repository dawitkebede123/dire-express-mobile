import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../ethiopian_date.dart';

Future<DateTime?> pickLoadDateTime(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final now = DateTime.now();
  final first = firstDate ?? now.subtract(const Duration(days: 1));
  final last = lastDate ?? now.add(const Duration(days: 365));
  final locale = Localizations.localeOf(context);
  var safeInitial = initial ?? now;
  if (safeInitial.isBefore(first)) safeInitial = first;
  if (safeInitial.isAfter(last)) safeInitial = last;
  DateTime? date;
  if (locale.languageCode == 'am') {
    date = await showDialog<DateTime>(
      context: context,
      builder: (context) => EthiopianDatePickerDialog(
        initialDate: safeInitial,
        firstDate: first,
        lastDate: last,
      ),
    );
  } else {
    date = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: first,
      lastDate: last,
    );
  }
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial ?? now),
    builder: (context, child) {
      return Localizations.override(
        context: context,
        locale: const Locale('en', 'US'),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      );
    },
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

class EthiopianDatePickerDialog extends StatefulWidget {
  const EthiopianDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<EthiopianDatePickerDialog> createState() => _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState extends State<EthiopianDatePickerDialog> {
  late EthiopianDate _visible;
  late EthiopianDate _selected;

  @override
  void initState() {
    super.initState();
    _selected = EthiopianDate.fromGregorian(widget.initialDate);
    _visible = _selected.startOfMonth;
  }

  bool _isSelectable(EthiopianDate date) {
    final g = date.toGregorian();
    final day = DateTime(g.year, g.month, g.day);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !day.isBefore(first) && !day.isAfter(last);
  }

  @override
  Widget build(BuildContext context) {
    final days = _visible.daysInMonth;
    final firstWeekday = _visible.startOfMonth.toGregorian().weekday % 7;
    final today = EthiopianDate.fromGregorian(DateTime.now());

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      title: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _visible = _visible.addMonths(-1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${_visible.monthName} ${_visible.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _visible = _visible.addMonths(1)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (final name in ethiopianWeekdaysAm)
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: firstWeekday + days,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox.shrink();
                final day = index - firstWeekday + 1;
                final date = EthiopianDate(year: _visible.year, month: _visible.month, day: day);
                final selected = date.year == _selected.year && date.month == _selected.month && date.day == _selected.day;
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                final enabled = _isSelectable(date);
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: Material(
                    color: selected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: enabled ? () => setState(() => _selected = date) : null,
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !enabled
                                ? AppColors.outlineVariant
                                : selected
                                    ? Colors.white
                                    : AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ይቅር')),
        FilledButton(
          onPressed: _isSelectable(_selected) ? () => Navigator.pop(context, _selected.toGregorian()) : null,
          child: const Text('እሺ'),
        ),
      ],
    );
  }
}
