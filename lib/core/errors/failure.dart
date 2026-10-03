/// Thrown by repositories. Cubits catch it and expose [message] to the UI.
class Failure implements Exception {
  const Failure(this.message);

  final String message;

  static const Failure unknown =
      Failure('Something went wrong. Please try again.');

  @override
  String toString() => message;
}
