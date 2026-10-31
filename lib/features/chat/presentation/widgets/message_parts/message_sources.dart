import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/message_source.dart';

class MessageSources extends StatelessWidget {
  const MessageSources({super.key, required this.sources});

  final List<MessageSource> sources;

  Future<void> _openSource(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showOpenError(ScaffoldMessenger.of(context));
      return;
    }

    
    final messenger = ScaffoldMessenger.of(context);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) _showOpenError(messenger);
    } catch (_) {
      _showOpenError(messenger);
    }
  }

  void _showOpenError(ScaffoldMessengerState messenger) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح المصدر.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore,
                size: 14,
                color: Color(0xFF00D4A0),
              ),
              SizedBox(width: 4),
              Text(
                'المصادر:',
                style: TextStyle(
                  color: Color(0xFF00D4A0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sources
                .map((source) => _buildSourceChip(context, source))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(BuildContext context, MessageSource source) {
    final host = _hostOf(source.url);

    return InkWell(
      onTap: () => _openSource(context, source.url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF00D4A0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00D4A0).withValues(alpha: 0.35),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.link,
              size: 12,
              color: Color(0xFF00D4A0),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                host.isNotEmpty ? host : source.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7EE7CD),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hostOf(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    return host.replaceFirst('www.', '');
  }
}
