import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/discovery/discovery_bloc.dart';
import 'pet_detail_page.dart';

class PetDiscoveryPage extends StatelessWidget {
  const PetDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<DiscoveryBloc>()..add(const LoadDiscoveryPets()),
      child: const _PetDiscoveryView(),
    );
  }
}

class _PetDiscoveryView extends StatefulWidget {
  const _PetDiscoveryView();

  @override
  State<_PetDiscoveryView> createState() => _PetDiscoveryViewState();
}

class _PetDiscoveryViewState extends State<_PetDiscoveryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final bloc = context.read<DiscoveryBloc>();
    final currentSpecies = (bloc.state is DiscoveryLoaded)
        ? (bloc.state as DiscoveryLoaded).activeSpeciesFilter
        : 'todos';

    bloc.add(LoadDiscoveryPets(query: value, species: currentSpecies));
  }

  void _onFilterChanged(String species) {
    final bloc = context.read<DiscoveryBloc>();
    bloc.add(
        LoadDiscoveryPets(query: _searchController.text, species: species));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            _buildFilters(context),
            Expanded(
              child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is DiscoveryError) {
                    return Center(child: Text('Error: ${state.message}'));
                  } else if (state is DiscoveryLoaded) {
                    if (state.pets.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron mascotas'),
                      );
                    }
                    return _buildPetsGrid(context, state.pets);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, Adoptante 👋',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Encuentra tu mascota',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, size: 28),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('2',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Buscar mascota...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {}, // TODO: Abrir filtros avanzados
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        String activeFilter = 'todos';
        if (state is DiscoveryLoaded) {
          activeFilter = state.activeSpeciesFilter;
        }

        return Container(
          height: 50,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildFilterChip(context, 'Todos', 'todos', activeFilter),
              const SizedBox(width: 12),
              _buildFilterChip(context, '🐶 Perros', 'perro', activeFilter),
              const SizedBox(width: 12),
              _buildFilterChip(context, '🐱 Gatos', 'gato', activeFilter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, String value, String activeValue) {
    final isSelected = value == activeValue;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPetsGrid(BuildContext context, List<PetEntity> pets) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return _buildPetCard(context, pet);
      },
    );
  }

  Widget _buildPetCard(BuildContext context, PetEntity pet) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailPage(pet: pet),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(pet.species),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      image: pet.primaryPhotoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(pet.primaryPhotoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: pet.primaryPhotoUrl == null
                        ? Center(
                            child: Icon(
                              Icons.pets,
                              size: 40,
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.breed ?? 'Mestizo'} • ${pet.ageYears} años',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(
                        '2.5 km', // Placeholder para distancia
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(String species) {
    if (species.toLowerCase() == 'perro')
      return const Color(0xFFFFF8E1); // Amber accent
    if (species.toLowerCase() == 'gato')
      return const Color(0xFFE0F2F1); // Teal accent
    return const Color(0xFFF5F5F5);
  }
}
