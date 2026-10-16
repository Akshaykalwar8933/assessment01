import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/task_stats.dart';

class TaskStatusDonutChart extends StatelessWidget {
  const TaskStatusDonutChart({
    super.key,
    required this.stats,
    required this.size,
  });

  final TaskStats stats;
  final double size;

  List<PieChartSectionData> _buildChartSections(double thickness) {
    final segments = [
      (stats.overdue, AppColors.red),
      (stats.closed, AppColors.green),
      (stats.open, AppColors.yellow),
    ].where((s) => s.$1 > 0).toList();

    // No tasks: a single neutral ring instead of an empty chart.
    if (segments.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: AppColors.border,
          radius: thickness,
          showTitle: false,
        ),
      ];
    }
    return [
      for (final (value, color) in segments)
        PieChartSectionData(
          value: value.toDouble(),
          color: color,
          radius: thickness,
          showTitle: false,
          cornerRadius: segments.length > 1 ? thickness / 2 : 0,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final thickness = size * 0.05;
    final segmentCount = [
      stats.overdue,
      stats.closed,
      stats.open,
    ].where((v) => v > 0).length;
    return Semantics(
      label:
          '${stats.total} tasks: ${stats.open} open, ${stats.overdue} overdue, '
          '${stats.closed} closed',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: _buildChartSections(thickness),
                startDegreeOffset: 270,
                centerSpaceRadius: size / 2 - thickness,
                sectionsSpace: segmentCount > 1 ? thickness * 1.6 : 0,
                pieTouchData: PieTouchData(enabled: false),
              ),
              duration: const Duration(milliseconds: 300),
            ),
            ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${stats.total}',
                      style: AppTextStyles.chartTotal.copyWith(
                        fontSize: size * 0.24,
                      ),
                    ),
                  ),
                  Text(
                    'Tasks',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coloured dot + "Open 10" legend entry.
class ChartLegendItem extends StatelessWidget {
  const ChartLegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.r,
          height: 14.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: '$value',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: AppTextStyles.caption.copyWith(fontSize: 13.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
