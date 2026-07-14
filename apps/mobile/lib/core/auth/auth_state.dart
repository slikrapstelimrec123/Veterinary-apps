import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_repository.dart';
export 'auth_repository.dart' show RegisterResult;
import 'current_user.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._repository) {
    if (_repository.isConfigured) {
      _authSubscription = supabase
          .Supabase.instance.client.auth.onAuthStateChange
          .listen(_handleAuthChange);
    }
  }

  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  CurrentUser? currentUser;
  bool isLoading = true;
  String? errorMessage;

  bool get isAuthenticated => currentUser != null;
  bool get isConfigured => _repository.isConfigured;
  bool get useMockData => _repository.useMockData;

  Future<void> _handleAuthChange(supabase.AuthState state) async {
    if (state.event == supabase.AuthChangeEvent.signedOut) {
      currentUser = null;
      errorMessage = null;
      notifyListeners();
      return;
    }

    if (state.session == null) return;

    try {
      currentUser = await _repository.getCurrentUser();
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Не вдалося завершити вхід. Спробуйте ще раз.';
    }
    notifyListeners();
  }

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();

    try {
      currentUser = await _repository.getCurrentUser();
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Не вдалося відновити сесію.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _repository.login(email: email, password: password);
    } catch (_) {
      errorMessage = 'Електронна пошта або пароль неправильні.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool registrationPendingConfirmation = false;

  Future<void> registerPetOwner({
    required String email,
    required String password,
    required String fullName,
    required String city,
    String? phone,
  }) async {
    isLoading = true;
    errorMessage = null;
    registrationPendingConfirmation = false;
    notifyListeners();

    try {
      final result = await _repository.registerPetOwner(
        email: email,
        password: password,
        fullName: fullName,
        city: city,
        phone: phone,
      );
      switch (result) {
        case RegisterResult.success:
          currentUser = await _repository.getCurrentUser();
        case RegisterResult.confirmationRequired:
          registrationPendingConfirmation = true;
        case RegisterResult.failed:
          errorMessage =
              'Не вдалося створити акаунт. Перевірте поля й спробуйте ще раз.';
      }
    } on supabase.AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists') ||
          e.statusCode == '422') {
        errorMessage =
            'Ця електронна пошта вже зареєстрована. Спробуйте увійти.';
      } else {
        errorMessage = 'Помилка: ${e.message}';
      }
    } catch (e) {
      errorMessage = 'Помилка: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    errorMessage = null;
    notifyListeners();
    try {
      final launched = await _repository.signInWithGoogle();
      if (!launched) {
        errorMessage = 'Не вдалося відкрити вхід через Google.';
        notifyListeners();
      }
    } catch (_) {
      errorMessage = 'Не вдалося увійти через Google. Спробуйте ще раз.';
      notifyListeners();
    }
  }

  Future<void> signInWithApple() async {
    errorMessage = null;
    notifyListeners();
    try {
      final launched = await _repository.signInWithApple();
      if (!launched) {
        errorMessage = 'Не вдалося відкрити вхід через Apple.';
        notifyListeners();
      }
    } catch (_) {
      errorMessage = 'Не вдалося увійти через Apple. Спробуйте ще раз.';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({
    super.key,
    required AuthState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return scope!.notifier!;
  }
}
