// Turns a caught error into text that is safe to show the user.
String friendlyError(Object error, String fallback) {
  const prefix = 'Exception: ';
  final text = error.toString();
  if (error is Exception && text.startsWith(prefix)) {
    return text.substring(prefix.length);
  }
  return fallback;
}
