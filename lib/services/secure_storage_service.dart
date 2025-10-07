import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageService {
  Future<bool> cacheKeyWithValue({
    required String key,
    required String value,
  });

  Future<String?> getKey({required String key});

  Future<bool> removeKey({
    required String key,
  });
}

class SecureStorageServiceImpl implements SecureStorageService {
  final FlutterSecureStorage flutterSecureStorage;

  const SecureStorageServiceImpl({
    required this.flutterSecureStorage,
  });

  @override
  Future<bool> cacheKeyWithValue({
    required String key,
    required String value,
  }) async {
    try {
      return await flutterSecureStorage
          .write(
            key: key,
            value: value,
          )
          .then(
            (value) => true,
          );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> getKey({
    required String key,
  }) async {
    try {
      return await flutterSecureStorage.read(
        key: key,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> removeKey({
    required String key,
  }) async {
    try {
      return await flutterSecureStorage
          .delete(
            key: key,
          )
          .then(
            (value) => true,
          );
    } catch (e) {
      rethrow;
    }
  }
}
