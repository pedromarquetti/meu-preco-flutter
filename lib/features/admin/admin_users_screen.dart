import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models/models.dart';
import '../../core/ui/empty_view.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/loading_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'data/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final AdminRepository _repository =
      context.appDependencies.adminRepository;
  List<UserView> _users = const [];
  bool _loading = true;
  String? _error;
  int page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pageResult = await _repository.listUsers(page: page);
      setState(() {
        _users = pageResult.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeRole(UserView user) async {
    final strings = AppLocalizations.of(context);
    final session = context.authSession;
    if (user.id == session.user?.id) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.adminCannotChangeOwnRole)));
      return;
    }
    final currentRole = user.role ?? UserRole.user;
    final newRole = currentRole == UserRole.admin
        ? UserRole.user
        : UserRole.admin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.adminConfirmRoleChange),
        content: Text(
          '${user.name ?? user.email ?? ''} → ${newRole == UserRole.admin ? strings.adminPromoteToAdmin : strings.adminDemoteToUser}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.confirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.updateUserRole(userId: user.id!, role: newRole);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_users.isEmpty) return const EmptyView(title: '');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isAdmin = user.role == UserRole.admin;
          return Card(
            child: ListTile(
              title: Text(user.name ?? user.email ?? '-'),
              subtitle: Text(user.email ?? ''),
              trailing: TextButton(
                onPressed: () => _changeRole(user),
                child: Text(
                  isAdmin
                      ? strings.adminDemoteToUser
                      : strings.adminPromoteToAdmin,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
