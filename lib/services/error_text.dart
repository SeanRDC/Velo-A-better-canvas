// Turns a caught error into text that is safe to show the user.

// The app's own exceptions carry a readable message ("Cannot delete messages
// while offline."). Anything else, such as a socket or parsing error, could
// expose internals, so it is replaced with [fallback].
String friendlyError(Object error, String fallback) {
  const prefix = 'Exception: ';
  final text = error.toString();
  if (error is Exception && text.startsWith(prefix)) {
    return text.substring(prefix.length);
  }
  return fallback;
}
