import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isSignup = false;
  String? error;
  bool isSubmitting = false;

  Future<void> _submit() async {
    setState(() {
      error = null;
      isSubmitting = true;
    });

    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (!email.toLowerCase().endsWith('.edu')) {
      setState(() {
        error = 'Use your school\'s .edu email.';
        isSubmitting = false;
      });
      return;
    }

    try {
      if (isSignup) {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: pass);
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: pass);
      }
      // AuthProvider's listener will automatically pick up the auth state
      // change and sync with the backend. No manual API call needed here.
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Authentication failed');
    } catch (_) {
      setState(() => error = 'Unexpected error. Try again.');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // If user is Firebase-authenticated but backend sync failed,
    // show a retry option.
    if (auth.firebaseUser != null && auth.error != null) {
      return Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  auth.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : () => auth.retrySync(),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Retry connection'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              isSignup ? 'Create account' : 'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'School email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Password (min 6 chars)'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isSignup ? 'Sign up' : 'Log in'),
            ),
            TextButton(
              onPressed: () => setState(() => isSignup = !isSignup),
              child: Text(isSignup
                  ? 'Have an account? Log in'
                  : 'New here? Create an account'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Password reset email sent.')),
                  );
                }
              },
              child: const Text('Forgot password?'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
