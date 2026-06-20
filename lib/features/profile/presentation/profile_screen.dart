import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/profile_controller.dart';
import '../data/profile_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../app/router/app_routes.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final profile = profileAsync.value;
              if (profile != null) {
                context.push('/edit-profile', extra: profile);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return _buildLoggedOutView(ref);
          return _buildProfileView(context, profile);
        },
      ),
    );
  }

  Widget _buildLoggedOutView(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Not signed in',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, ProfileModel profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.fullName?.isNotEmpty == true
                        ? profile.fullName![0].toUpperCase()
                        : profile.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.grey),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName ?? profile.username,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          if (profile.fullName != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${profile.username}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: profile.isOnline ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                profile.isOnline ? 'Online' : 'Offline',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                profile.bio!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildStatsRow(profile),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildInfoTile(
                  Icons.person,
                  'Full Name',
                  profile.fullName ?? 'Not set',
                ),
                _buildInfoTile(
                  Icons.alternate_email,
                  'Username',
                  profile.username,
                ),
                _buildInfoTile(
                  Icons.description_outlined,
                  'Bio',
                  profile.bio?.isNotEmpty == true ? profile.bio! : 'Not set',
                ),
                _buildInfoTile(
                  Icons.access_time,
                  'Last Seen',
                  profile.lastSeen != null
                      ? timeago.format(profile.lastSeen!)
                      : 'Unknown',
                ),
                _buildInfoTile(
                  Icons.calendar_today,
                  'Member Since',
                  _formatDate(profile.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ProfileModel profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Level', '1'),
        _buildStatItem('Points', '0'),
        _buildStatItem('Followers', '0'),
        _buildStatItem('Following', '0'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
