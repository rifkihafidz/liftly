import 'package:web/web.dart' as web;

void reloadPage() {
  try {
    // Call the global helper defined in index.html
    (web.window as dynamic).triggerAppUpdate();
  } catch (e) {
    // Fallback to hard reload if helper is missing
    web.window.location.reload();
  }
}
