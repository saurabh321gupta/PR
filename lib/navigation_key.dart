import 'package:flutter/material.dart';

/// Global navigator key — used by NotificationService to navigate
/// from background notification taps without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
