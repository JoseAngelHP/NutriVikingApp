import 'package:flutter/material.dart';
import 'package:nutri_viking_app/Pages/auth_service.dart';
import 'package:nutri_viking_app/Pages/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SingUp extends StatefulWidget {
  const SingUp({Key? key}) : super(key: key);

  @override
  _SingUpState createState() => _SingUpState();
}

class _SingUpState extends State<SingUp> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _role = 'coach'; // 'client' o 'coach'

  // Controladores
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  //String _goal ='fat_loss'; // Objetivo asignado por el coach (valor por defecto)

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? user = await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _role,
        weight: _role == 'client' ? double.parse(_weightController.text) : null,
        height: _role == 'client' ? double.parse(_heightController.text) : null,
        //goal: _role == 'client' ? _goal : null, // Solo se envía si es cliente
      );

      if (user != null) {
        Navigator.pushReplacementNamed(
          context,
          _role == 'coach' ? '/coach_home' : '/client_home',
          arguments: user.uid,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        padding: EdgeInsets.only(top: 50.0),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffd17a0f), Color(0xff00a0b7), Color(0xff301939)],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Text(
                "Crear Una\nCuenta",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 40.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 50.0, left: 30.0, right: 30.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nombre",
                          style: TextStyle(
                            color: Color(0xffb51837),
                            fontSize: 23.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextFormField(
                          controller: _nameController,
                          validator:
                              (val) =>
                                  val!.isEmpty ? 'Ingrese su nombre' : null,
                          decoration: InputDecoration(
                            hintText: "Ingrese Nombre",
                            prefixIcon: Icon(
                              Icons.person,
                              color: Color(0xffb51837),
                            ),
                          ),
                        ),
                        SizedBox(height: 40.0),
                        Text(
                          "Email",
                          style: TextStyle(
                            color: Color(0xffb51837),
                            fontSize: 23.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextFormField(
                          controller: _emailController,
                          validator:
                              (val) =>
                                  val!.isEmpty ? 'Ingrese email válido' : null,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Ingrese Email",
                            prefixIcon: Icon(
                              Icons.email,
                              color: Color(0xffb51837),
                            ),
                          ),
                        ),
                        SizedBox(height: 40.0),
                        Text(
                          "Contraseña",
                          style: TextStyle(
                            color: Color(0xffb51837),
                            fontSize: 23.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextFormField(
                          controller: _passwordController,
                          validator:
                              (val) =>
                                  val!.length < 6
                                      ? 'Mínimo 6 caracteres'
                                      : null,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Ingrese Contraseña",
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Color(0xffb51837),
                            ),
                          ),
                        ),
                        SizedBox(height: 40.0),
                        Text(
                          "Tipo de Cuenta",
                          style: TextStyle(
                            color: Color(0xffb51837),
                            fontSize: 23.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _role,
                          items: [
                            DropdownMenuItem(
                              value: 'client',
                              child: Text('Cliente'),
                            ),
                            DropdownMenuItem(
                              value: 'coach',
                              child: Text('Coach'),
                            ),
                          ],
                          onChanged: (val) => setState(() => _role = val!),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.group,
                              color: Color(0xffb51837),
                            ),
                          ),
                        ),
                        // Nota: El objetivo (_goal) ahora lo asigna el coach después del registro
                        if (_role == 'client') ...[
                          SizedBox(height: 40.0),
                          Text(
                            "Peso (kg)",
                            style: TextStyle(
                              color: Color(0xffb51837),
                              fontSize: 23.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextFormField(
                            controller: _weightController,
                            validator:
                                (val) =>
                                    val!.isEmpty ? 'Ingrese su peso' : null,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Ej: 70.5",
                              prefixIcon: Icon(
                                Icons.line_weight,
                                color: Color(0xffb51837),
                              ),
                            ),
                          ),
                          SizedBox(height: 40.0),
                          Text(
                            "Altura (cm)",
                            style: TextStyle(
                              color: Color(0xffb51837),
                              fontSize: 23.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextFormField(
                            controller: _heightController,
                            validator:
                                (val) =>
                                    val!.isEmpty ? 'Ingrese su altura' : null,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Ej: 175",
                              prefixIcon: Icon(
                                Icons.height,
                                color: Color(0xffb51837),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 40.0),
                        GestureDetector(
                          onTap: _isLoading ? null : _handleSignUp,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xffb51837),
                                  Color(0xff661c3a),
                                  Color(0xff301939),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.topRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child:
                                  _isLoading
                                      ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        "Registrarse",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "¿Ya tienes una cuenta?",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SignIn(),
                                        ),
                                      ),
                                  child: Text(
                                    "Iniciar Sesión",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 4, 72, 129),
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
