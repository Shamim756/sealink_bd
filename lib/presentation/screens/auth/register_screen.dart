import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String _role = 'BUYER';
  bool _obscure = true;
  bool? _usernameOk;
  bool _checking = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String v) {
    _debounce?.cancel();
    if (v.length < 4) {
      setState(() {
        _usernameOk = null;
        _checking = false;
      });
      return;
    }
    setState(() => _checking = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final ok = await context.read<AuthProvider>().checkUsername(v);
      if (!mounted) return;
      setState(() {
        _usernameOk = ok;
        _checking = false;
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameOk != true) {
      _snack('Choose an available username', false);
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      role: _role,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, '/verify-email', arguments: {
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
      });
    } else {
      _snack(auth.error ?? 'Registration failed', false);
    }
  }

  void _snack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  Widget? _usernameSuffix() {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_usernameOk == null) return null;
    return Icon(
      _usernameOk! ? Icons.check_circle : Icons.cancel,
      color: _usernameOk! ? Colors.green : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _username,
                  onChanged: _onUsernameChanged,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: _usernameSuffix(),
                    helperText: _usernameOk == false
                        ? 'Username already taken'
                        : _usernameOk == true
                            ? 'Username available'
                            : null,
                    helperStyle: TextStyle(
                      color: _usernameOk == false
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  validator: Validators.username,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (01XXXXXXXXX)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
                                const SizedBox(height: 20),
                const Text('I am a:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 20),
                const Text('I am a:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                                RadioGroup<String>(
                  groupValue: _role,
                  onChanged: (v) => setState(() => _role = v!),
                  child: Row(
                    children: const [
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Buyer'),
                          value: 'BUYER',
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Supplier'),
                          value: 'SUPPLIER',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Register'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
