// Lays cards out in as many equal-width columns as fit the available width, so lists fill wide
// screens with more columns instead of leaving empty space at the sides.
import 'package:flutter/material.dart';

class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.minItemWidth = 340,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor();
        final columns = fit < 1 ? 1 : fit;

        final List<Widget> rows = [];
        for (int i = 0; i < children.length; i += columns) {
          if (i > 0) rows.add(SizedBox(height: spacing));

          if (columns == 1) {
            rows.add(children[i]);
            continue;
          }

          final List<Widget> cells = [];
          for (int c = 0; c < columns; c++) {
            if (c > 0) cells.add(SizedBox(width: spacing));
            final index = i + c;
            cells.add(Expanded(
              child: index < children.length ? children[index] : const SizedBox.shrink(),
            ));
          }

          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cells,
            ),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}
