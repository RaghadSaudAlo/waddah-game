import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/user_profile_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  int age = 6;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_screen.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            top: 28,
            left: 28,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFBFEFDD),
                      Color(0xFFB8C9FF),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),

          Center(
            child: SizedBox(
              width: 640,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _inputField(
                      controller: usernameController,
                      hint: 'اسم المستخدم',
                    ),
                    const SizedBox(height: 18),

                    _ageField(),

                    const SizedBox(height: 18),
                    _inputField(
                      controller: emailController,
                      hint: 'البريد الإلكتروني',
                    ),
                    const SizedBox(height: 18),
                    _inputField(
                      controller: passwordController,
                      hint: 'كلمة المرور',
                      obscure: true,
                    ),

                    const SizedBox(height: 28),

                    GestureDetector(
                      onTap: () async {
  await UserProfileStore.saveUser(
    username: usernameController.text.trim(),
    email: emailController.text.trim(),
    age: age,
  );

  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => const HomeScreen(),
    ),
  );
},
                      child: Container(
                        width: 320,
                        height: 78,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFBFEFDD),
                              Color(0xFFB8C9FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4).withOpacity(0.9),
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: obscure,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.black38,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ageField() {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4).withOpacity(0.9),
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (age > 5) {
                setState(() {
                  age--;
                });
              }
            },
            icon: const Icon(Icons.remove_circle_outline),
            color: const Color(0xFF7EC8E3),
          ),
          IconButton(
            onPressed: () {
              if (age < 11) {
                setState(() {
                  age++;
                });
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF7EC8E3),
          ),
          Expanded(
            child: Text(
              'العمر: $age',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}