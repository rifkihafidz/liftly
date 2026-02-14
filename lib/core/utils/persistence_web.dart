import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('navigator.storage.persist')
external JSPromise<JSBoolean> _persist();

@JS('navigator.storage.persisted')
external JSPromise<JSBoolean> _persisted();

Future<void> requestPersistence() async {
  try {
    final isPersisted = await _persisted().toDart;
    if (isPersisted.toDart) {
      debugPrint('Persistence: Storage is already persisted');
      return;
    }

    final result = await _persist().toDart;
    if (result.toDart) {
      debugPrint('Persistence: Storage successfully persisted');
    } else {
      debugPrint('Persistence: Storage persistence denied by browser');
    }
  } catch (e) {
    debugPrint('Persistence: Error requesting storage persistence: $e');
  }
}
