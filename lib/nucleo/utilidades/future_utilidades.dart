/// Timeout independiente del Future de Firestore.
/// `.timeout()` en queries nativas a veces no dispara en Android.
Future<T> conTimeoutDuro<T>(
  Future<T> future,
  Duration duracion, {
  required Object error,
}) {
  return Future.any([
    future,
    Future<T>.delayed(duracion, () => throw error),
  ]);
}
