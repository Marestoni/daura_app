import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ ADICIONE
import '../controllers/login_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PEGAR O CONTROLLER DO PROVIDER
    final controller = context.watch<LoginController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business_center,
            size: 44,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Gestão Daura',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faça login para continuar',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildForm(LoginController controller) {
    return Column(
      children: [
        CustomTextField(
          label: 'E-mail',
          hint: 'Digite seu e-mail',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Senha',
          hint: 'Digite sua senha',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          validator: Validators.validatePassword,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Text(
              _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (controller.error != null) _buildError(controller.error!),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Entrar',
          onPressed: controller.isLoading ? null : () => _login(controller),
          isLoading: controller.isLoading,
        ),
        const SizedBox(height: 20),
        Text(
          'Desenvolvido com ❤️ para Gestão Daura',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _login(LoginController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _goToDashboard(controller);
    }
  }

  void _goToDashboard(LoginController controller) {
    final userName = controller.user?.name ?? 'Usuário';

    // ✅ VERIFICAR SE O USER NÃO É NULL
    print(
      '🔵 Navegando para Dashboard com usuário: ${controller.user?.toJson()}',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(userName: userName),
      ),
    );
  }
}
