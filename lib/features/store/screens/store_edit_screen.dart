import 'package:flutter/material.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart' as profile;
import 'package:shoplancer_vendor/features/store/screens/store_settings_screen.dart';

class StoreEditScreen extends StatelessWidget {
  final profile.Store store;
  const StoreEditScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreSettingsScreen(store: store);
  }
}
