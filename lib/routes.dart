import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/auth/master_password_setup_screen.dart';
import 'screens/auth/biometric_auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/password/password_form_screen.dart';
import 'screens/password/password_detail_screen.dart';
import 'screens/settings/auth_settings_screen.dart';
import 'screens/settings/biometric_settings_screen.dart';
import 'models/password_entry.dart';
import 'models/auth_type.dart';

// 경로 상수
const String homeRoute = '/home';
const String authRoute = '/auth';
const String passwordAddAuthRoute = '/password-add-auth';
const String passwordViewAuthRoute = '/password-view-auth';
const String masterPasswordSetupRoute = '/master-password-setup';
const String biometricSetupRoute = '/biometric-setup';
const String addPasswordRoute = '/add-password';
const String passwordDetailsRoute = '/password-details';
const String settingsRoute = '/settings';
const String biometricSettingsRoute = '/biometric-settings';

// 앱 라우트 정의
Map<String, WidgetBuilder> getAppRoutes() {
  return {
    authRoute: (context) => const AuthScreen(),
    passwordAddAuthRoute: (context) => const AuthScreen(
          authType: AuthScreenType.passwordAdd,
          nextRoute: addPasswordRoute,
        ),
    passwordViewAuthRoute: (context) {
      final PasswordEntry? password =
          ModalRoute.of(context)?.settings.arguments as PasswordEntry?;
      return AuthScreen(
        authType: AuthScreenType.passwordView,
        nextRoute: passwordDetailsRoute,
        onAuthSuccess: () {
          Navigator.pushReplacementNamed(
            context,
            passwordDetailsRoute,
            arguments: password,
          );
        },
      );
    },
    masterPasswordSetupRoute: (context) => const MasterPasswordSetupScreen(),
    biometricSetupRoute: (context) => const BiometricAuthScreen(),
    homeRoute: (context) => const HomeScreen(),
    addPasswordRoute: (context) => const PasswordFormScreen(),
    passwordDetailsRoute: (context) {
      final PasswordEntry entry =
          ModalRoute.of(context)?.settings.arguments as PasswordEntry;
      return PasswordDetailScreen(entry: entry);
    },
    settingsRoute: (context) => const AuthSettingsScreen(),
    biometricSettingsRoute: (context) => const BiometricSettingsScreen(),
  };
}
