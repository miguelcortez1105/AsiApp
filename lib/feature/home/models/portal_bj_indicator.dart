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
    if (goal <= 0) {
      return 0;
    }

    return (achieved / goal).clamp(0, 1);
  }

  double get gap {
    return (goal - achieved).clamp(0, double.infinity);
  }
}