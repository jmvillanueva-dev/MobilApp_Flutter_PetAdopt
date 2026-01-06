import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/shelter_location.dart';

class ShelterMapPage extends StatefulWidget {
  const ShelterMapPage({super.key});

  @override
  State<ShelterMapPage> createState() => _ShelterMapPageState();
}

class _ShelterMapPageState extends State<ShelterMapPage> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLoading = true;
  ShelterLocation? _selectedShelter;
  String _searchQuery = '';

  // Mock data: Refugios en Quito, Ecuador
  final List<ShelterLocation> _allShelters = const [
    ShelterLocation(
      id: '1',
      name: 'Refugio Patitas Felices',
      address: 'Av. Principal #123, Quito',
      latitude: -0.1807,
      longitude: -78.4678,
      phone: '0998765432',
      petCount: 25,
    ),
    ShelterLocation(
      id: '2',
      name: 'Casa de Peludos',
      address: 'Calle La Gasca, Quito',
      latitude: -0.2105,
      longitude: -78.4916,
      phone: '0987654321',
      petCount: 18,
    ),
    ShelterLocation(
      id: '3',
      name: 'Amigos de 4 Patas',
      address: 'Av. 6 de Diciembre, Quito',
      latitude: -0.1650,
      longitude: -78.4850,
      phone: '0976543210',
      petCount: 32,
    ),
    ShelterLocation(
      id: '4',
      name: 'Hogar Animal',
      address: 'Sector Tumbaco, Quito',
      latitude: -0.2120,
      longitude: -78.3980,
      phone: '0965432109',
      petCount: 15,
    ),
    ShelterLocation(
      id: '5',
      name: 'Rescate Peludo',
      address: 'Norte de Quito',
      latitude: -0.1400,
      longitude: -78.4800,
      phone: '0954321098',
      petCount: 22,
    ),
  ];

  List<ShelterLocation> get _filteredShelters {
    if (_searchQuery.isEmpty) return _allShelters;
    return _allShelters
        .where((shelter) =>
            shelter.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      setState(() => _isLoading = true);

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationServiceDialog();
        }
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showPermissionDeniedDialog();
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_userLocation!, 13.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Even if location fails, we can still show the map with default center
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userLocation =
              const LatLng(-0.1807, -78.4678); // Default: Quito center
        });
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servicio de Ubicación Desactivado'),
        content: const Text(
            'Por favor activa los servicios de ubicación en tu dispositivo para ver tu posición en el mapa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Denegado'),
        content: const Text(
            'La aplicación necesita acceso a tu ubicación para mostrar refugios cercanos. Puedes usar el mapa sin tu ubicación o habilitar el permiso en configuración.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Mapa
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation ?? const LatLng(-0.1807, -78.4678),
                initialZoom: 13.0,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app_petadopt',
                ),
                MarkerLayer(
                  markers: [
                    // Marcador del usuario
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                    // Marcadores de refugios
                    ..._filteredShelters.map((shelter) => Marker(
                          point: LatLng(shelter.latitude, shelter.longitude),
                          width: 50,
                          height: 60,
                          child: _buildShelterMarker(shelter),
                        )),
                  ],
                ),
              ],
            ),

            // Barra de búsqueda
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildSearchBar(),
            ),

            // Card de información del refugio seleccionado
            if (_selectedShelter != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildShelterCard(_selectedShelter!),
              ),

            // FAB para re-centrar ubicación
            Positioned(
              bottom: _selectedShelter != null ? 200 : 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF00BFA5),
                onPressed: _initLocation,
                child: const Icon(Icons.gps_fixed, color: Colors.white),
              ),
            ),

            // Indicador de carga
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00BFA5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar refugios...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _selectedShelter = null;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchQuery = '';
                  _selectedShelter = null;
                });
              },
              child: const Icon(Icons.clear, color: Colors.grey, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildShelterMarker(ShelterLocation shelter) {
    final isSelected = _selectedShelter?.id == shelter.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedShelter = shelter);
        _mapController.move(
          LatLng(shelter.latitude, shelter.longitude),
          15.0,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFF00BFA5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isSelected
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF00BFA5))
                      .withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 24,
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color:
                isSelected ? const Color(0xFFFF6B35) : const Color(0xFF00BFA5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildShelterCard(ShelterLocation shelter) {
    final distance = _userLocation != null
        ? shelter.distanceTo(_userLocation!.latitude, _userLocation!.longitude)
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home,
                  color: Color(0xFF00BFA5),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelter.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shelter.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedShelter = null),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (distance != null) ...[
                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 20),
              ],
              Icon(Icons.pets, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${shelter.petCount} mascotas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (shelter.phone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  shelter.phone!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a detalles del refugio
              },
              icon: const Icon(Icons.arrow_forward, size: 20),
              label: const Text('Ver detalles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
