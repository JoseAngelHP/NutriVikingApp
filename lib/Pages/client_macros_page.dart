import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutri_viking_app/Pages/meals_customization_page.dart';

class ClientMacrosPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String coachId;

  const ClientMacrosPage({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.coachId,
  }) : super(key: key);

  @override
  _ClientMacrosPageState createState() => _ClientMacrosPageState();
}

class _ClientMacrosPageState extends State<ClientMacrosPage> {
  late Future<Map<String, dynamic>> _userDataFuture;

  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _selectedGender;
  String? _selectedActivity;
  List<String> _customMeals = [
    'Desayuno',
    'Almuerzo',
    'Cena',
  ]; // Valores por defecto

  // Métodos para calcular las métricas
  double _calculateTMB(double peso, double altura, int edad, String genero) {
    return genero.toLowerCase() == 'hombre'
        ? 88.362 + (13.397 * peso) + (4.799 * altura) - (5.677 * edad)
        : 447.593 + (9.247 * peso) + (3.098 * altura) - (4.330 * edad);
  }

  double _calculateBMI(double peso, double altura) {
    final alturaMetros = altura / 100;
    return peso / (alturaMetros * alturaMetros);
  }

  double _calculateBodyFat(double imc, int edad, String genero) {
    final factorSexo = genero.toLowerCase() == 'hombre' ? 1 : 0;
    return (1.20 * imc) + (0.23 * edad) - (10.8 * factorSexo) - 5.4;
  }

  double _calculateWater(double peso) => 35 * peso;

  Future<void> _updateMetrics() async {
    try {
      final peso = double.tryParse(_weightController.text) ?? 0;
      final altura = double.tryParse(_heightController.text) ?? 0;
      final edad = int.tryParse(_ageController.text) ?? 0;
      final genero = _selectedGender ?? 'Hombre';

      if (peso > 0 && altura > 0 && edad > 0) {
        final imc = _calculateBMI(peso, altura);
        final metrics = {
          'basalMetabolism': _calculateTMB(peso, altura, edad, genero),
          'bmi': imc,
          'bodyFatPercentage': _calculateBodyFat(imc, edad, genero),
          'waterIntake': _calculateWater(peso),
          // Mantener el objetivo existente sin sobrescribirlo
          if (_goalController.text.isNotEmpty) 'goal': _goalController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .update(metrics);

        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Métricas actualizadas!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese peso, altura y edad válidos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al calcular métricas: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadClientData().then((data) {
      _selectedGender = data['gender'] ?? 'Hombre';
      _selectedActivity = data['activityLevel'] ?? 'Moderado';
      _ageController.text = data['age']?.toString() ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      _heightController.text = data['height']?.toString() ?? '';
      _goalController.text = data['goal'] ?? '';
      _customMeals = List<String>.from(
        data['customMeals'] ?? ['Desayuno', 'Almuerzo', 'Cena'],
      );
      // Calcular métricas si hay datos suficientes
      if ((data['weight'] ?? 0) > 0 &&
          (data['height'] ?? 0) > 0 &&
          (data['age'] ?? 0) > 0) {
        _updateMetrics();
      }
      return data;
    });
  }

  Future<Map<String, dynamic>> _loadClientData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .get();

      if (!doc.exists) throw Exception('El cliente no existe');

      return doc.data()!;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      return {};
    }
  }

  Future<void> _updateFields() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .update({
            if (_goalController.text.isNotEmpty) 'goal': _goalController.text,
            if (_selectedGender != null) 'gender': _selectedGender,
            if (_selectedActivity != null) 'activityLevel': _selectedActivity,
            if (_ageController.text.isNotEmpty)
              'age': int.tryParse(_ageController.text),
            if (_weightController.text.isNotEmpty)
              'weight': double.tryParse(_weightController.text),
            if (_heightController.text.isNotEmpty)
              'height': double.tryParse(_heightController.text),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos actualizados!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonHideUnderline(
      // Esto quita la línea inferior y el ícono
      child: DropdownButton<String>(
        value: _selectedGender,
        items:
            ['Hombre', 'Mujer'].map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(
                  gender,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() => _selectedGender = value);
          _updateFields();
        },
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black,
        ),
        icon: SizedBox.shrink(), // Esto elimina el ícono del triángulo
        isExpanded: false,
      ),
    );
  }

  Widget _buildActivityDropdown() {
    return DropdownButtonHideUnderline(
      // Esto quita la línea inferior y el ícono
      child: DropdownButton<String>(
        value: _selectedActivity,
        items:
            ['Bajo', 'Moderado', 'Alto', 'Muy alto', 'Hiperactivo'].map((
              activity,
            ) {
              return DropdownMenuItem(
                value: activity,
                child: Text(
                  activity,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() => _selectedActivity = value);
          _updateFields();
        },
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black,
        ),
        icon: SizedBox.shrink(), // Esto elimina el ícono del triángulo
        isExpanded: false,
      ),
    );
  }

  Widget _buildAgeField() {
    return SizedBox(
      width: 25,
      child: TextFormField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _updateFields(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.clientName),
        backgroundColor: const Color(0xFFb51837),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFFb51837)),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Error al cargar datos',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final userData = snapshot.data!;
          _goalController.text = userData['goal'] ?? '';
          return _buildContent(userData);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> userData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionTitle('Perfil'),
          _buildProfileItem(
            'Altura (cm)',
            userData['height']?.toInt().toString() ??
                'N/A', // Convertir a entero
          ),
          _buildProfileItem(
            'Peso (kg)',
            userData['weight']?.toInt().toString() ??
                'N/A', // Convertir a entero
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sexo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildGenderDropdown(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildAgeField(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actividad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildActivityDropdown(),
              ],
            ),
          ),
          _buildEditableGoalField(),
          _buildMealsCustomizationButton(),

          _buildSectionTitle('Resultados'),
          _buildResultItem(
            Icons.local_fire_department,
            'Metabolismo Basal',
            '${userData['basalMetabolism']?.toStringAsFixed(0) ?? 'N/A'} kcal',
            Color(0xFFFF5A4A),
          ),
          _buildResultItem(
            Icons.calculate,
            'Índice Masa Corporal',
            userData['bmi']?.toStringAsFixed(2) ?? 'N/A',
            Color(0xFF4CAF50),
          ),
          _buildResultItem(
            Icons.invert_colors,
            'Grasa Corporal (%)',
            userData['bodyFatPercentage']?.toStringAsFixed(1) ?? 'N/A',
            Color(0xFF9C27B0),
          ),
          _buildResultItem(
            Icons.water_drop,
            'Requerimiento de Agua (ml)',
            userData['waterIntake']?.toStringAsFixed(0) ?? 'N/A',
            Color(0xFF2196F3),
          ),
          ElevatedButton(
            onPressed: _updateMetrics,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 143, 231, 162),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('CALCULAR MÉTRICAS', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  // Añade este método:
  Widget _buildMealsCustomizationButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<List<String>>(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      MealsCustomizationPage(currentMeals: _customMeals),
            ),
          );

          if (result != null) {
            setState(() => _customMeals = result);
            // Aquí puedes guardar en Firestore si lo necesitas
            await _saveCustomMealsToFirestore(result);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Personalizar las comidas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomMealsToFirestore(List<String> meals) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .update({
            'customMeals': meals,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar comidas: $e')));
    }
  }

  Widget _buildEditableGoalField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Objetivo', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            width: 165,
            child: TextFormField(
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              controller: _goalController,
              decoration: InputDecoration(
                hintText: 'Escribe el objetivo',
                border: InputBorder.none,
              ),
              onFieldSubmitted: (value) => _updateFields(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF7F7F7),
      width: double.infinity,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildProfileItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
