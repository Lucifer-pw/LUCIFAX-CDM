import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';
import 'package:lucifax_cdm/core/services/github_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isRegister;
  const LoginScreen({super.key, required this.isRegister});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  Future<void> _checkUpdates() async {
    final updateInfo = await GithubService.checkUpdates();
    if (updateInfo != null && updateInfo['hasUpdate'] == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.glassBorder),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              const Text(AppStrings.updateAvailableTitle),
            ],
          ),
          content: Text(
            AppStrings.updateAvailableDesc.replaceFirst('{version}', updateInfo['latestVersion']) +
            '\n\nCatatan Rilis:\n${updateInfo['releaseNotes']}'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.updateLaterBtn, style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (updateInfo['downloadUrl'] != null) {
                  _startDownloadFlow(updateInfo['downloadUrl']);
                } else {
                  // Fallback to launch web page
                  GithubService.launchUrlString(updateInfo['htmlUrl'] ?? '');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(AppStrings.updateDownloadBtn),
            ),
          ],
        ),
      );
    }
  }

  void _startDownloadFlow(String url) {
    double progress = 0.0;
    String? error;
    bool completed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (completed) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) Navigator.pop(context);
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.glassBorder),
              ),
              title: const Text('Mengunduh Pembaruan...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  Text('${(progress * 100).toStringAsFixed(0)}% selesai'),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ],
                ],
              ),
              actions: error != null
                  ? [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      )
                    ]
                  : [],
            );
          },
        );
      },
    );

    GithubService.downloadAndInstallApk(
      url,
      (p) {
        if (mounted) {
          // Trigger rebuild of progress dialog
          // Find context of Dialog and state
          // To update state inside StatefulWidget Builder:
          progress = p;
          (context as Element).visitAncestorElements((element) {
            if (element is StatefulElement && element.state is StatefulBuilder) {
              element.state.setState(() {});
            }
            return true;
          });
        }
      },
      (err) {
        completed = true;
        if (err != null) {
          error = err;
          if (mounted) {
            (context as Element).visitAncestorElements((element) {
              if (element is StatefulElement && element.state is StatefulBuilder) {
                element.state.setState(() {});
              }
              return true;
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (widget.isRegister) {
        await authService.register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        await authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        // Check if PIN setup is required
        final hasPin = await authService.hasPinSetup();
        if (hasPin) {
          context.go('/mode-select');
        } else {
          context.go('/pin-setup');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('user-not-found') || e.toString().contains('wrong-password')
            ? AppStrings.errorAuth
            : 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Animation
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                ],
              ),
            ),
          ),
          // Glow decorations
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 100,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withOpacity(0.1),
                blurRadius: 80,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Icon
                      Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: AppColors.primaryAccent,
                      ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 32,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        widget.isRegister ? 'Lindungi perangkat Anda sekarang' : 'Masuk untuk mengontrol perangkat Anda',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fadeIn(delay: 300.ms),
                      
                      const SizedBox(height: 40),
                      
                      // Form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.glassBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.isRegister) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Nama Lengkap',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: AppStrings.emailHint,
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: AppStrings.passwordHint,
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) => value == null || value.length < 6 ? 'Kata sandi minimal 6 karakter' : null,
                            ),
                            const SizedBox(height: 24),
                            
                            if (_errorMessage != null) ...[
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(widget.isRegister ? AppStrings.registerBtn : AppStrings.loginBtn),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                      
                      const SizedBox(height: 24),
                      
                      // Register or Login Switch Button
                      TextButton(
                        onPressed: () {
                          if (widget.isRegister) {
                            context.go('/login');
                          } else {
                            context.go('/register');
                          }
                        },
                        child: Text(
                          widget.isRegister ? AppStrings.loginLink : AppStrings.registerLink,
                          style: const TextStyle(color: AppColors.primaryAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
