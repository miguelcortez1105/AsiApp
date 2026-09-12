class DashboardMetrics {
  const DashboardMetrics({
    this.currentRevenue = 0,
    this.previousYearRevenue = 0,
    this.annualGoal = 0,
  });

  final double currentRevenue;
  final double previousYearRevenue;
  final double annualGoal;

  double get goalGap {
    return (annualGoal - currentRevenue).clamp(0, double.infinity);
  }

  double get goalPercentage {
    if (annualGoal <= 0) {
      return 0;
    }

    return ((currentRevenue / annualGoal) * 100).clamp(0, 100);
  }

  double get annualVariation {
    if (previousYearRevenue <= 0) {
      return 0;
    }

    return ((currentRevenue - previousYearRevenue) /
            previousYearRevenue) *
        100;
  }
}