import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../adoption/presentation/pages/adoption_requests_page.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../chat/presentation/pages/chat_page.dart'; // Contains ChatPageProvider
import '../../../map/presentation/pages/shelter_map_page.dart';
import '../../../pets/presentation/bloc/pets_bloc.dart';
import '../../../pets/presentation/bloc/pets_event.dart';
import '../../../pets/presentation/pages/pet_discovery_page.dart';
import '../../../pets/presentation/pages/pets_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../../injection_container.dart';
import 'shelter_home_page.dart';

class HomePage extends StatefulWidget {
  final UserEntity user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final PetsBloc _petsBloc;

  @override
  void initState() {
    super.initState();
    // Create PetsBloc only for shelter users
    if (widget.user.role == 'refugio') {
      _petsBloc = getIt<PetsBloc>()..add(PetsLoadRequested(widget.user.id));
    }
  }

  @override
  void dispose() {
    if (widget.user.role == 'refugio') {
      _petsBloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdoptante = widget.user.role == 'adoptante';

    // Define tabs based on role
    final List<Widget> pages = isAdoptante
        ? [
            const PetDiscoveryPage(),
            const ShelterMapPage(), // Mapa de refugios
            const ChatPageProvider(), // Chat IA
            const AdoptionRequestsPage(),
            const ProfilePage(),
          ]
        : [
            BlocProvider.value(
              value: _petsBloc,
              child: ShelterHomePage(
                user: widget.user,
                onTabChange: (index) => setState(() => _currentIndex = index),
              ),
            ),
            BlocProvider.value(
              value: _petsBloc,
              child: PetsListPage(user: widget.user),
            ),
            const AdoptionRequestsPage(),
            const ProfilePage(),
          ];

    final List<BottomNavigationBarItem> items = isAdoptante
        ? const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Mapa'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chat IA'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Solicitudes'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil'),
          ]
        : const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio'),
            BottomNavigationBarItem(
                icon: Icon(Icons.pets),
                activeIcon: Icon(Icons.pets),
                label: 'Mascotas'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                activeIcon: Icon(Icons.list_alt),
                label: 'Solicitudes'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil'),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: items,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
        ),
      ),
    );
  }
}
