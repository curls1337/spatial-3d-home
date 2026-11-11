import 'dart:math' as math;
import '../models/app_models.dart';

class SpatialMath {
  SpatialMath._();

  /// BRD 4.1 Straight-line Depreciation Formula:
  /// Estimated = max(PurchasePrice * (1 - r * (ageMonths / 12)), PurchasePrice * salvageFloor)
  static double calculateStraightLineValuation({
    required double purchasePrice,
    required AssetCategory category,
    required DateTime purchaseDate,
    DateTime? referenceDate,
  }) {
    if (purchasePrice <= 0) return 0;
    final ref = referenceDate ?? DateTime.now();
    final months = math.max(
      0,
      (ref.year - purchaseDate.year) * 12 + (ref.month - purchaseDate.month),
    );
    final years = months / 12.0;

    final double rate;
    final double floorRatio;
    switch (category) {
      case AssetCategory.electronics:
        rate = 0.20;
        floorRatio = 0.10;
        break;
      case AssetCategory.furniture:
      case AssetCategory.appliances:
        rate = 0.10;
        floorRatio = 0.20;
        break;
      case AssetCategory.collectibles:
        rate = 0.00;
        floorRatio = 1.00;
        break;
    }

    final floor = purchasePrice * floorRatio;
    final raw = purchasePrice * (1.0 - (rate * years));
    return math.max(raw, floor).roundToDouble();
  }
}
