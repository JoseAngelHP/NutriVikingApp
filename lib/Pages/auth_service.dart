import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------- REGISTRO --------------------
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // Añade este parámetro
    double? weight,
    double? height,
    //required String goal,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'assignedCoach': null, // Campo nuevo para asignación de coaches
          'weight': weight,
          'height': height,
          /*'goal': goal,*/
          'createdAt': Timestamp.now(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('General error: $e');
      return null;
    }
  }

  // -------------------- ACTUALIZAR OBJETIVO (COACH) --------------------
  Future<void> updateClientGoal({
    required String clientUid,
    required String goal, // 'fat_loss', 'muscle_gain', etc.
  }) async {
    try {
      await _firestore.collection('users').doc(clientUid).update({
        'goal': goal,
        'updatedAt': Timestamp.now(), // Opcional: registrar cuándo se actualizó
      });
    } catch (e) {
      print('Error updating goal: $e');
      rethrow; // Opcional: maneja el error en la UI
    }
  }

  // -------------------- INICIO DE SESIÓN --------------------
  Future<User?> signIn(String email, String password) async {
    try {
      // Inicia sesión sin verificar el correo
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtén el usuario
      User? user = userCredential.user;

      // Aquí no chequeamos si el correo está verificado
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase: ${e.code} - ${e.message}');
      return null;
    } catch (e, stack) {
      print('Error inesperado: $e\nStack: $stack');
      return null;
    }
  }

  // -------------------- CERRAR SESIÓN --------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // -------------------- DATOS DEL USUARIO --------------------
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) throw Exception('Usuario no encontrado');

      final data = doc.data();
      if (data is! Map<String, dynamic>) {
        throw Exception('Formato de datos inválido');
      }

      return data;
    } catch (e) {
      print('Error en getUserData: $e');
      rethrow;
    }
  }

  // -------------------- LISTA DE COACHES --------------------
  Future<List<Map<String, dynamic>>> getAvailableCoaches() async {
    final query =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'coach')
            .get();

    return query.docs.map((doc) {
      return {'id': doc.id, 'name': doc['name'], 'email': doc['email']};
    }).toList();
  }

  // -------------------- ACTUALIZAR PERFIL --------------------
  Future<void> updateUserProfile({
    required String userId,
    double? weight,
    double? height,
    String? goal,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (goal != null) 'goal': goal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
