import 'package:flutter/material.dart';

/// Paleta de colores mejorada para la aplicación
/// Mantiene el verde como principal pero con mejor contraste
class AppColors {
  // Colores principales (verde)
  static const Color primaryGreen = Color(0xFF2E7D32); // Verde oscuro principal
  static const Color primaryGreenLight = Color(0xFF4CAF50); // Verde claro
  static const Color primaryGreenLighter = Color(0xFF81C784); // Verde más claro
  static const Color primaryGreenDark = Color(0xFF1B5E20); // Verde muy oscuro

  // Colores de estado
  static const Color statusActive = Color(0xFF4CAF50); // Verde para activo
  static const Color statusInactive = Color(0xFF9E9E9E); // Gris para inactivo
  static const Color statusInProgress =
      Color(0xFF2196F3); // Azul para en progreso
  static const Color statusMaintenance =
      Color(0xFFFF9800); // Naranja para mantenimiento
  static const Color statusCompleted =
      Color(0xFF2196F3); // Azul para completado
  static const Color statusWarning =
      Color(0xFFFFC107); // Amarillo para advertencia
  static const Color statusError = Color(0xFFF44336); // Rojo para error

  // Colores de acento (para contraste)
  static const Color accentBlue = Color(0xFF1976D2); // Azul acento
  static const Color accentPurple = Color(0xFF7B1FA2); // Morado acento
  static const Color accentOrange = Color(0xFFFF6F00); // Naranja acento
  static const Color accentTeal = Color(0xFF00796B); // Verde azulado acento
  static const Color accentIndigo = Color(0xFF303F9F); // Índigo acento

  // Colores de fondo
  static const Color backgroundLight = Color(0xFFF5F5F5); // Fondo claro
  static const Color backgroundCard = Color(0xFFFFFFFF); // Fondo de tarjetas
  static const Color backgroundDark = Color(0xFF212121); // Fondo oscuro

  // Colores de texto
  static const Color textPrimary = Color(0xFF212121); // Texto principal
  static const Color textSecondary = Color(0xFF757575); // Texto secundario
  static const Color textLight = Color(0xFFFFFFFF); // Texto claro

  // Colores de empresas (variaciones para diferenciar)
  static const List<Color> companyColors = [
    Color(0xFF2E7D32), // Verde principal
    Color(0xFF1976D2), // Azul
    Color(0xFF7B1FA2), // Morado
    Color(0xFFFF6F00), // Naranja
    Color(0xFF00796B), // Verde azulado
    Color(0xFF303F9F), // Índigo
    Color(0xFFC2185B), // Rosa
    Color(0xFF00838F), // Cyan oscuro
  ];

  // Obtener color de empresa por índice
  static Color getCompanyColor(int? companyId) {
    if (companyId == null) return primaryGreen;
    return companyColors[companyId % companyColors.length];
  }

  // Obtener color de estado del bus
  static Color getBusStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'en_ruta':
        return statusActive;
      case 'inactive':
        return statusInactive;
      case 'in_progress':
        return statusInProgress;
      case 'maintenance':
        return statusMaintenance;
      case 'completed':
      case 'finalizado':
        return statusCompleted;
      default:
        return statusInactive;
    }
  }

  // Gradientes para efectos visuales
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryGreenLight, primaryGreen],
    );
  }

  static LinearGradient getStatusGradient(String status) {
    final color = getBusStatusColor(status);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.8),
        color,
      ],
    );
  }
}
