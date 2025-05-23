import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClientHomeScreen extends StatelessWidget {
  final String userId;

  const ClientHomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF301939),
      appBar: AppBar(
        title: Text(
          'Mi Plan de Alimentación',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFb51837),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
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
            children: [
              _buildUserInfo(),
              SizedBox(height: 20),
              Expanded(child: _buildNutritionPlan()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(color: Colors.white);
        }

        final user = snapshot.data!.data() as Map<String, dynamic>;

        return Card(
          color: Color(0xFF4a1e5a),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text(
                    user['name'],
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                Divider(color: Colors.white54),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      'Peso',
                      '${user['weight'].toStringAsFixed(0)} kg',
                    ),
                    _buildInfoItem(
                      'Altura',
                      '${user['height'].toStringAsFixed(0)} cm',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionPlan() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('nutrition')
              .doc(today)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Tu coach aún no ha asignado tu plan de alimentación para hoy.\n\nRevisa más tarde o contacta a tu coach.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final meals = data['meals'] as List<dynamic>;

        return ListView.separated(
          itemCount: meals.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final meal = meals[index] as Map<String, dynamic>;
            final items = meal['items'] as List<dynamic>;

            return _buildMealSection(meal['name'], items);
          },
        );
      },
    );
  }

  Widget _buildMealSection(String mealName, List<dynamic> foodItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            mealName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          color: Color(0xFF4a1e5a),
          child: Padding(
            padding: EdgeInsets.all(12),
            child:
                foodItems.isEmpty
                    ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No hay alimentos asignados para esta comida',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                    : Column(
                      children:
                          foodItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final food = entry.value as Map<String, dynamic>;
                            return _buildFoodItem(
                              food,
                              isLast: index == foodItems.length - 1,
                            );
                          }).toList(),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  food['name'] ?? 'Alimento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${food['quantity'] ?? '1'} porción',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 6),
          if (!isLast)
            Divider(color: Colors.white54, height: 16),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
