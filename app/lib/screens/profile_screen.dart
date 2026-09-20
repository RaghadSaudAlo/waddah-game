import 'package:flutter/material.dart';
import '../services/user_profile_store.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String email = '';
  int age = 6;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final savedName = await UserProfileStore.getUsername();
    final savedEmail = await UserProfileStore.getEmail();
    final savedAge = await UserProfileStore.getAge();

    if (!mounted) return;

    setState(() {
      username = savedName;
      email = savedEmail;
      age = savedAge;
      isLoading = false;
    });
  }

  Future<void> _logout() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_screen.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            top: 32,
            left: 24,
            child: _CircleButton(
              icon: Icons.arrow_forward_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          const Positioned(
            top: 42,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ملف الطفل',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27A9C9),
                ),
              ),
            ),
          ),

          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : Container(
                    width: 620,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3C4).withOpacity(0.94),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/waddah.png',
                          width: 140,
                        ),
                        const SizedBox(height: 16),

                        _infoRow(
                          icon: Icons.child_care_rounded,
                          title: 'اسم الطفل',
                          value: username.isEmpty ? 'غير محدد' : username,
                        ),
                        const SizedBox(height: 16),

                        _infoRow(
                          icon: Icons.cake_rounded,
                          title: 'العمر',
                          value: '$age سنوات',
                        ),
                        const SizedBox(height: 16),

                        _infoRow(
                          icon: Icons.email_rounded,
                          title: 'البريد الإلكتروني',
                          value: email.isEmpty ? 'غير محدد' : email,
                        ),

                        const SizedBox(height: 28),

                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            width: 260,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFBFEFDD),
                                  Color(0xFFB8C9FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(34),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(
                                fontSize: 22,
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
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF27A9C9), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE08A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF2D2D2D),
          size: 26,
        ),
      ),
    );
  }
}