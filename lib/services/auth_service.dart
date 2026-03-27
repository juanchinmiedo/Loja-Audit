// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  // Una sola instancia de GoogleSignIn reutilizada en toda la clase.
  // Sin scopes extra — solo necesitamos identidad para Firebase Auth.
  final _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Limpiar cualquier sesión de Google cacheada (mismo proyecto Firebase,
      //    misma cuenta usada por la app loja → evita que signIn() devuelva null
      //    silenciosamente al reutilizar un token caducado o de otra app).
      await _googleSignIn.signOut();

      // 2. Mostrar el selector de cuenta siempre.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario cerró el selector — no es un error, simplemente canceló.
        debugPrint('⚠️  signInWithGoogle: usuario canceló el selector');
        return null;
      }

      // 3. Obtener tokens OAuth.
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        debugPrint(
          '❌ signInWithGoogle: idToken null. '
          'Verifica que el proveedor Google está habilitado en Firebase Console '
          'y que el SHA-1 de este app está registrado.',
        );
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken:     googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // 4. Autenticar en Firebase.
      final result = await _auth.signInWithCredential(credential);
      final user   = result.user;
      if (user == null) {
        debugPrint('❌ signInWithGoogle: Firebase user null tras signInWithCredential');
        return null;
      }
      debugPrint('✅ Firebase signed in: ${user.uid} / ${user.email}');

      // 5. Forzar refresco del token para que los Custom Claims estén frescos.
      //    (Crítico: los claims que puso setClaims.js no llegan hasta el
      //    próximo getIdToken(true) o authStateChanges posterior al login.)
      await user.getIdToken(true);
      debugPrint('✅ Token refrescado — claims actualizados');

      // 6. Verificar que el usuario existe en la colección users de Firestore.
      //    Solo los usuarios creados por la app loja (o el script) tienen doc aquí.
      final snap = await _db.collection('users').doc(user.uid).get();
      debugPrint('ℹ️  users/${user.uid} exists: ${snap.exists}');

      if (!snap.exists) {
        debugPrint('❌ UID no encontrado en /users — acceso denegado');
        await _signOutBoth();
        return null;
      }

      // 7. Verificar Custom Claims: el usuario debe tener rol "admin".
      //    La app de auditoría es de solo-lectura para admins/owners.
      final idTokenResult = await user.getIdTokenResult();
      final roles = idTokenResult.claims?['roles'];
      debugPrint('ℹ️  Claims roles: $roles');

      final isAdmin = roles is List
          ? roles.contains('admin')
          : roles.toString().contains('admin');

      if (!isAdmin) {
        debugPrint('❌ El usuario no tiene rol "admin" en claims — acceso denegado');
        await _signOutBoth();
        return null;
      }

      debugPrint('✅ Acceso concedido: ${user.email} con roles=$roles');
      return user;

    } on FirebaseAuthException catch (e) {
      // Errores concretos: network-request-failed, invalid-credential, etc.
      debugPrint('❌ FirebaseAuthException: code=${e.code}  msg=${e.message}');
      rethrow; // login_screen.dart lo captura y muestra el mensaje de error
    } catch (e, st) {
      debugPrint('❌ Error inesperado en signInWithGoogle: $e\n$st');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _signOutBoth();
  }

  Future<void> _signOutBoth() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('⚠️  Error en _auth.signOut(): $e');
    }
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️  Error en _googleSignIn.signOut(): $e');
    }
  }
}
