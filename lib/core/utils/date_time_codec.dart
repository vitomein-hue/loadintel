int encodeDateTime(DateTime value) {
  return value.toUtc().millisecondsSinceEpoch;
}

DateTime decodeDateTime(Object value) {
  return DateTime.fromMillisecondsSinceEpoch(
    value as int,
    isUtc: true,
  ).toLocal();
}

DateTime? decodeNullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return decodeDateTime(value);
}
