import 'package:evaporated_storage_example/login/domain/constants.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: SizedBox(
              height: 80,
              child: GoogleSignInButton(
                clientId: googleClientId,
                loadingIndicator: const CircularProgressIndicator(),
                onSignedIn: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
