import 'package:flutter/material.dart';
import 'package:spare_kart/core/utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(r.horizontalPadding()),
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Order updates and messages'),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Promotions and deals'),
            value: false,
            onChanged: (_) {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About SpareKart'),
            subtitle: const Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}
