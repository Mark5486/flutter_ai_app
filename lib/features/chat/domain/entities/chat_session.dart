import 'package:equatable/equatable.dart';

class ChatSession extends Equatable {
  const ChatSession({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt];
}
