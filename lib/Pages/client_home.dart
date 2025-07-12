import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientHomeScreen extends StatefulWidget {
  final String userId;

  const ClientHomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  List<String> _savedMenus = [];
  String? _selectedMenu;
  DateTime _selectedWorkoutDate = DateTime.now(); // Añade esta variable de estado
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Número de pestañas (Alimentación + Ejercicios)
      child: Scaffold(
        backgroundColor: Color(0xFF301939),
        appBar: AppBar(
          title: Text(
            'Mi Plan de Alimentación',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFFFE7900),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.black),
              onPressed: () => _logout(context),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.black,
            labelColor:
                Colors.black, // Color del texto de la pestaña seleccionada
            unselectedLabelColor:
                Colors.black87, // Color del texto de pestañas no seleccionadas
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                icon: Icon(Icons.fastfood, color: Colors.black),
                text: 'Alimentación',
              ),
              Tab(
                icon: Icon(Icons.fitness_center, color: Colors.black),
                text: 'Ejercicios',
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFE5E4E4)],
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
                Expanded(
                  child: TabBarView(
                    children: [
                      // Pestaña 1: Plan de Alimentación
                      _buildNutritionPlan(),
                      // Pestaña 2: Plan de Ejercicios
                      _buildWorkoutPlan(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutPlan() {
    return Column(
      children: [
        // Selector de fecha (AÑADIDO)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedWorkoutDate = _selectedWorkoutDate.subtract(Duration(days: 1));
                  });
                },
              ),
              TextButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedWorkoutDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedWorkoutDate = picked);
                  }
                },
                child: Text(
                  DateFormat('EEEE, d MMMM').format(_selectedWorkoutDate),
                  style: TextStyle(color: Colors.black),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedWorkoutDate = _selectedWorkoutDate.add(Duration(days: 1));
                  });
                },
              ),
            ],
          ),
        ),
        
        // StreamBuilder modificado para usar _selectedWorkoutDate
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('workouts')
              .doc(DateFormat('yyyy-MM-dd').format(_selectedWorkoutDate))
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'No hay ejercicios asignados para este día.\n\nRevisa otra fecha o contacta a tu coach.',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final exercises = (data['exercises'] as List<dynamic>?) ?? [];

            return ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final exercise = exercises[index] as Map<String, dynamic>;
                return _buildExerciseSection(exercise);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildExerciseSection(Map<String, dynamic> exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Color(0xFFedbb99),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección para el PDF con manejo seguro del contexto
                if (exercise['pdfUrl'] != null &&
                    exercise['pdfUrl'].toString().isNotEmpty)
                  Builder(
                    builder:
                        (context) => Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: InkWell(
                            onTap: () async {
                              final url = exercise['pdfUrl'];
                              try {
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No se pudo abrir el PDF',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Ver PDF',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(color: Colors.white);
        }

        final user = snapshot.data!.data() as Map<String, dynamic>;

        return Card(
          color: Color(0xFFedbb99),
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

  /*Widget _buildNutritionPlan() {
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
  }*/

  Widget _buildNutritionPlan() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      children: [
        // Selector de menús
        PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFf9f9f9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu, color: Colors.black, size: 20),
                SizedBox(width: 8),
                Text('Menús', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
          onSelected: (menuName) {
            setState(() {
              _selectedMenu = menuName;
            });
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem(value: null, child: Text('Plan del día')),
              PopupMenuDivider(),
              ..._savedMenus
                  .map((menu) => PopupMenuItem(value: menu, child: Text(menu)))
                  .toList(),
            ];
          },
        ),
        SizedBox(height: 10),
        // Contenido del plan de nutrición
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream:
                _selectedMenu == null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('nutrition')
                        .doc(today)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('saved_menus')
                        .doc(_selectedMenu)
                        .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    _selectedMenu == null
                        ? 'Tu coach aún no ha asignado tu plan de alimentación para hoy.\n\nRevisa más tarde o contacta a tu coach.'
                        : 'El menú seleccionado no contiene información.',
                    style: TextStyle(color: Colors.black, fontSize: 16),
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
          ),
        ),
      ],
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
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          color: Color(0xFFedbb99),
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
    final List<String>? suggestions =
        food['suggestions'] != null
            ? List<String>.from(food['suggestions'])
            : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal del alimento
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
                [
                  if (food['brand'] != null && food['brand'].isNotEmpty)
                    food['brand'],
                  '${food['quantity'] ?? '1'} porción',
                ].join(', '),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),

          // Sección de sugerencias
          if (suggestions != null && suggestions.isNotEmpty) ...[
            SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sugerencias:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      suggestions
                          .map(
                            (suggestion) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFFE7900).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFFFE7900).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ],

          // Separador
          SizedBox(height: 6),
          if (!isLast) Divider(color: Colors.white54, height: 16),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSavedMenus();
  }

  Future<void> _loadSavedMenus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

    if (doc.exists) {
      setState(() {
        _savedMenus = List<String>.from(doc.data()?['savedMenus'] ?? []);
      });
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
