import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthService() {
    // Inicializar usuario actual inmediatamente
    _user = _auth.currentUser;
    
    // Escuchar cambios en el estado de autenticación (solo si es necesario)
    if (_user == null) {
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    }
  }

  /// Login con email y contraseña
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Usar signInWithCredential para evitar reCAPTCHA
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);

      _user = result.user;
      _setLoading(false);
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return null;
    } catch (e) {
      _setError('Error inesperado: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Registro con email y contraseña
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Actualizar el display name si se proporciona
      if (displayName != null && displayName.isNotEmpty) {
        await result.user?.updateDisplayName(displayName.trim());
        await result.user?.reload();
        _user = _auth.currentUser;
      }

      _setLoading(false); // Asegurar que se desactive el loading
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return null;
    } catch (e) {
      _setError('Error inesperado: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Login con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el login
        _setLoading(false);
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      
      _user = result.user;
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return null;
    } catch (e) {
      _setError('Error con Google Sign-In: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Enviar email de verificación
  Future<void> sendEmailVerification() async {
    try {
      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
      }
    } catch (e) {
      _setError('Error al enviar email de verificación: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
    } catch (e) {
      _setError('Error al enviar email de recuperación: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar perfil del usuario
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (_user == null) return;

      _setLoading(true);
      _clearError();

      await _user!.updateDisplayName(displayName);
      if (photoURL != null) {
        await _user!.updatePhotoURL(photoURL);
      }
      
      await _user!.reload();
      _user = _auth.currentUser;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
    } catch (e) {
      _setError('Error al actualizar perfil: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Obtener mensaje de error en español
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'El email no es válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: $errorCode';
    }
  }
}

