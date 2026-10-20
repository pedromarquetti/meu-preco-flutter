import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../core/config/app_config.dart';
import '../../core/http/server_health_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// First screen on boot: pick (or confirm) the Meu Preço API server.
///
/// The app only proceeds to login after `GET /healthz` succeeds for the
/// selected origin.
class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  ServerHealthResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.appDependencies.config.apiOrigin.toString(),
    );
    // Surface a saved server that failed its boot-time health check.
    _result = context.appDependencies.serverGate;
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

  Future<void> _probe() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final healthChecker = context.appDependencies.healthChecker;
    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await healthChecker.check(_controller.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  Future<void> _saveAndContinue() async {
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
    deps.serverGate = null;
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(AppRoutes.login);
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

    return Scaffold(
      appBar: AppBar(title: Text(strings.serverConfigTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.appDescription,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
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
                    onFieldSubmitted: (_) => _saveAndContinue(),
                  ),
                  const SizedBox(height: 16),
                  if (_result != null) ...[
                    _StatusBanner(
                      result: _result!,
                      text: _messageFor(strings, _result!),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => {
                            _probe().then(
                              (_) => _result?.ok == true
                                  ? _saveAndContinue()
                                  : null,
                            ),
                          },
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.saveAndContinue),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _busy ? null : _probe,
                    child: Text(strings.testConnection),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.result, required this.text});

  final ServerHealthResult result;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.ok
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    return Row(
      children: [
        Icon(
          result.ok ? Icons.check_circle_outline : Icons.error_outline,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
