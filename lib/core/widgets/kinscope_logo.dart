import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Kinscope stacked lockup (mark + wordmark as one image). Swaps to the
/// light-ink variant on dark backgrounds, per the brand sheet's misuse rules.
class KinscopeLogo extends StatelessWidget {
  final double width;

  const KinscopeLogo({super.key, this.width = 140});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/brand/kinscope-lockup-light.svg'
        : 'assets/brand/kinscope-lockup.svg';

    return SvgPicture.asset(asset, width: width);
  }
}
