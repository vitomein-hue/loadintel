import 'dart:convert';

String? encodeDoubleList(List<double>? values) {
  if (values == null) {
    return null;
  }
  return jsonEncode(values);
}

List<double>? decodeDoubleList(Object? value) {
  if (value == null) {
    return null;
  }
  final decoded = jsonDecode(value as String) as List<dynamic>;
  return decoded.map((item) => (item as num).toDouble()).toList();
}
