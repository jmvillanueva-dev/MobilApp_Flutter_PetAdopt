import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_profile_dialog.dart';
import '../../../../injection_container.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // UserId is now managed by the provided ProfileBloc, which was initialized in HomePage
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _ProfileView(),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ProfileError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is ProfileLoaded) {
          final user = state.user;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: user.photoUrl != null
                      ? ClipOval(
                          child:
                              Image.network(user.photoUrl!, fit: BoxFit.cover))
                      : Center(
                          child: Text(
                            (user.displayName?.isNotEmpty == true)
                                ? user.displayName!
                                    .trim()
                                    .split(' ')
                                    .take(2)
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .join()
                                    .toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Name & Role
                Text(
                  user.displayName ?? 'Usuario',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role?.toUpperCase() ?? 'USUARIO',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Section
                if (user.email.isNotEmpty)
                  _ProfileInfoItem(
                      icon: Icons.email_outlined, text: user.email),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  _ProfileInfoItem(
                      icon: Icons.phone_outlined, text: user.phoneNumber!),
                if (user.address != null && user.address!.isNotEmpty)
                  _ProfileInfoItem(
                      icon: Icons.location_on_outlined, text: user.address!),

                const SizedBox(height: 32),

                // Settings List
                _ProfileOption(
                  icon: Icons.edit_outlined,
                  title: 'Editar Perfil',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => EditProfileDialog(
                        user: user,
                        onSave: (newName, newPhone, newAddress) {
                          context.read<ProfileBloc>().add(
                                ProfileUpdateRequested(
                                  userId: user.id,
                                  displayName: newName,
                                  phoneNumber: newPhone,
                                  address: newAddress,
                                ),
                              );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Logout
                _ProfileOption(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    context.read<AuthBloc>().add(const SignOutRequested());
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileInfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
