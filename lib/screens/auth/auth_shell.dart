import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/arco_components.dart';

/// Centered auth layout matching Design System v1 panel + brand.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s6,
              vertical: AppSpacing.s8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: AppSpacing.s8),
                  ArcoSectionHead(title: title, subtitle: subtitle),
                  const SizedBox(height: AppSpacing.s6),
                  ArcoPanel(child: child),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.s5),
                    Center(child: footer!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ArcoBrandMark(size: 48),
        const SizedBox(height: AppSpacing.s3),
        Text('iStatis', style: AppText.h3.copyWith(color: AppColors.accent)),
        const SizedBox(height: AppSpacing.s1),
        Text('v1.0 · dark', style: AppText.eyebrow),
      ],
    );
  }
}
