import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyPushEnabled = 'notification_push_enabled';
const _keyNewMessages = 'notification_new_messages';
const _keyListingUpdates = 'notification_listing_updates';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _newMessages = true;
  bool _listingUpdates = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool(_keyPushEnabled) ?? true;
      _newMessages = prefs.getBool(_keyNewMessages) ?? true;
      _listingUpdates = prefs.getBool(_keyListingUpdates) ?? true;
      _loading = false;
    });
  }

  Future<void> _setPushEnabled(bool v) async {
    setState(() => _pushEnabled = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushEnabled, v);
  }

  Future<void> _setNewMessages(bool v) async {
    setState(() => _newMessages = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNewMessages, v);
  }

  Future<void> _setListingUpdates(bool v) async {
    setState(() => _listingUpdates = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyListingUpdates, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSwitch(
                  title: 'Push notifications',
                  subtitle: 'Receive push notifications on this device',
                  value: _pushEnabled,
                  onChanged: _setPushEnabled,
                ),
                const SizedBox(height: 12),
                _buildSwitch(
                  title: 'New messages',
                  subtitle: 'When someone sends you a message',
                  value: _newMessages,
                  onChanged: _setNewMessages,
                ),
                const SizedBox(height: 12),
                _buildSwitch(
                  title: 'Listing updates',
                  subtitle: 'When listings you saved are updated',
                  value: _listingUpdates,
                  onChanged: _setListingUpdates,
                ),
              ],
            ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
