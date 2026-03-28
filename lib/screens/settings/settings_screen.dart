import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _biometricService = BiometricService();
  final _nameController = TextEditingController();

  bool _isEditingName = false;
  bool _isSavingName = false;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _biometricLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final supported = await _biometricService.isDeviceSupported();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = enabled;
        _biometricLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable biometric login',
      );
      if (!authenticated) return;
    }
    await _biometricService.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _biometricEnabled = value);
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSavingName = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(fullName: newName);
      ref.invalidate(profileProvider);
      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Profile section
          _buildSectionHeader('Profile'),
          profileAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.error_outline,
                  color: AppTheme.errorColor),
              title: const Text('Could not load profile'),
              subtitle: Text(error.toString()),
            ),
            data: (profile) {
              if (profile == null) {
                return const ListTile(
                  title: Text('Not signed in'),
                );
              }

              if (!_isEditingName) {
                _nameController.text = profile.fullName ?? '';
              }

              return Column(
                children: [
                  // Display name
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: _isEditingName
                        ? TextField(
                            controller: _nameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter display name',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          )
                        : Text(
                            profile.fullName ?? 'No name set',
                            style: TextStyle(
                              color: profile.fullName != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                            ),
                          ),
                    subtitle: const Text('Display name'),
                    trailing: _isEditingName
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSavingName)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              else ...[
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: AppTheme.successColor),
                                  onPressed: _saveName,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: AppTheme.textMuted),
                                  onPressed: () => setState(
                                      () => _isEditingName = false),
                                ),
                              ],
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 20, color: AppTheme.textSecondary),
                            onPressed: () {
                              _nameController.text = profile.fullName ?? '';
                              setState(() => _isEditingName = true);
                            },
                          ),
                  ),
                  const Divider(),

                  // Email
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(profile.email),
                    subtitle: const Text('Email'),
                  ),
                ],
              );
            },
          ),

          const Divider(height: 32),

          // Security section
          _buildSectionHeader('Security'),
          if (_biometricLoading)
            const ListTile(
              leading: Icon(Icons.fingerprint),
              title: Text('Biometric Login'),
              trailing: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_biometricSupported)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Login'),
              subtitle: const Text('Use fingerprint or face to sign in'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            )
          else
            const ListTile(
              leading: Icon(Icons.fingerprint, color: AppTheme.textMuted),
              title: Text('Biometric Login'),
              subtitle: Text('Not supported on this device'),
            ),

          const Divider(height: 32),

          // Account section
          _buildSectionHeader('Account'),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.errorColor),
            title: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: _signOut,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
