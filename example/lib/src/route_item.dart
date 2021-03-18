import 'package:flutter/material.dart';

typedef RouteCallback = void Function(BuildContext context);

class RouteItem {
  RouteItem({
    required this.title,
    required this.push,
  });

  final String title;
  final RouteCallback push;
}
