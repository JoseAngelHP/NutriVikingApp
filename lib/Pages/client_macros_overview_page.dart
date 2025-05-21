import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutri_viking_app/Pages/client_macros_page.dart';

class ClientMacrosOverviewPage extends StatelessWidget {
  final String coachId;

  const ClientMacrosOverviewPage({Key? key, required this.coachId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF301939),
      appBar: AppBar(
        title: Text('Macros de Clientes', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFb51837),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF301939), Color(0xFF661c3a)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('assignedCoach', isEqualTo: coachId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No tienes clientes asignados', style: TextStyle(color: Colors.white)));
            }

            final clients = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                final clientData = client.data() as Map<String, dynamic>;
                
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
                      clientData['name'] ?? 'Cliente',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calorías: ${clientData['dailyCalories'] ?? 'N/A'} kcal',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text('P: ${clientData['proteinIntake'] ?? '0'}g', style: TextStyle(fontSize: 12)),
                              backgroundColor: Color(0xFFb51837).withOpacity(0.3),
                            ),
                            SizedBox(width: 4),
                            Chip(
                              label: Text('C: ${clientData['carbsIntake'] ?? '0'}g', style: TextStyle(fontSize: 12)),
                              backgroundColor: Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                            SizedBox(width: 4),
                            Chip(
                              label: Text('G: ${clientData['fatsIntake'] ?? '0'}g', style: TextStyle(fontSize: 12)),
                              backgroundColor: Color(0xFF9C27B0).withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward, color: Colors.white),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientMacrosPage(
                            clientId: client.id,
                            clientName: clientData['name'] ?? 'Cliente', coachId: '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}