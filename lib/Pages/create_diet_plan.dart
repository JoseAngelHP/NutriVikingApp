import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateDietPlanScreen extends StatefulWidget {
  final String coachId;
  final String clientId;

  const CreateDietPlanScreen({
    Key? key,
    required this.coachId,
    required this.clientId,
  }) : super(key: key);

  @override
  _CreateDietPlanScreenState createState() => _CreateDietPlanScreenState();
}

class _CreateDietPlanScreenState extends State<CreateDietPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _meals = [];

  void _addMeal() {
    setState(() {
      _meals.add({
        'food': '',
        'calories': 0,
        'protein': 0,
        'time': 'lunch',
      });
    });
  }

  Future<void> _savePlan() async {
    await FirebaseFirestore.instance.collection('diet_plans').add({
      'coachId': widget.coachId,
      'clientId': widget.clientId,
      'meals': _meals,
      'createdAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Plan de Dieta'),
        backgroundColor: const Color(0xffb51837),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _meals.length,
                  itemBuilder: (context, index) {
                    return _buildMealCard(index);
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _addMeal,
                child: const Text('Añadir Comida'),
              ),
              ElevatedButton(
                onPressed: _savePlan,
                child: const Text('Guardar Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Alimento'),
              onChanged: (value) => _meals[index]['food'] = value,
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calorías'),
              onChanged: (value) => _meals[index]['calories'] = int.tryParse(value) ?? 0,
            ),
            DropdownButtonFormField<String>(
              value: _meals[index]['time'],
              items: ['breakfast', 'lunch', 'dinner', 'snack'].map((time) {
                return DropdownMenuItem(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (value) => setState(() => _meals[index]['time'] = value!),
            ),
          ],
        ),
      ),
    );
  }
}