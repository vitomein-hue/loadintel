import 'package:loadintel/domain/models/range_result.dart';

abstract class RangeResultRepository {
  Future<void> addResult(RangeResult result);
  Future<void> updateResult(RangeResult result);
  Future<void> deleteResult(String id);
  Future<RangeResult?> getResult(String id);
  Future<List<RangeResult>> listResultsByLoad(String loadId);
  Future<RangeResult?> getBestResultForLoad(String loadId);
}

