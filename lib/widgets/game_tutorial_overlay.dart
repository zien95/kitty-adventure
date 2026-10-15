import 'package:flutter/material.dart';

class GameTutorialStep {
  final GlobalKey targetKey;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final String clickHint;

  const GameTutorialStep({
    required this.targetKey,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.clickHint,
  });
}

class GameTutorialOverlay extends StatefulWidget {
  final GlobalKey rootKey;
  final List<GameTutorialStep> steps;
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const GameTutorialOverlay({
    super.key,
    required this.rootKey,
    required this.steps,
    required this.currentStep,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<GameTutorialOverlay> createState() => _GameTutorialOverlayState();
}

class _GameTutorialOverlayState extends State<GameTutorialOverlay> {
  Rect? _targetRect;
  bool _measurementPending = false;

  void _scheduleMeasurement() {
    if (_measurementPending) return;
    _measurementPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementPending = false;
      if (!mounted) return;
      final targetRect = _readTargetRect();
      if (targetRect != _targetRect) {
        setState(() => _targetRect = targetRect);
      }
    });
  }

  @override
  void didUpdateWidget(covariant GameTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.rootKey != widget.rootKey ||
        oldWidget.steps.isEmpty ||
        widget.steps.isEmpty ||
        oldWidget.steps[oldWidget.currentStep].targetKey !=
            widget.steps[widget.currentStep].targetKey) {
      _targetRect = null;
    }
  }

  Rect? _readTargetRect() {
    if (widget.steps.isEmpty) return null;
    final rootContext = widget.rootKey.currentContext;
    final targetContext =
        widget.steps[widget.currentStep].targetKey.currentContext;
    if (rootContext == null || targetContext == null) return null;

    final rootBox = rootContext.findRenderObject();
    final targetBox = targetContext.findRenderObject();
    final overlayBox = context.findRenderObject();
    if (rootBox is! RenderBox ||
        targetBox is! RenderBox ||
        overlayBox is! RenderBox ||
        !rootBox.hasSize ||
        !targetBox.hasSize ||
        !overlayBox.hasSize ||
        !targetBox.attached) {
      return null;
    }

    final offset =
        overlayBox.globalToLocal(targetBox.localToGlobal(Offset.zero));
    return offset & targetBox.size;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final step = widget.steps[widget.currentStep];
    final highlightRect = _targetRect?.inflate(8);
    final isLastStep = widget.currentStep == widget.steps.length - 1;

    return LayoutBuilder(builder: (context, constraints) {
      // Global keys have no geometry on the first build. Measure after layout
      // and repeat when parent layout or the current step changes.
      _scheduleMeasurement();
      final size = constraints.biggest;
      final safeTop = media.padding.top.clamp(16.0, double.infinity);
      final safeBottom = media.padding.bottom.clamp(16.0, double.infinity);
      final availableHeight =
          (size.height - safeTop - safeBottom).clamp(0.0, double.infinity);
      final topSpace = highlightRect == null
          ? availableHeight
          : (highlightRect.top - 16 - safeTop).clamp(0.0, availableHeight);
      final bottomSpace = highlightRect == null
          ? 0.0
          : (size.height - safeBottom - highlightRect.bottom - 16)
              .clamp(0.0, availableHeight);
      final targetIsHigh = bottomSpace > topSpace;
      final cardHeight = targetIsHigh ? bottomSpace : topSpace;

      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SpotlightPainter(highlightRect: highlightRect),
              ),
            ),
          ),
          ..._tapBlockers(size, highlightRect),
          if (highlightRect != null)
            Positioned.fromRect(
              rect: highlightRect,
              child: IgnorePointer(
                key: const ValueKey('game-tour-highlight'),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.45, end: 1),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: step.accentColor.withValues(alpha: value),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: step.accentColor.withValues(
                              alpha: 0.28 * value,
                            ),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned.fill(
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Align(
                alignment:
                    targetIsHigh ? Alignment.bottomCenter : Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    maxHeight: cardHeight > 0 ? cardHeight : availableHeight,
                  ),
                  child: Material(
                    color: const Color(0xFFF8FBFF),
                    elevation: 16,
                    shadowColor: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: SingleChildScrollView(
                        key: ValueKey(widget.currentStep),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: step.accentColor.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    step.icon,
                                    color: step.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: const TextStyle(
                                          color: Color(0xFF233247),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'Step ${widget.currentStep + 1} of ${widget.steps.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF60728A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Skip game tour',
                                  onPressed: widget.onSkip,
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step.description,
                              style: const TextStyle(
                                color: Color(0xFF334052),
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: step.accentColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: step.accentColor.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: step.accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.clickHint,
                                      style: const TextStyle(
                                        color: Color(0xFF334052),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 5,
                                value: (widget.currentStep + 1) /
                                    widget.steps.length,
                                color: step.accentColor,
                                backgroundColor: const Color(0xFFDCE5EF),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.currentStep > 0)
                                  IconButton(
                                    tooltip: 'Previous step',
                                    onPressed: widget.onBack,
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                TextButton.icon(
                                  onPressed: widget.onSkip,
                                  icon: const Icon(Icons.skip_next, size: 18),
                                  label: const Text('Skip'),
                                ),
                                FilledButton.icon(
                                  onPressed: widget.onNext,
                                  icon: Icon(
                                    isLastStep
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                    size: 18,
                                  ),
                                  label: Text(isLastStep ? 'Finish' : 'Next'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: step.accentColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  List<Widget> _tapBlockers(Size size, Rect? highlightRect) {
    final screenRect = Offset.zero & size;
    final safeHighlightRect = highlightRect?.intersect(screenRect);
    if (safeHighlightRect == null ||
        safeHighlightRect.width <= 0 ||
        safeHighlightRect.height <= 0) {
      return const [Positioned.fill(child: _TapBlocker())];
    }

    final blockers = <Widget>[];
    void addBlocker({
      double? left,
      double? top,
      double? right,
      double? bottom,
      double? width,
      double? height,
    }) {
      if ((width != null && width <= 0) || (height != null && height <= 0)) {
        return;
      }

      blockers.add(
        Positioned(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          width: width,
          height: height,
          child: const _TapBlocker(),
        ),
      );
    }

    addBlocker(left: 0, top: 0, right: 0, height: safeHighlightRect.top);
    addBlocker(left: 0, top: safeHighlightRect.bottom, right: 0, bottom: 0);
    addBlocker(
      left: 0,
      top: safeHighlightRect.top,
      width: safeHighlightRect.left,
      height: safeHighlightRect.height,
    );
    addBlocker(
      left: safeHighlightRect.right,
      top: safeHighlightRect.top,
      right: 0,
      height: safeHighlightRect.height,
    );
    return blockers;
  }
}

class _TapBlocker extends StatelessWidget {
  const _TapBlocker();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: const SizedBox.expand(),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? highlightRect;

  const _SpotlightPainter({required this.highlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xD900101D),
    );

    if (highlightRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect!, const Radius.circular(12)),
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect;
  }
}
