import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../viewmodels/login_viewmodel.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final LoginViewModel _viewModel = LoginViewModel();

  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _carregando = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(usuario: credential.user),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      String mensagem = 'E-mail ou senha incorretos.';

      if (e.code == 'invalid-email') {
        mensagem = 'E-mail inválido.';
      } else if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado.';
      } else if (e.code == 'wrong-password') {
        mensagem = 'Senha incorreta.';
      } else if (e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha incorretos.';
      } else if (e.code == 'operation-not-allowed') {
        mensagem = 'Login por e-mail/senha não está ativado no Firebase.';
      }

      _mostrarErro(mensagem);
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      _mostrarErro('Erro inesperado: $e');
    }
  }

  Future<void> _fazerLoginComGoogle() async {
    setState(() => _carregando = true);

    try {
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();

      if (!googleSignIn.supportsAuthenticate()) {
        throw Exception('Este dispositivo não suporta login com Google.');
      }

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Não foi possível obter o token do Google.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      setState(() => _carregando = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(usuario: userCredential.user),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      String mensagem = 'Erro ao entrar com Google.';

      if (e.code == 'account-exists-with-different-credential') {
        mensagem = 'Já existe uma conta com esse e-mail usando outro método.';
      } else if (e.code == 'invalid-credential') {
        mensagem = 'Credencial do Google inválida.';
      } else if (e.code == 'operation-not-allowed') {
        mensagem = 'Login com Google não está ativado no Firebase.';
      }

      _mostrarErro(mensagem);
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      _mostrarErro('Erro ao entrar com Google. Verifique a configuração do Firebase.');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _logoLogin() {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A853).withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD4A853),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.content_cut,
              size: 56,
              color: Color(0xFFD4A853),
            );
          },
        ),
      ),
    );
  }

  Widget _botaoEntrar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _carregando ? null : _fazerLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4A853),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: _carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Text('Entrar'),
      ),
    );
  }

  Widget _botaoGoogle() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _carregando ? null : _fazerLoginComGoogle,
        icon: const Icon(
          Icons.g_mobiledata,
          size: 32,
          color: Color(0xFFD4A853),
        ),
        label: const Text(
          'Entrar com Google',
          style: TextStyle(
            color: Color(0xFFD4A853),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD4A853)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _divisor() {
    return const Row(
      children: [
        Expanded(
          child: Divider(color: Color(0xFF3C3C3C)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: TextStyle(color: Colors.white38),
          ),
        ),
        Expanded(
          child: Divider(color: Color(0xFF3C3C3C)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _logoLogin(),
                  const SizedBox(height: 12),
                  const Text(
                    'Felipe Barber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Faça seu login',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 36),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('E-mail', Icons.email_outlined),
                    validator: _viewModel.validarEmail,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_senhaVisivel,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Senha',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white38,
                        ),
                        onPressed: () =>
                            setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                    ),
                    validator: _viewModel.validarSenha,
                  ),
                  const SizedBox(height: 28),

                  _botaoEntrar(),

                  const SizedBox(height: 18),

                  _divisor(),

                  const SizedBox(height: 18),

                  _botaoGoogle(),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Não tem conta? ',
                        style: TextStyle(color: Colors.white54),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: Color(0xFFD4A853),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4A853), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}