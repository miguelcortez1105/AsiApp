enum PortalIndicatorType {
  essencial,
  complementar,
}

enum PortalIndicatorUnit {
  moeda,
  percentual,
  numero,
}

class PortalBjIndicator {
  const PortalBjIndicator({
    required this.name,
    required this.type,
    required this.achieved,
    required this.goal,
    required this.unit,
  });

  final String name;
  final PortalIndicatorType type;
  final double achieved;
  final double goal;
  final PortalIndicatorUnit unit;

  double get progress {
    if (goal <= 0) return 0;

    return (((achieved / goal) * 100)
        .clamp(0.0, 100.0))
        .toDouble();
  }

  double get gap {
    return ((goal - achieved)
        .clamp(0.0, double.infinity))
        .toDouble();
  }
}