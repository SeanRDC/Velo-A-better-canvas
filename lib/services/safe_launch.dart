// Opens links found in Canvas content and AI replies, limited to safe schemes.
import 'package:url_launcher/url_launcher.dart';

const Set<String> _allowedSchemes = {'http', 'https', 'mailto'};
const String _canvasOrigin = 'https://hau.instructure.com';

// Returns the link to open, or null when it must not be launched. Canvas often
// writes site-relative links ("/courses/1/files/2"), which resolve to Canvas.
Uri? resolveSafeUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed.startsWith('/') && !trimmed.startsWith('//') ? '$_canvasOrigin$trimmed' : trimmed);
  if (uri == null || !_allowedSchemes.contains(uri.scheme.toLowerCase())) return null;
  return uri;
}

Future<bool> launchSafeUrl(String url) async {
  final uri = resolveSafeUrl(url);
  if (uri == null) return false;

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
