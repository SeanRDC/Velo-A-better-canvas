// Lets a screen redraw when a background Canvas refresh brings back new data.
import 'package:flutter/widgets.dart';

import 'canvas_service.dart';

// Screens show saved data immediately while CanvasService refreshes it in the
// background. Mix this in and reload in [onCanvasRefreshed]; that reload reads
// the now-fresh saved copy, so it should not show a loading spinner.
mixin CanvasRefreshMixin<T extends StatefulWidget> on State<T> {
  void onCanvasRefreshed();

  void _handleRefresh() {
    if (mounted) onCanvasRefreshed();
  }

  @override
  void initState() {
    super.initState();
    CanvasService.dataRevision.addListener(_handleRefresh);
  }

  @override
  void dispose() {
    CanvasService.dataRevision.removeListener(_handleRefresh);
    super.dispose();
  }
}
