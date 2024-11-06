Map<String, List<Map<String, dynamic>>> mergeObjects(
    Map<String, dynamic>? obj1, Map<String, dynamic>? obj2) {
  // Menggunakan map baru untuk hasil penggabungan
  Map<String, List<Map<String, dynamic>>> merged = {};

  // Menambahkan semua entry dari obj1 jika tidak null
  obj1?.forEach((key, value) {
    merged[key] = List.from(
        value); // Salin list untuk menghindari perubahan langsung pada obj1
  });

  // Menggabungkan entry dari obj2
  obj2?.forEach((key, value) {
    if (merged.containsKey(key)) {
      // Jika key sudah ada, tambahkan semua item dari list obj2 ke list di merged
      merged[key]!.addAll(value);
    } else {
      // Jika key belum ada, tambahkan key-value dari obj2 langsung ke merged
      merged[key] = List.from(value);
    }
  });

  return merged;
}
