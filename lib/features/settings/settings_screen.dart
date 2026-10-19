import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../core/config/app_config.dart';
import '../../core/http/server_health_service.dart';
import '../../core/models/models.dart';
import '../../l10n/generated/app_localizations.dart';

/// Frontend configuration: change the API host, reset to defaults, and view
/// the active server.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _checking = false;
  ServerHealthResult? _result;
  ServerHealthResult? _health;
  ServerHealthResult? _readiness;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.appDependencies.config.apiOrigin.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final strings = AppLocalizations.of(context);
    if (value == null || AppConfig.tryParseOrigin(value) == null) {
      return strings.invalidServerUrl;
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final deps = context.appDependencies;
    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await deps.healthChecker.check(_controller.text);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _busy = false;
        _result = result;
      });
      return;
    }
    await deps.configController.saveOrigin(_controller.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  Future<void> _resetToDefault() async {
    final deps = context.appDependencies;
    await deps.configController.resetToDefault();
    if (!mounted) return;
    _controller.text = deps.config.apiOrigin.toString();
    setState(() {
      _result = const ServerHealthResult.ok();
      _health = null;
      _readiness = null;
    });
  }

  /// Probes both `/healthz` (liveness) and `/readyz` (readiness) for the
  /// address currently typed, without saving it.
  Future<void> _checkConnectivity() async {
    final deps = context.appDependencies;
    setState(() {
      _checking = true;
      _health = null;
      _readiness = null;
    });
    final health = await deps.healthChecker.check(_controller.text);
    final readiness = await deps.healthChecker.checkReadiness(_controller.text);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _health = health;
      _readiness = readiness;
    });
  }

  Future<void> _logout() async {
    await context.appDependencies.authSession.logout();
  }

  String _roleLabel(AppLocalizations strings, UserRole? role) {
    return switch (role) {
      UserRole.admin => strings.adminRoleLabel,
      UserRole.user => strings.userRoleLabel,
      null => strings.notAuthenticatedLabel,
    };
  }

  String _messageFor(AppLocalizations strings, ServerHealthResult result) {
    if (result.ok) return strings.serverConnectionSuccess;
    switch (result.errorCode) {
      case 'invalid_url':
        return strings.invalidServerUrl;
      case 'timeout':
        return strings.serverConnectionTimeout;
      default:
        return strings.serverConnectionFailure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = context.appConfig;
    final session = context.authSession;

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.accountSection,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${strings.currentUserLabel}: '
                        '${session.user?.email ?? strings.notAuthenticatedLabel}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${strings.roleLabel}: '
                        '${_roleLabel(strings, session.user?.role)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _logout,
                          icon: const Icon(Icons.logout),
                          label: Text(strings.logoutAction),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.settingsServerSection,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${strings.currentHostLabel}: '
                        '${config.apiOrigin.toString()}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${strings.apiPrefixLabel}: ${config.apiPrefix}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.connectivitySection,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (_health != null || _readiness != null) ...[
                        const SizedBox(height: 12),
                        if (_health != null)
                          _StatusRow(
                            label: strings.healthStatusLabel,
                            ok: _health!.ok,
                            text: _messageFor(strings, _health!),
                          ),
                        if (_readiness != null) ...[
                          const SizedBox(height: 8),
                          _StatusRow(
                            label: strings.readinessStatusLabel,
                            ok: _readiness!.ok,
                            text: _readiness!.ok
                                ? strings.readinessHealthyLabel
                                : strings.readinessUnavailableLabel,
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _busy || _checking
                              ? null
                              : _checkConnectivity,
                          icon: _checking
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: Text(strings.checkConnectivityAction),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controller,
                  enabled: !_busy,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: strings.serverAddressLabel,
                    hintText: strings.serverAddressHint,
                    helperText: strings.serverAddressHelp,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validate,
                  onFieldSubmitted: (_) => _save(),
                ),
              ),
              const SizedBox(height: 16),
              if (_result != null) ...[
                Row(
                  children: [
                    Icon(
                      _result!.ok
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: _result!.ok
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _messageFor(strings, _result!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _result!.ok
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.testConnection),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _resetToDefault,
                      child: Text(strings.settingsResetToDefault),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back),
                label: Text(strings.homeTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok, required this.text});

  final String label;
  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ok ? theme.colorScheme.primary : theme.colorScheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $text',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
