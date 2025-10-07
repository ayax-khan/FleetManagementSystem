// lib/models/pol_price.dart
import 'package:hive/hive.dart';

part 'pol_price.g.dart';

@HiveType(typeId: 8) // Additional as mentioned
class PolPrice extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double petrolPrice;

  @HiveField(3)
  double dieselPrice;

  @HiveField(4)
  double? pvtUseRatePetrol; // 50% or calculated

  @HiveField(5)
  double? pvtUseRateDiesel;

  PolPrice({
    this.id,
    required this.date,
    required this.petrolPrice,
    required this.dieselPrice,
    this.pvtUseRatePetrol,
    this.pvtUseRateDiesel,
  });
}
