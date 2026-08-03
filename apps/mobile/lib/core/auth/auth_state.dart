import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../notifications/local_notification_service.dart';
import 'auth_repository.dart';
export 'auth_repository.dart' show RegisterResult;
import 'current_user.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._repository, AppLinks appLinks) {
    if (_repository.isConfigured) {
      _authSubscription = supabase
          .Supabase.instance.client.auth.onAuthStateChange
          .listen(_handleAuthChange);
      _deepLinkSubscription = appLinks.uriLinkStream.listen(
        _handleOAuthCallback,
        onError: _handleDeepLinkError,
      );
    }
  }

  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;

  CurrentUser? currentUser;
  bool isLoading = true;
  bool passwordRecoveryRequired = false;
  String? errorMessage;

  bool get isAuthenticated => currentUser != null;
  bool get isConfigured => _repository.isConfigured;
  bool get useMockData => _repository.useMockData;

  Future<void> _handleOAuthCallback(Uri uri) async {
    final isAuthLink = uri.scheme == 'lappo' &&
        uri.host == 'auth' &&
        (uri.path == '/callback' || uri.path == '/reset-password');
    if (!isAuthLink) return;

    final isPasswordRecovery = uri.path == '/reset-password';

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await supabase.Supabase.instance.client.auth.getSessionFromUrl(uri);
      passwordRecoveryRequired = isPasswordRecovery;
      if (!isPasswordRecovery) {
        currentUser = await _repository.getCurrentUser();
        if (currentUser == null) {
          throw StateError('Профіль користувача не знайдено.');
        }
      }
    } on supabase.AuthException catch (error) {
      errorMessage = error.message.toLowerCase().contains('expired')
          ? 'Посилання недійсне або вже протерміноване. Запросіть нове.'
          : 'Не вдалося завершити безпечний вхід. Спробуйте ще раз.';
    } catch (_) {
      errorMessage = 'Не вдалося завершити безпечний вхід. Спробуйте ще раз.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _handleDeepLinkError(Object _) {
    errorMessage = 'Не вдалося відкрити безпечне посилання. Спробуйте ще раз.';
    isLoading = false;
    notifyListeners();
  }

  Future<void> _handleAuthChange(supabase.AuthState state) async {
    if (state.event == supabase.AuthChangeEvent.signedOut) {
      await LocalNotificationService.instance.resetForAccountChange();
      currentUser = null;
      passwordRecoveryRequired = false;
      errorMessage = null;
      notifyListeners();
      return;
    }

    if (state.session == null) return;

    if (state.event == supabase.AuthChangeEvent.passwordRecovery) {
      passwordRecoveryRequired = true;
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return;
    }

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
        errorMessage =
            'Не вдалося створити акаунт. Перевірте дані та спробуйте ще раз.';
      }
    } catch (_) {
      errorMessage =
          'Не вдалося створити акаунт. Перевірте дані та спробуйте ще раз.';
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
    await LocalNotificationService.instance.resetForAccountChange();
    await _repository.logout();
    currentUser = null;
    passwordRecoveryRequired = false;
    notifyListeners();
  }

  Future<bool> updatePassword(String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.updatePassword(password);
      passwordRecoveryRequired = false;
      currentUser = await _repository.getCurrentUser();
      return true;
    } on supabase.AuthException {
      errorMessage =
          'Не вдалося змінити пароль. Запросіть нове посилання та спробуйте ще раз.';
      return false;
    } catch (_) {
      errorMessage = 'Не вдалося змінити пароль. Спробуйте ще раз.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String city,
    String? phone,
    String? email,
  }) async {
    currentUser = await _repository.updateProfile(
      fullName: fullName,
      city: city,
      phone: phone,
      email: email,
    );
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    currentUser = await _repository.completeOnboarding();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
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
