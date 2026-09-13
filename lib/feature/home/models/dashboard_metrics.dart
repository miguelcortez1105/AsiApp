class DashboardMetrics {
  const DashboardMetrics({
    required this.currentRevenue,
    required this.previousYearRevenue,
    required this.annualGoal,
  });

  final double currentRevenue;
  final double previousYearRevenue;
  final double annualGoal;

  factory DashboardMetrics.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return DashboardMetrics(
      currentRevenue:
          (data['currentRevenue'] as num?)?.toDouble() ?? 0,
      previousYearRevenue:
          (data['previousYearRevenue'] as num?)?.toDouble() ?? 0,
      annualGoal:
          (data['annualGoal'] as num?)?.toDouble() ?? 0,
    );
  }
}


class PortalBjIndicator {
  const PortalBjIndicator({
    required this.id,
    required this.name,
    required this.type,
    required this.goal,
    required this.achieved,
    required this.unit,
    required this.order,
    required this.year,
  });

  final String id;
  final String name;
  final String type;
  final double goal;
  final double achieved;
  final String unit;
  final int order;
  final int year;

  factory PortalBjIndicator.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return PortalBjIndicator(
      id: id,
      name: data['name']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      goal: (data['goal'] as num?)?.toDouble() ?? 0,
      achieved: (data['achieved'] as num?)?.toDouble() ?? 0,
      unit: data['unit']?.toString() ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      year: (data['year'] as num?)?.toInt() ?? 0,
    );
  }

  double get progress {
    if (goal <= 0) return 0;

    return ((achieved / goal) * 100).clamp(0, 100);
  }

  double get gap {
    return (goal - achieved).clamp(0, double.infinity);
  }
}