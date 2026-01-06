import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/pets/presentation/bloc/pets_bloc.dart';
import '../../../../features/pets/presentation/bloc/pets_state.dart';
import '../../../adoption/presentation/bloc/adoption_bloc.dart';
import '../../../adoption/presentation/bloc/adoption_event.dart';
import '../../../adoption/presentation/bloc/adoption_state.dart';
import '../../../adoption/presentation/pages/adoption_requests_page.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ShelterHomePage extends StatefulWidget {
  final UserEntity user;
  final Function(int)? onTabChange;

  const ShelterHomePage({
    super.key,
    required this.user,
    this.onTabChange,
  });

  @override
  State<ShelterHomePage> createState() => _ShelterHomePageState();
}

class _ShelterHomePageState extends State<ShelterHomePage> {
  @override
  Widget build(BuildContext context) {
    // PetsBloc is now provided by HomePage, so we only need AdoptionBloc here
    return BlocProvider(
      create: (_) => GetIt.I<AdoptionBloc>()..add(LoadShelterRequests()),
      child: _ShelterDashboard(
        user: widget.user,
        onTabChange: widget.onTabChange,
      ),
    );
  }
}

class _ShelterDashboard extends StatelessWidget {
  final UserEntity user;
  final Function(int)? onTabChange;

  const _ShelterDashboard({
    required this.user,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          // Header / App Bar Personalizado
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),

          // Estats
          SliverToBoxAdapter(
            child: _buildStats(context),
          ),

          // Título Solicitudes Recientes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solicitudes Recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3B48),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navegar al tab de solicitudes (index 2 en main) or push page
                      // En este layout, el user puede simplemente usar el bottom nav.
                      // O podemos hacer un push.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AdoptionRequestsPage()),
                      );
                    },
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(color: Colors.orange),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Lista de Solicitudes Recientes (Limitada a 3)
          SliverToBoxAdapter(
            child: _buildRecentRequestsList(),
          ),

          // Título Mis Mascotas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Mascotas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3B48),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Cambiar a la pestaña de Mascotas (índice 1 para refugios)
                      onTabChange?.call(1);
                    },
                    icon: const Icon(Icons.pets, size: 18),
                    label: const Text('Ver Mascotas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de Mascotas (Horizontal o Vertical corta)
          SliverToBoxAdapter(
            child: _buildMyPetsPreview(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF00BFA5),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.store, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Refugio',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Panel de administración',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined, color: Colors.white))
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<PetsBloc, PetsState>(
              builder: (context, state) {
                int count = 0;
                if (state is PetsLoaded) count = state.pets.length;
                return _StatCard(
                  count: count.toString(),
                  label: 'Mascotas',
                  color: const Color(0xFF00C853), // Greenish
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<AdoptionBloc, AdoptionState>(
              builder: (context, state) {
                int count = 0;
                if (state is AdoptionLoaded) {
                  count = state.requests
                      .where((r) => r.status == 'pendiente')
                      .length;
                }
                return _StatCard(
                  count: count.toString(),
                  label: 'Pendientes',
                  color: const Color(0xFFFFAB40), // Orange
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<AdoptionBloc, AdoptionState>(
              builder: (context, state) {
                int count = 0;
                if (state is AdoptionLoaded) {
                  count = state.requests
                      .where((r) => r.status == 'aprobada')
                      .length;
                }
                // Nota: Idealmente contaríamos adopciones históricas, aquí filtramos solicitudes aprobadas recientes
                return _StatCard(
                  count: count.toString(),
                  label: 'Adoptadas',
                  color: const Color(0xFF29B6F6), // Blue
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRequestsList() {
    return BlocBuilder<AdoptionBloc, AdoptionState>(
      builder: (context, state) {
        if (state is AdoptionLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdoptionLoaded) {
          final requests = state.requests.take(3).toList(); // Solo mostrar 3

          if (requests.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No hay solicitudes recientes',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                          image: req.petPhotoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(req.petPhotoUrl!),
                                  fit: BoxFit.cover)
                              : null),
                      child: req.petPhotoUrl == null
                          ? const Icon(Icons.pets, color: Colors.orange)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitud para ${req.petName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'De: ${req.adopterNamr ?? 'Usuario'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (req.status == 'pendiente') ...[
                      _SmallActionBtn(
                          icon: Icons.check,
                          color: Colors.green,
                          onTap: () {
                            context.read<AdoptionBloc>().add(
                                UpdateRequestStatus(
                                    requestId: req.id, status: 'aprobada'));
                          }),
                      const SizedBox(width: 8),
                      _SmallActionBtn(
                          icon: Icons.close,
                          color: Colors.red,
                          onTap: () {
                            context.read<AdoptionBloc>().add(
                                UpdateRequestStatus(
                                    requestId: req.id, status: 'rechazada'));
                          }),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: (req.status == 'aprobada'
                                    ? Colors.green
                                    : Colors.red)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(req.status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: req.status == 'aprobada'
                                    ? Colors.green
                                    : Colors.red)),
                      )
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMyPetsPreview() {
    return BlocBuilder<PetsBloc, PetsState>(
      builder: (context, state) {
        if (state is PetsLoaded) {
          if (state.pets.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('No has publicado mascotas aún.'),
            );
          }

          return SizedBox(
            height: 160,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: state.pets.length,
              itemBuilder: (context, index) {
                final pet = state.pets[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                            image: pet.primaryPhotoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(pet.primaryPhotoUrl!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: pet.primaryPhotoUrl == null
                              ? const Center(
                                  child: Icon(Icons.pets, color: Colors.grey))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        pet.status, // Disponible / Adoptado
                        style: TextStyle(
                            fontSize: 12,
                            color: pet.status == 'adoptado'
                                ? Colors.orange
                                : Colors.green),
                      )
                    ],
                  ),
                );
              },
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
