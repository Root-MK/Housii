import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shows a date range picker that auto-closes when end date is selected
Future<DateTimeRange?> showAutoCloseDateRangePicker({
  required BuildContext context,
  DateTime? initialStart,
  DateTime? initialEnd,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) => _AutoCloseDateRangePickerDialog(
      initialStart: initialStart,
      initialEnd: initialEnd,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _AutoCloseDateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;

  const _AutoCloseDateRangePickerDialog({
    this.initialStart,
    this.initialEnd,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_AutoCloseDateRangePickerDialog> createState() => _AutoCloseDateRangePickerDialogState();
}

class _AutoCloseDateRangePickerDialogState extends State<_AutoCloseDateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _focusedMonth;
  bool _selectingEndDate = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
    _focusedMonth = widget.initialStart ?? DateTime.now();
    _selectingEndDate = widget.initialStart != null && widget.initialEnd == null;
  }

  void _onDaySelected(DateTime day) {
    if (!_selectingEndDate) {
      // Selecting start date
      setState(() {
        _startDate = day;
        _endDate = null;
        _selectingEndDate = true;
      });
    } else {
      // Selecting end date
      if (day.isBefore(_startDate!)) {
        // If selected day is before start, swap them
        setState(() {
          _endDate = _startDate;
          _startDate = day;
        });
      } else {
        setState(() {
          _endDate = day;
        });
      }
      // Auto close and return result
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          Navigator.of(context).pop(DateTimeRange(start: _startDate!, end: _endDate!));
        }
      });
    }
  }

  bool _isInRange(DateTime day) {
    if (_startDate == null) return false;
    if (_endDate == null) return day == _startDate;
    return !day.isBefore(_startDate!) && !day.isAfter(_endDate!);
  }

  bool _isStart(DateTime day) {
    return _startDate != null && 
           day.year == _startDate!.year && 
           day.month == _startDate!.month && 
           day.day == _startDate!.day;
  }

  bool _isEnd(DateTime day) {
    return _endDate != null && 
           day.year == _endDate!.year && 
           day.month == _endDate!.month && 
           day.day == _endDate!.day;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectingEndDate ? 'Vælg slutdato' : 'Vælg startdato',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Selected range display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fra',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                        Text(
                          _startDate != null 
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : '—',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _startDate != null ? AppColors.primaryPurple : AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: AppColors.primaryPurple),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Til',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                        Text(
                          _endDate != null 
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : '—',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _endDate != null ? AppColors.primaryPurple : AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  _getMonthName(_focusedMonth.month) + ' ${_focusedMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Weekday headers
            Row(
              children: ['Ma', 'Ti', 'On', 'To', 'Fr', 'Lø', 'Sø']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            
            // Calendar grid
            _buildCalendarGrid(),
            
            const SizedBox(height: 16),
            
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuller',
                style: TextStyle(color: AppColors.gray),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    
    // Monday = 1, Sunday = 7
    int startWeekday = firstDayOfMonth.weekday;
    
    final days = <Widget>[];
    
    // Empty cells before first day
    for (int i = 1; i < startWeekday; i++) {
      days.add(const SizedBox());
    }
    
    // Days of month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isDisabled = date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);
      final inRange = _isInRange(date);
      final isStartDay = _isStart(date);
      final isEndDay = _isEnd(date);
      
      days.add(
        GestureDetector(
          onTap: isDisabled ? null : () => _onDaySelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isStartDay || isEndDay 
                  ? AppColors.primaryPurple 
                  : inRange 
                      ? AppColors.primaryPurple.withOpacity(0.2) 
                      : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isStartDay || isEndDay ? FontWeight.w600 : FontWeight.w400,
                  color: isDisabled 
                      ? AppColors.lightGray 
                      : isStartDay || isEndDay 
                          ? Colors.white 
                          : AppColors.darkGray,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: days,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januar', 'Februar', 'Marts', 'April', 'Maj', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'December'
    ];
    return months[month - 1];
  }
}
