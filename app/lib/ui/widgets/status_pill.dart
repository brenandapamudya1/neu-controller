// Connection + latency pill (DESIGN.md 5.3). Never color-only:
// the state is always spelled out in text next to the dot.

import 'package:flutter/widgets.dart';

import '../../core/theme.dart';

/// Green below 30 ms, yellow otherwise with a reply, red when [rttMs]
/// is null (no reply within timeout).
class StatusPill extends StatelessWidget {
  final int? rttMs;

  const StatusPill({super.key, required this.rttMs});

  @override
  Widget build(BuildContext context) {
    final NeuPalette palette = NeuTheme.of(context);
    final int? rtt = rttMs;
    final Color color;
    final String label;
    if (rtt == null) {
      color = palette.error;
      label = 'Disconnected';
    } else if (rtt < kGoodLatencyMs) {
      color = palette.ok;
      label = 'Connected · $rtt ms';
    } else {
      color = palette.warn;
      label = 'Slow · $rtt ms';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: NeuSizes.labelMinFontSize,
          ),
        ),
      ],
    );
  }
}

/// Below this round-trip the link counts as good (DESIGN.md 5.3).
const int kGoodLatencyMs = 30;
