import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_error_messages.dart';
import 'auth_session.dart';

/// Sign-in screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final strings = AppLocalizations.of(context);
    final session = context.appDependencies.authSession;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await session.login(
        identifier: _identifierController.text,
        password: _passwordController.text,
      );
      // On success the router redirect leaves this screen.
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(strings, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final expired = context.authSession.status == AuthStatus.expired;

    return Scaffold(
      appBar: AppBar(title: Text(strings.loginTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (expired) ...[
                    _MessageBanner(
                      text: strings.sessionExpiredMessage,
                      icon: Icons.lock_clock,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    strings.loginDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _identifierController,
                    enabled: !_busy,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: strings.loginIdentifierLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value?.trim() ?? '').isEmpty) {
                        return strings.invalidIdentifierError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_busy,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: strings.passwordLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').length < 8) {
                        return strings.weakPasswordError;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _MessageBanner(
                      text: _error!,
                      icon: Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.signInAction),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.push(AppRoutes.register),
                    child: Text(strings.needAccountAction),
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

/// Small inline banner used for session and submission feedback.
class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color),
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
