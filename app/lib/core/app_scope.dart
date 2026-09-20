import 'package:flutter/widgets.dart';

import 'session.dart';

class AppScope extends InheritedNotifier<AppSession> {
  const AppScope({
    super.key,
    required AppSession super.notifier,
    required super.child,
  });

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
