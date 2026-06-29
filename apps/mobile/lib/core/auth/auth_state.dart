import 'package:flutter/material.dart';

import 'auth_repository.dart';
import 'current_user.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._repository);

  final AuthRepository _repository;

  CurrentUser? currentUser;
  bool isLoading = true;
  String? errorMessage;

  bool get isAuthenticated => currentUser != null;
  bool get isConfigured => _repository.isConfigured;
  bool get useMockData => _repository.useMockData;

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();

    try {
      currentUser = await _repository.getCurrentUser();
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Unable to restore your session.';
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
      errorMessage = 'Email or password is incorrect.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerPetOwner({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _repository.registerPetOwner(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
    } catch (_) {
      errorMessage = 'Unable to create account. Please check the fields and try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    currentUser = null;
    notifyListeners();
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
