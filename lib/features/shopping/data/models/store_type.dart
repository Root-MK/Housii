/// Store types for shopping items
enum StoreType {
  bilka('bilka', 'Bilka', '🟡'),
  rema1000('rema1000', 'Rema 1000', '🔵'),
  abcLavpris('abcLavpris', 'ABC Lavpris', '🟢'),
  other('other', 'Anden butik', '🏪');

  final String value;
  final String displayName;
  final String emoji;

  const StoreType(this.value, this.displayName, this.emoji);

  /// Convert from Firestore string value
  static StoreType? fromValue(String? value) {
    if (value == null) return null;
    return StoreType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StoreType.other,
    );
  }
}
