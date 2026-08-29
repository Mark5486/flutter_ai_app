import 'package:flutter/material.dart';
import 'package:flutter_ai_app/features/attachment/domain/entity/attachment_entity.dart';

class PickFileButtonWidget extends StatelessWidget {
  final AttachmentType type;
  final VoidCallback onPressed;

  const PickFileButtonWidget({
    super.key,
    required this.type,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = type == AttachmentType.image;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(isImage ? Icons.image : Icons.insert_drive_file),
      label: Text(isImage ? 'اختيار صورة' : 'اختيار مستند'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
