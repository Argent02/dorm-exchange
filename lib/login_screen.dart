import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _submit() async {
    setState(() => error = null);
    final email = emailCtrl.text.trim();
    final pass  = passCtrl.text.trim();

    if (!email.toLowerCase().endsWith('.edu')) {
      setState(() => error = 'Use your school\'s .edu email.');
      return;
    }

    try {
      if (isSignup) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Authentication failed');
    } catch (_) {
      setState(() => error = 'Unexpected error. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(isSignup ? 'Create account' : 'Welcome back', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'School email')),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password (min 6 chars)')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _submit, child: Text(isSignup ? 'Sign up' : 'Log in')),
            TextButton(
              onPressed: () => setState(() => isSignup = !isSignup),
              child: Text(isSignup ? 'Have an account? Log in' : 'New here? Create an account'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isNotEmpty) {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
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