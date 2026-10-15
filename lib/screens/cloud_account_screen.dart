import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/cloud_save_service.dart';

class CloudAccountScreen extends StatefulWidget {
  const CloudAccountScreen({super.key});
  @override
  State<CloudAccountScreen> createState() => _CloudAccountScreenState();
}

class _CloudAccountScreenState extends State<CloudAccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _cloud = CloudSaveService.instance;
  bool _register = false;
  bool _working = false;
  String? _message;

  Future<void> _authenticate() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      if (_register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text);
      }
      _password.clear();
    } on FirebaseAuthException catch (error) {
      if (mounted)
        setState(() => _message = switch (error.code) {
              'invalid-credential' ||
              'wrong-password' ||
              'user-not-found' =>
                'Check your email and password.',
              'email-already-in-use' =>
                'That email already has an account. Choose Sign in.',
              'weak-password' =>
                'Use a stronger password, at least 8 characters.',
              'too-many-requests' =>
                'Too many attempts. Please try again later.',
              'network-request-failed' =>
                'Connect to the internet and try again.',
              _ => error.message ?? 'Could not sign in. Please try again.',
            });
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Enter your email first.');
      return;
    }
    setState(() => _working = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted)
        setState(() =>
            _message = 'If that account exists, a reset email is on its way.');
    } on FirebaseAuthException catch (_) {
      if (mounted)
        setState(() => _message =
            'Could not request a reset. Check your email and connection.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Choose progress'),
                  content: Text(message),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Continue'))
                  ])) ??
      false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Account & Cloud Save')),
        body: ListenableBuilder(
            listenable: _cloud,
            builder: (context, _) => Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(Icons.cloud_done_outlined, size: 64),
                              const SizedBox(height: 16),
                              const Text('Your pets, wherever you play.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              if (!_cloud.available)
                                const Text(
                                    'Cloud accounts could not start. You can still play offline. Restart while connected to retry.')
                              else if (_cloud.user == null) ...[
                                const Text(
                                    'Sign in with email to keep your pet family, coins, care journal, and game progress across devices. Offline play is always available.'),
                                const SizedBox(height: 20),
                                Form(
                                    key: _form,
                                    child: Column(children: [
                                      TextFormField(
                                          controller: _email,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.email
                                          ],
                                          decoration: const InputDecoration(
                                              labelText: 'Email'),
                                          validator: (value) => value != null &&
                                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                      .hasMatch(value.trim())
                                              ? null
                                              : 'Enter a valid email'),
                                      TextFormField(
                                          controller: _password,
                                          obscureText: true,
                                          autofillHints: [
                                            _register
                                                ? AutofillHints.newPassword
                                                : AutofillHints.password
                                          ],
                                          decoration: const InputDecoration(
                                              labelText: 'Password'),
                                          validator: (value) => value != null &&
                                                  value.length >=
                                                      (_register ? 8 : 1)
                                              ? null
                                              : 'Use at least 8 characters'),
                                    ])),
                                const SizedBox(height: 20),
                                FilledButton(
                                    onPressed: _working ? null : _authenticate,
                                    child: Text(_register
                                        ? 'Create account'
                                        : 'Sign in')),
                                TextButton(
                                    onPressed: _working
                                        ? null
                                        : () => setState(
                                            () => _register = !_register),
                                    child: Text(_register
                                        ? 'Already have an account? Sign in'
                                        : 'New here? Create account')),
                                TextButton(
                                    onPressed: _working ? null : _resetPassword,
                                    child: const Text('Forgot password?')),
                              ] else ...[
                                Text(_cloud.user!.email ?? 'Signed in',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                Text(_cloud.status),
                                if (_cloud.lastSaved != null)
                                  Text(
                                      'Last cloud save: ${_cloud.lastSaved!.toLocal().toString().split('.').first}'),
                                const SizedBox(height: 16),
                                if (_cloud.needsChoice)
                                  const Text(
                                      'Choose a save to start automatic cloud saving. Restoring replaces the progress on this device.'),
                                if (_cloud.needsChoice)
                                  FilledButton(
                                      onPressed: _cloud.busy
                                          ? null
                                          : () async {
                                              if (!_cloud.cloudExists ||
                                                  await _confirm(
                                                      'Replace the cloud save with this device’s progress?'))
                                                await _cloud.useDevice();
                                            },
                                      child: const Text(
                                          'Use this device’s progress')),
                                if (!_cloud.needsChoice)
                                  FilledButton.icon(
                                      onPressed: _cloud.busy
                                          ? null
                                          : () => _cloud.save(force: false),
                                      icon: const Icon(Icons.cloud_upload),
                                      label: const Text('Save now')),
                                OutlinedButton.icon(
                                    onPressed: _cloud.busy
                                        ? null
                                        : () async {
                                            if (await _confirm(
                                                'Restore your cloud save? A backup of this device’s progress will be kept locally.'))
                                              await _cloud.restore();
                                          },
                                    icon: const Icon(Icons.cloud_download),
                                    label:
                                        const Text('Restore cloud progress')),
                                TextButton(
                                    onPressed:
                                        _cloud.busy ? null : _cloud.retry,
                                    child: const Text('Refresh cloud status')),
                                TextButton(
                                    onPressed: _cloud.busy
                                        ? null
                                        : () async {
                                            await _cloud.save();
                                            await FirebaseAuth.instance
                                                .signOut();
                                          },
                                    child: const Text('Sign out')),
                                const Text(
                                    'Cloud saves are private to your account. Signing out keeps local progress on this device.'),
                              ],
                              if (_working || _cloud.busy)
                                const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(
                                        child: CircularProgressIndicator())),
                              if (_message != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(_message!)),
                            ]),
                      )),
                )),
      );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
