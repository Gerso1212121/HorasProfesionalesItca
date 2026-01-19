import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Este es el widget (clase) que encapsula tu contenido
class UsersContent extends StatefulWidget {
  const UsersContent({Key? key}) : super(key: key);

  @override
  _UsersContentState createState() => _UsersContentState();
}

Future<Map<String, dynamic>> fetchUserData(String userId) async {
  final doc = await FirebaseFirestore.instance
      .collection('estudiantes')
      .doc(userId)
      .get();
  return doc.data() ?? {};
}

class _UsersContentState extends State<UsersContent> {
  String _searchQuery = ''; // Estado para el campo de búsqueda

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Usuarios',
                style: GoogleFonts.itim(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar exportación de usuarios
                },
                icon: const Icon(Icons.download),
                label: Text(
                  'Exportar',
                  style: GoogleFonts.itim(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar usuarios...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('estudiantes')
                          // Lógica para filtrar según la búsqueda
                          // .where('nombre', isGreaterThanOrEqualTo: _searchQuery)
                          // .where('nombre', isLessThan: _searchQuery + 'z')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: GoogleFonts.itim(color: Colors.red),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final users = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nombre = (data['nombre'] ?? '').toLowerCase();
                          return nombre.contains(_searchQuery.toLowerCase());
                        }).toList();

                        if (users.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay usuarios registrados',
                                  style: GoogleFonts.itim(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final doc = users[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  child: Text(
                                    (data['nombre'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  data['nombre'] + " " + data['apellido'] ??
                                      'Sin nombre',
                                  style: GoogleFonts.itim(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['correo'] ?? 'Sin email',
                                      style: GoogleFonts.itim(),
                                    ),
                                    Text(
                                      'UID: ${doc.id}',
                                      style: GoogleFonts.itim(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      onTap: () {
                                        // TODO: Lógica para ver detalles
                                        showUserDataPopup(context, doc.id);
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.visibility),
                                          const SizedBox(width: 8),
                                          Text('Ver detalles',
                                              style: GoogleFonts.itim()),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        // TODO: Lógica para editar
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit),
                                          const SizedBox(width: 8),
                                          Text('Editar',
                                              style: GoogleFonts.itim()),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        // TODO: Lógica para eliminar
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete,
                                              color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text('Eliminar',
                                              style: GoogleFonts.itim(
                                                  color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showUserDataPopup(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchUserData(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Datos del Usuario'),
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Error al cargar los datos: ${snapshot.error}'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cerrar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            } else {
              final userData = snapshot.data ?? {};
              return AlertDialog(
                title: const Text('Datos del Usuario'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      ListTile(
                        title: const Text('Nombre:'),
                        subtitle: Text(userData['nombre'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('Apellido:'),
                        subtitle: Text(userData['apellido'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('Año:'),
                        subtitle: Text(userData['año'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('Carrera:'),
                        subtitle: Text(userData['carrera'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('Correo:'),
                        subtitle: Text(userData['correo'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('Fecha de Sincronización:'),
                        subtitle:
                            Text(userData['fecha_sincronizacion'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('Sede:'),
                        subtitle: Text(userData['sede'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('Teléfono:'),
                        subtitle: Text(userData['telefono'] ?? 'N/A'),
                      ),
                      ListTile(
                        title: const Text('UID Firebase:'),
                        subtitle: Text(userData['uid_firebase'] ?? 'N/A'),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cerrar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }
}
