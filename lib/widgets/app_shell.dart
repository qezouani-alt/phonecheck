import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.leading = true,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool leading;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _GlassBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  children: [
                    if (leading || title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Row(
                          children: [
                            if (leading)
                              _GlassBackButton(
                                onPressed: () => Navigator.maybePop(context),
                              ),
                            if (leading) const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: AppTextStyles.cardTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(child: ClipRect(child: child)),
                    if (footer != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * .38,
                          ),
                          child: SingleChildScrollView(child: footer!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackground extends StatelessWidget {
  const _GlassBackground();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF101722), Color(0xFF141A24), Color(0xFF191F29)]
              : const [Color(0xFFFAFBFD), Color(0xFFF3F6FA), Color(0xFFEEF3F8)],
        ),
      ),
      child: Stack(
        children: [
          _GlassGlow(
            alignment: const Alignment(1.12, -.65),
            color: dark ? const Color(0xFF1465C8) : const Color(0xFFA9CCF3),
          ),
          _GlassGlow(
            alignment: const Alignment(-1.1, .75),
            color: dark ? const Color(0xFF087B78) : const Color(0xFFA9DCD5),
          ),
          _GlassGlow(
            alignment: const Alignment(.92, 1.04),
            color: dark ? const Color(0xFF5949A7) : const Color(0xFFD0D0EF),
          ),
          _GlassGlow(
            alignment: const Alignment(-.94, -.95),
            color: dark ? const Color(0xFF255DA0) : const Color(0xFFFFFFFF),
          ),
        ],
      ),
    );
  }
}

class _GlassGlow extends StatelessWidget {
  const _GlassGlow({required this.alignment, required this.color});

  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Container(
      width: 520,
      height: 520,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          stops: const [0, .42, 1],
          colors: [
            color.withValues(alpha: .28),
            color.withValues(alpha: .10),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: dark
                ? Colors.white.withValues(alpha: .09)
                : Colors.white.withValues(alpha: .58),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(
              color: dark
                  ? Colors.white.withValues(alpha: .16)
                  : Colors.white.withValues(alpha: .72),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class PageContent extends StatelessWidget {
  const PageContent({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: padding, children: children);
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(22);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                color ??
                (dark
                    ? Colors.white.withValues(alpha: .075)
                    : Colors.white.withValues(alpha: .88)),
            borderRadius: radius,
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .15)
                  : const Color(0xFFDCE5EE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .18 : .055),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
