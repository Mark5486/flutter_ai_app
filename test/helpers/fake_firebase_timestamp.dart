

class FakeFirestoreTimestamp {
  const FakeFirestoreTimestamp(this.value);

  final DateTime value;

  DateTime toDate() => value;
}
