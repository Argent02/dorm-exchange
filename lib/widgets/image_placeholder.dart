import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder for missing or failed listing images.
class ImagePlaceholder extends StatelessWidget {
  final double? size;

  const ImagePlaceholder({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: size,
          color: theme.colorScheme.placeholderIcon,
        ),
      ),
    );
  }
}
