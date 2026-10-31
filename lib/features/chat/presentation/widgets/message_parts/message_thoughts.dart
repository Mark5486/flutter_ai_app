import 'package:flutter/material.dart';

class MessageThoughts extends StatefulWidget {
  const MessageThoughts({super.key, required this.thoughts});

  final String thoughts;

  @override
  State<MessageThoughts> createState() => _MessageThoughtsState();
}

class _MessageThoughtsState extends State<MessageThoughts> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.psychology : Icons.psychology_outlined,
                  size: 15,
                  color: const Color(0xFF9F7BFF),
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'إخفاء التفكير' : 'كيف فكرت؟',
                  style: const TextStyle(
                    color: Color(0xFF9F7BFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 15,
                  color: const Color(0xFF9F7BFF),
                ),
              ],
            ),
          ),
          if (_expanded)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF9F7BFF).withValues(alpha: 0.2),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.thoughts,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
