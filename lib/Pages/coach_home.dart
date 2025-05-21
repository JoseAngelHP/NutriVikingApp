import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:nutri_viking_app/Pages/client_macros_overview_page.dart';
//import 'package:nutri_viking_app/Pages/create_diet_plan.dart';
//import 'package:nutri_viking_app/Pages/client_macros_page.dart'; // Asume que crearás este archivo
import 'package:nutri_viking_app/Pages/assign_clients_page.dart';
import 'package:nutri_viking_app/Pages/main_navigation_page.dart'; // Nuevo archivo para asignación

class CoachHomeScreen extends StatelessWidget {
  final String coachId;

  const CoachHomeScreen({Key? key, required this.coachId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF301939),
      appBar: AppBar(
        title: Text('Panel del Coach', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFb51837),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // Botón nuevo para asignar clientes
        backgroundColor: Color(0xFFb51837),
        child: Icon(Icons.person_add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssignClientsPage(coachId: coachId),
            ),
          );
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF301939), Color(0xFF661c3a)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis Clientes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Expanded(child: _buildClientsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('assignedCoach', isEqualTo: coachId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar clientes',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final clients = snapshot.data!.docs;

        return ListView.builder(
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return Card(
              color: Color(0xFF4a1e5a),
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Color(0xFFb51837),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  client['name'],
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                /*subtitle: Text(
                  'Objetivo: ${client['goal']}',
                  style: TextStyle(color: Colors.white70),
                ),*/
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () => _confirmDeleteClient(
                            context,
                            client.id,
                            client['name'],
                          ),
                    ),

                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => MainNavigationPage(
                            clientId: client.id,
                            clientName: client['name'],
                            coachId: coachId,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteClient(
    BuildContext context,
    String clientId,
    String clientName,
  ) {
    // Guardamos el ScaffoldMessenger antes de cualquier operación asíncrona
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Cliente'),
          content: Text(
            '¿Estás seguro de que deseas eliminar a $clientName permanentemente?',
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar el diálogo primero

                try {
                  await _deleteClient(clientId);
                  // Usamos el scaffoldMessenger que guardamos previamente
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Cliente eliminado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al eliminar cliente: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteClient(String clientId) async {
    try {
      // 1. Eliminar de Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .delete();
    } catch (e) {
      print('Error al eliminar cliente: $e');
      throw e;
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
