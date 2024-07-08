import 'package:elea_chat/screens/app_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/app_wrapper.dart';

final GoRouter router = GoRouter(
  initialLocation: '/main/main',
  routes: [
    GoRoute(
      path: '/main/:action',
      builder: (context, state) =>
          AppWrapper(action: state.pathParameters['action']),
    ),
  ],
);
