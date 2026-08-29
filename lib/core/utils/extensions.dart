import 'package:cloud_firestore/cloud_firestore.dart';

extension DocumentSnapshotExtensions on DocumentSnapshot {
  Map<String, dynamic> get dataMap {
    final data = this.data();

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  String get documentId => id;
}

extension QueryDocumentSnapshotExtensions
    on QueryDocumentSnapshot<Map<String, dynamic>> {
  Map<String, dynamic> get dataMap => data();

  String get documentId => id;
}

extension TimestampExtensions on Timestamp? {
  DateTime? get dateTime => this?.toDate();
}
