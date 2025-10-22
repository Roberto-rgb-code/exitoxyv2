import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Mostrar loading mientras se verifica la autenticación
        if (authService.isLoading) {
          return _buildLoadingScreen(context);
        }

        // Si hay usuario autenticado, mostrar la app principal
        if (authService.user != null) {
          return child;
        }

        // Si no hay usuario autenticado, mostrar login
        return const LoginPage();
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 1000.ms),
              
              SizedBox(height: 30),
              
              // App name
              Text(
                'exitoxy',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              
              SizedBox(height: 10),
              
              // Subtitle
              Text(
                'Inteligencia de Mercado Geoespacial',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 700.ms),
              
              SizedBox(height: 40),
              
              // Loading indicator
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 900.ms),
              
              SizedBox(height: 20),
              
              // Loading text
              Text(
                'Cargando...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 1100.ms),
            ],
          ),
        ),
      ),
    );
  }
}

