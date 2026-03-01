import 'dart:js_interop';
import 'package:liftly/core/utils/app_logger.dart';

@JS('navigator.storage.persist')
external JSPromise<JSBoolean> _persist();

@JS('navigator.storage.persisted')
external JSPromise<JSBoolean> _persisted();

Future<void> requestPersistence() async {
  try {
    final isPersisted = await _persisted().toDart;
    if (isPersisted.toDart) {
      AppLogger.debug('Persistence', 'Storage is already persisted');
      return;
    }

    final result = await _persist().toDart;
    if (result.toDart) {
      AppLogger.debug('Persistence', 'Storage successfully persisted');
    } else {
      AppLogger.warning('Persistence', 'Storage persistence denied by browser');
    }
  } catch (e) {
    AppLogger.error('Persistence', 'Error requesting storage persistence', e);
  }
}
