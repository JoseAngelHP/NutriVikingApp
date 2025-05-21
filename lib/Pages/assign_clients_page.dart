import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignClientsPage extends StatelessWidget {
  final String coachId;

  const AssignClientsPage({Key? key, required this.coachId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF301939),
      appBar: AppBar(
        title: const Text(
          'Asignar Clientes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFb51837),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF301939), Color(0xFF661c3a)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'client')
                  .where('assignedCoach', isEqualTo: null)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar clientes: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No hay clientes disponibles para asignar',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final client = snapshot.data!.docs[index];
                return Card(
                  color: const Color(0xFF4a1e5a),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFb51837),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      client['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Text(
                      client['email'] ?? 'Sin email',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      onPressed: () => _assignClient(context, client.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _assignClient(BuildContext context, String clientId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      // Debug: Verificar UID y rol del usuario actual
      print("UID usuario actual: ${user.uid}");

      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      print("Datos del usuario actual: ${currentUserDoc.data()}");

      if (currentUserDoc['role'] != 'coach' &&
          currentUserDoc['isAdmin'] != true) {
        throw Exception("No tienes permisos (debes ser coach o admin)");
      }

      // Debug: Verificar datos del cliente antes de actualizar
      final clientBefore =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(clientId)
              .get();

      print("Datos del cliente ANTES: ${clientBefore.data()}");

      // Operación de actualización
      await FirebaseFirestore.instance.collection('users').doc(clientId).update(
        {
          'assignedCoach': coachId,
          'lastUpdated': FieldValue.serverTimestamp(), // Campo adicional útil
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Asignación exitosa"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stacktrace) {
      print("Error completo: $e");
      print("Stack trace: $stacktrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}