import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/adoption_request_entity.dart';
import '../bloc/adoption_bloc.dart';
import '../bloc/adoption_event.dart';
import '../bloc/adoption_state.dart';

class AdoptionRequestsPage extends StatelessWidget {
  const AdoptionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<AdoptionBloc>(),
      child: const _AdoptionView(),
    );
  }
}

class _AdoptionView extends StatefulWidget {
  const _AdoptionView();

  @override
  State<_AdoptionView> createState() => _AdoptionViewState();
}

class _AdoptionViewState extends State<_AdoptionView> {
  String _selectedFilter = 'todos'; // todos, pendiente, aprobada, rechazada

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'adoptante';

    if (role == 'refugio') {
      context.read<AdoptionBloc>().add(LoadShelterRequests());
    } else {
      context.read<AdoptionBloc>().add(LoadAdopterRequests());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'adoptante';
    final isShelter = role == 'refugio';

    return Scaffold(
      appBar: AppBar(
        title: Text(isShelter ? 'Solicitudes Recibidas' : 'Mis Solicitudes'),
      ),
      body: BlocConsumer<AdoptionBloc, AdoptionState>(
        listener: (context, state) {
          if (state is AdoptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AdoptionOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          if (state is AdoptionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<AdoptionRequestEntity> requests = [];
          if (state is AdoptionLoaded) {
            requests = state.requests;
          }

          // Filtrar
          final filteredRequests = requests.where((req) {
            if (_selectedFilter == 'todos') return true;
            return req.status == _selectedFilter;
          }).toList();

          return Column(
            children: [
              _buildFilters(context),
              Expanded(
                child: filteredRequests.isEmpty
                    ? _buildEmptyState(isShelter)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = filteredRequests[index];
                          return _buildRequestCard(context, request, isShelter);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('Todos', 'todos'),
          const SizedBox(width: 8),
          _filterChip('Pendientes', 'pendiente'),
          const SizedBox(width: 8),
          _filterChip('Aprobadas', 'aprobada'),
          const SizedBox(width: 8),
          _filterChip('Rechazadas', 'rechazada'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  Widget _buildEmptyState(bool isShelter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isShelter
                ? 'No hay solicitudes con este filtro'
                : 'No se encontraron solicitudes',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, AdoptionRequestEntity request, bool isShelter) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: request.petPhotoUrl != null
                      ? NetworkImage(request.petPhotoUrl!)
                      : null,
                  child: request.petPhotoUrl == null
                      ? const Icon(Icons.pets)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.petName ?? 'Mascota',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Enviado el ${_formatDate(request.createdAt)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Botón de eliminar solo para adoptantes (cancelar solicitud) y si está pendiente
                if (!isShelter && request.status == 'pendiente')
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _confirmDelete(context, request.id),
                    tooltip: 'Cancelar solicitud',
                  ),
              ],
            ),
            const Divider(height: 24),
            if (isShelter) ...[
              Text(
                'De: ${request.adopterNamr ?? 'Usuario'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              request.message ?? 'Sin mensaje',
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
            if (isShelter && request.status == 'pendiente') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _updateStatus(context, request.id, 'rechazada'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Rechazar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _updateStatus(context, request.id, 'aprobada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aprobar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar solicitud?'),
        content: const Text(
            'Esta acción eliminará tu solicitud de adopción. ¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<AdoptionBloc>()
                  .add(DeleteAdoptionRequest(requestId));
            },
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String requestId, String status) {
    context.read<AdoptionBloc>().add(
          UpdateRequestStatus(requestId: requestId, status: status),
        );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
