import 'package:flutter/material.dart';
import 'dart:core';

typedef void RouteCallback(BuildContext context);

class RouteItem {
  RouteItem({
    required this.title,
    required this.push,
  });

  final String title;
  final RouteCallback push;
}
