import 'package:flutter/material.dart';

import 'app_theme.dart';

// ---------------------------------------------------------------------------
// Buttons — matches Design System v1: primary / secondary / ghost / danger
// ---------------------------------------------------------------------------

enum ArcoButtonVariant { primary, secondary, ghost, danger }

enum ArcoButtonSize { sm, md, lg }

class ArcoButton extends StatelessWidget {
  const ArcoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ArcoButtonVariant.primary,
    this.size = ArcoButtonSize.md,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ArcoButtonVariant variant;
  final ArcoButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      ArcoButtonSize.sm => 36.0,
      ArcoButtonSize.md => 44.0,
      ArcoButtonSize.lg => 48.0,
    };
    final textStyle = switch (size) {
      ArcoButtonSize.sm => AppText.small.copyWith(fontWeight: FontWeight.w600),
      ArcoButtonSize.md => AppText.button,
      ArcoButtonSize.lg => AppText.body.copyWith(fontWeight: FontWeight.w600),
    };
    final hPad = switch (size) {
      ArcoButtonSize.sm => AppSpacing.s3,
      ArcoButtonSize.md => AppSpacing.s5,
      ArcoButtonSize.lg => AppSpacing.s6,
    };

    // AppText.button defaults to text1; set foreground explicitly per variant.
    final fg = _foregroundColor(variant);
    final labelStyle = textStyle.copyWith(color: fg);

    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _spinnerColor(variant),
            ),
          )
        : (icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: AppSpacing.s2),
                    Text(label, style: labelStyle),
                  ],
                )
              : Text(label, style: labelStyle));

    final Widget button;
    switch (variant) {
      case ArcoButtonVariant.primary:
        button = ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.accentContrast,
            minimumSize: Size(expand ? double.infinity : 0, height),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            textStyle: textStyle,
          ),
          child: content,
        );
      case ArcoButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface2,
            foregroundColor: AppColors.text1,
            minimumSize: Size(expand ? double.infinity : 0, height),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            side: const BorderSide(color: AppColors.borderStrong),
            textStyle: textStyle,
          ),
          child: content,
        );
      case ArcoButtonVariant.ghost:
        button = TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.text2,
            minimumSize: Size(expand ? double.infinity : 0, height),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            textStyle: textStyle,
          ),
          child: content,
        );
      case ArcoButtonVariant.danger:
        button = OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.dangerSoft,
            foregroundColor: AppColors.danger,
            minimumSize: Size(expand ? double.infinity : 0, height),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            side: BorderSide(color: AppColors.danger.withOpacity(0.35)),
            textStyle: textStyle,
          ),
          child: content,
        );
    }

    return button;
  }

  Color _foregroundColor(ArcoButtonVariant v) => switch (v) {
    ArcoButtonVariant.primary => AppColors.accentContrast,
    ArcoButtonVariant.secondary => AppColors.text1,
    ArcoButtonVariant.ghost => AppColors.text2,
    ArcoButtonVariant.danger => AppColors.danger,
  };

  Color _spinnerColor(ArcoButtonVariant v) => switch (v) {
    ArcoButtonVariant.primary => AppColors.accentContrast,
    _ => AppColors.accent,
  };
}

class ArcoIconButton extends StatelessWidget {
  const ArcoIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.rMd,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: AppColors.accentContrast),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chips & badges
// ---------------------------------------------------------------------------

class ArcoChip extends StatelessWidget {
  const ArcoChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accentSoft2 : AppColors.surface2;
    final border = selected ? AppColors.accentBorder : AppColors.border;
    final color = selected ? AppColors.accent : AppColors.text1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: AppSpacing.s2,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.rPill,
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: AppText.small.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

enum ArcoBadgeVariant { neutral, accent, success, warning, danger }

class ArcoBadge extends StatelessWidget {
  const ArcoBadge({
    super.key,
    required this.label,
    this.variant = ArcoBadgeVariant.neutral,
    this.showDot = false,
  });

  final String label;
  final ArcoBadgeVariant variant;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = switch (variant) {
      ArcoBadgeVariant.neutral => (
        AppColors.surface2,
        AppColors.text2,
        AppColors.text3,
      ),
      ArcoBadgeVariant.accent => (
        AppColors.accentSoft,
        AppColors.accent,
        AppColors.accent,
      ),
      ArcoBadgeVariant.success => (
        AppColors.successSoft,
        AppColors.success,
        AppColors.success,
      ),
      ArcoBadgeVariant.warning => (
        AppColors.warningSoft,
        AppColors.warning,
        AppColors.warning,
      ),
      ArcoBadgeVariant.danger => (
        AppColors.dangerSoft,
        AppColors.danger,
        AppColors.danger,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rPill,
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppText.chip.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alerts
// ---------------------------------------------------------------------------

enum ArcoAlertVariant { info, success, warning, danger }

class ArcoAlert extends StatelessWidget {
  const ArcoAlert({
    super.key,
    required this.message,
    this.variant = ArcoAlertVariant.info,
    this.icon,
  });

  final String message;
  final ArcoAlertVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, defaultIcon) = switch (variant) {
      ArcoAlertVariant.info => (
        AppColors.accentSoft,
        AppColors.text1,
        AppColors.accentBorder,
        Icons.info_outline,
      ),
      ArcoAlertVariant.success => (
        AppColors.successSoft,
        AppColors.text1,
        AppColors.success.withOpacity(0.3),
        Icons.check_circle_outline,
      ),
      ArcoAlertVariant.warning => (
        AppColors.warningSoft,
        AppColors.text1,
        AppColors.warning.withOpacity(0.3),
        Icons.warning_amber_rounded,
      ),
      ArcoAlertVariant.danger => (
        AppColors.dangerSoft,
        AppColors.text1,
        AppColors.danger.withOpacity(0.3),
        Icons.error_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: fg),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(message, style: AppText.small.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards & layout chrome
// ---------------------------------------------------------------------------

class ArcoCard extends StatelessWidget {
  const ArcoCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: AppDecorations.card(),
      padding: padding ?? const EdgeInsets.all(AppSpacing.s4),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: AppRadius.rLg, child: card),
    );
  }
}

class ArcoPanel extends StatelessWidget {
  const ArcoPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.s6),
      child: child,
    );
  }
}

class ArcoDivider extends StatelessWidget {
  const ArcoDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderSubtle,
    );
  }
}

class ArcoSectionHead extends StatelessWidget {
  const ArcoSectionHead({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, style: AppText.eyebrow),
          const SizedBox(height: AppSpacing.s2),
        ],
        Text(title, style: AppText.h1),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(subtitle!, style: AppText.body.copyWith(color: AppColors.text2)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar & segmented navigation (Design System v1)
// ---------------------------------------------------------------------------

class ArcoBrandMark extends StatelessWidget {
  const ArcoBrandMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: AppRadius.rMd,
      ),
      alignment: Alignment.center,
      child: Text(
        'i',
        style: AppText.body.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.accentContrast,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}

class ArcoTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ArcoTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBrand = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBrand;

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 60);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface1.withOpacity(0.92),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: Row(
              children: [
                if (showBrand) ...[
                  const ArcoBrandMark(),
                  const SizedBox(width: AppSpacing.s3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: AppText.navTitle),
                      if (subtitle != null)
                        Text(subtitle!, style: AppText.navSubtitle),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArcoSegTabs extends StatelessWidget {
  const ArcoSegTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s3,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = i == selectedIndex;
            return Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 2 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: AppRadius.rSm,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                      vertical: AppSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.surface1 : Colors.transparent,
                      borderRadius: AppRadius.rSm,
                      boxShadow: active ? AppShadows.level1 : null,
                    ),
                    child: Text(
                      labels[i],
                      style: AppText.small.copyWith(
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active ? AppColors.text1 : AppColors.text3,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class ArcoFieldLabel extends StatelessWidget {
  const ArcoFieldLabel({super.key, required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.s1),
          Text(hint!, style: AppText.caption),
        ],
      ],
    );
  }
}
