import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';

class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({super.key});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen> {
  final List<String> _pin = [];
  bool _confirming = false;
  String _firstPin = '';
  String? _error;

  void _onNumberTap(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(number);
        _error = null;
      });

      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () => _processPin());
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
        _error = null;
      });
    }
  }

  void _processPin() async {
    final enteredPin = _pin.join();
    if (!_confirming) {
      setState(() {
        _firstPin = enteredPin;
        _confirming = true;
        _pin.clear();
      });
    } else {
      if (enteredPin == _firstPin) {
        // Save PIN
        await ref.read(authServiceProvider).savePin(enteredPin);
        if (mounted) {
          final userModel = ref.read(userModelProvider).value;
          if (userModel?.role == 'admin') {
            context.go('/mode-select');
          } else {
            context.go('/user-home');
          }
        }
      } else {
        setState(() {
          _pin.clear();
          _confirming = false;
          _firstPin = '';
          _error = AppStrings.errorPinMismatch;
        });
      }
    }
  }

  Widget _buildDot(int index) {
    bool active = index < _pin.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primaryAccent : Colors.transparent,
        border: Border.all(color: active ? AppColors.primaryAccent : AppColors.textSecondary, width: 2),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primaryAccent.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
    ).animate(target: active ? 1 : 0).scale(duration: 150.ms);
  }

  Widget _buildNumKey(String text) {
    return InkWell(
      onTap: () => _onNumberTap(text),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
          color: AppColors.glassBackground,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.lock_outline, size: 64, color: AppColors.primaryAccent)
                  .animate()
                  .shake(duration: 500.ms),
              const SizedBox(height: 24),
              Text(
                AppStrings.pinTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                _confirming ? AppStrings.confirmPinSubtitle : AppStrings.pinSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Dots Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => _buildDot(index)),
              ),
              
              const SizedBox(height: 24),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                ).animate().shake(),
                
              const Spacer(),
              
              // Numpad Grid
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['1', '2', '3'].map((n) => _buildNumKey(n)).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['4', '5', '6'].map((n) => _buildNumKey(n)).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['7', '8', '9'].map((n) => _buildNumKey(n)).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 76), // empty space
                        _buildNumKey('0'),
                        InkWell(
                          onTap: _onBackspace,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 76,
                            height: 76,
                            alignment: Alignment.center,
                            child: const Icon(Icons.backspace_outlined, size: 28, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
