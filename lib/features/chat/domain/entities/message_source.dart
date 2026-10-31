import 'package:equatable/equatable.dart';

class MessageSource extends Equatable {
  const MessageSource({required this.title, required this.url});

  final String title;
  final String url;

  Map<String, dynamic> toMap() {
    return {'title': title, 'url': url};
  }

  @override
  List<Object?> get props => [title, url];
}
