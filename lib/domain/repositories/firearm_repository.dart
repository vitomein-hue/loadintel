import 'package:loadintel/domain/models/firearm.dart';

abstract class FirearmRepository {
  Future<void> upsertFirearm(Firearm firearm);
  Future<void> deleteFirearm(String id);
  Future<Firearm?> getFirearm(String id);
  Future<List<Firearm>> listFirearms();
}
