import 'package:flutter/material.dart';
import 'package:farmmarket/services/supabase_service.dart';

class AuthGate extends StatelessWidget {
  final WidgetBuilder builder;
  const AuthGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!Navigator.of(context).canPop()) {
          Navigator.pushReplacementNamed(context, '/login-screen');
        } else {
          Navigator.pushNamed(context, '/login-screen');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return builder(context);
  }
}
