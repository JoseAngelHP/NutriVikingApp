import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModernMacrosPage extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ModernMacrosPage({
    Key? key,
    required this.clientId,
    required this.clientName,
    required String coachId,
  }) : super(key: key);

  @override
  _ModernMacrosPageState createState() => _ModernMacrosPageState();
}

class _ModernMacrosPageState extends State<ModernMacrosPage> {
  late Future<Map<String, dynamic>> _userDataFuture;
  String _currentDietType = 'Personalizada';
  int _carbsPercentage = 50;
  int _proteinPercentage = 20;
  int _fatsPercentage = 30;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadClientData();
  }

  Future<Map<String, dynamic>> _loadClientData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .get();

      if (!doc.exists) throw Exception('El cliente no existe');
      
      // Cargar porcentajes guardados si existen
      final data = doc.data()!;
      if (data['macroPercentages'] != null) {
        _carbsPercentage = data['macroPercentages']['carbs'] ?? _carbsPercentage;
        _proteinPercentage = data['macroPercentages']['protein'] ?? _proteinPercentage;
        _fatsPercentage = data['macroPercentages']['fats'] ?? _fatsPercentage;
        _currentDietType = data['dietType'] ?? _currentDietType;
      }
      
      return data;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
      return {};
    }
  }

  Future<void> _updateCalories(double newCalories) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .update({
            'dailyCalories': newCalories,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _userDataFuture = _userDataFuture.then((data) {
          data['dailyCalories'] = newCalories;
          return data;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calorías actualizadas!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  Future<void> _saveMacroPercentages() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .update({
            'macroPercentages': {
              'carbs': _carbsPercentage,
              'protein': _proteinPercentage,
              'fats': _fatsPercentage,
            },
            'dietType': _currentDietType,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Distribución de macros guardada!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Map<String, dynamic> _calculateMacros(Map<String, dynamic> userData) {
    // Si ya existen gramos específicos en Firestore
    if (userData['proteinIntake'] != null &&
        userData['carbsIntake'] != null &&
        userData['fatsIntake'] != null) {
      final protein = (userData['proteinIntake'] as num).toDouble();
      final carbs = (userData['carbsIntake'] as num).toDouble();
      final fats = (userData['fatsIntake'] as num).toDouble();

      return {
        'protein': protein.roundToDouble(),
        'carbs': carbs.roundToDouble(),
        'fats': fats.roundToDouble(),
        'proteinKcal': (protein * 4).roundToDouble(),
        'carbsKcal': (carbs * 4).roundToDouble(),
        'fatsKcal': (fats * 9).roundToDouble(),
        'carbsPercentage': _carbsPercentage,
        'proteinPercentage': _proteinPercentage,
        'fatsPercentage': _fatsPercentage,
      };
    }

    final totalKcal = userData['dailyCalories']?.toDouble() ?? 0;
    
    // Usar los porcentajes actuales
    final carbsKcal = totalKcal * (_carbsPercentage / 100);
    final proteinKcal = totalKcal * (_proteinPercentage / 100);
    final fatsKcal = totalKcal * (_fatsPercentage / 100);

    final carbsG = (carbsKcal / 4).round();
    final proteinG = (proteinKcal / 4).round();
    final fatsG = (fatsKcal / 9).round();

    return {
      'carbs': carbsG,
      'protein': proteinG,
      'fats': fatsG,
      'carbsKcal': carbsG * 4,
      'proteinKcal': proteinG * 4,
      'fatsKcal': fatsG * 9,
      'carbsPercentage': _carbsPercentage,
      'proteinPercentage': _proteinPercentage,
      'fatsPercentage': _fatsPercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error al cargar datos'));
          }

          final userData = snapshot.data!;
          final macros = _calculateMacros(userData);

          return Column(
            children: [
              _buildTopBar(),
              _buildTitleBar(),
              _buildNavBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCalorieBox(userData['dailyCalories']?.toDouble() ?? 0),
                      _buildMacroSection(macros),
                      _buildDietTypeSection(),
                      _buildEditMacrosSection(),
                      _buildOtherGoalsSection(),
                      _buildMealDistributionSection(),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalorieBox(double calories) {
    return InkWell(
      onTap: () => _showCalorieEditDialog(calories),
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFfff9e6),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8),
            Text(
              '${calories.toStringAsFixed(0)} kcal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _showCalorieEditDialog(double currentCalories) async {
    final calorieController = TextEditingController(
      text: currentCalories.toStringAsFixed(0),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar calorías diarias'),
          content: TextField(
            controller: calorieController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Calorías (kcal)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 143, 231, 162),
              ),
              onPressed: () async {
                final newCalories = double.tryParse(calorieController.text);
                if (newCalories != null && newCalories > 0) {
                  await _updateCalories(newCalories);
                  Navigator.pop(context);
                }
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFFb51837),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      color: const Color(0xFFb51837),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Stack(alignment: Alignment.center),
    );
  }

  Widget _buildNavBar() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Distribución', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(
                widget.clientName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSection(Map<String, dynamic> macros) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Distribución de Macronutrientes',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMacroItem(
              'Carbohidratos',
              '${macros['carbs'].toStringAsFixed(0)} g',
              '${macros['carbsKcal'].toStringAsFixed(0)} kcal',
              Color(0xffd17a0f),
            ),
            _buildMacroItem(
              'Proteínas',
              '${macros['protein'].toStringAsFixed(0)} g',
              '${macros['proteinKcal'].toStringAsFixed(0)} kcal',
              Color(0xff00a0b7),
            ),
            _buildMacroItem(
              'Grasas',
              '${macros['fats'].toStringAsFixed(0)} g',
              '${macros['fatsKcal'].toStringAsFixed(0)} kcal',
              Color(0xff301990),
            ),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: const Color(0xffd17a0f),
                  value: macros['carbsPercentage']?.toDouble() ?? 50,
                  title: '${macros['carbsPercentage']?.toStringAsFixed(0) ?? 50}%',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  color: const Color(0xff00a0b7),
                  value: macros['proteinPercentage']?.toDouble() ?? 20,
                  title: '${macros['proteinPercentage']?.toStringAsFixed(0) ?? 20}%',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  color: const Color(0xff301990),
                  value: macros['fatsPercentage']?.toDouble() ?? 30,
                  title: '${macros['fatsPercentage']?.toStringAsFixed(0) ?? 30}%',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 10,
            ),
          ),
        ),
        SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMacroIndicator('Carbohidratos', Color(0xffd17a0f)),
            _buildMacroIndicator('Proteínas', Color(0xff00a0b7)),
            _buildMacroIndicator('Grasas', Color(0xff301990)),
          ],
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMacroIndicator(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String title, String value, String kcal, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        SizedBox(height: 4),
        Text(kcal, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDietTypeSection() {
    return InkWell(
      onTap: () => _showDietSelectionDialog(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tipo de dieta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              _currentDietType,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDietSelectionDialog() async {
    final dietOptions = [
      {'name': 'Estándar', 'carbs': 50, 'protein': 20, 'fats': 30},
      {'name': 'Equilibrada', 'carbs': 50, 'protein': 25, 'fats': 25},
      {'name': 'Baja en grasas', 'carbs': 60, 'protein': 25, 'fats': 15},
      {'name': 'Alta en proteínas', 'carbs': 25, 'protein': 40, 'fats': 35},
      {'name': 'Cetogénica', 'carbs': 5, 'protein': 30, 'fats': 65},
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Seleccionar tipo de dieta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...dietOptions.map((diet) => ListTile(
                    title: Text(diet['name'] as String),
                    subtitle: Text(
                        'Carb: ${diet['carbs']}% Prot: ${diet['protein']}% Grasas: ${diet['fats']}%'),
                    onTap: () {
                      setState(() {
                        _currentDietType = diet['name'] as String;
                        _carbsPercentage = diet['carbs'] as int;
                        _proteinPercentage = diet['protein'] as int;
                        _fatsPercentage = diet['fats'] as int;
                      });
                      _saveMacroPercentages();
                      Navigator.pop(context);
                    },
                  )),
              Divider(),
              ListTile(
                title: Text('Personalizada'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomDietDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomDietDialog() async {
    final carbsController = TextEditingController(text: _carbsPercentage.toString());
    final proteinController = TextEditingController(text: _proteinPercentage.toString());
    final fatsController = TextEditingController(text: _fatsPercentage.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dieta personalizada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: carbsController,
                decoration: InputDecoration(labelText: 'Carbohidratos (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: proteinController,
                decoration: InputDecoration(labelText: 'Proteínas (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatsController,
                decoration: InputDecoration(labelText: 'Grasas (%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final carbs = int.tryParse(carbsController.text) ?? 0;
                final protein = int.tryParse(proteinController.text) ?? 0;
                final fats = int.tryParse(fatsController.text) ?? 0;

                if (carbs + protein + fats == 100) {
                  setState(() {
                    _currentDietType = 'Personalizada';
                    _carbsPercentage = carbs;
                    _proteinPercentage = protein;
                    _fatsPercentage = fats;
                  });
                  _saveMacroPercentages();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('La suma debe ser 100%')),
                  );
                }
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditMacrosSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Editar distribución de macronutrientes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildOtherGoalsSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Otros objetivos nutricionales',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildMealDistributionSection() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 24),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFF9F9F9),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Distribución de comidas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /*Text(
                'Desayuno',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),*/
              /*RichText(
                text: TextSpan(
                  text: '375',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: ' kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),*/
            ],
          ),
        ),
      ],
    );
  }
}