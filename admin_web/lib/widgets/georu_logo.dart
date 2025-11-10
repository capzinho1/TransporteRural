import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Widget reutilizable para mostrar el logo GeoRu
///
/// El logo consiste en:
/// - Un ícono de pin de mapa con colores verde y azul
/// - El texto "GeoRu" con "Geo" en gris y "Ru" en verde
/// - El eslogan "App Rural en Tiempo Real"
class GeoRuLogo extends StatelessWidget {
  final double? size;
  final bool showText;
  final bool showSlogan;
  final Color? backgroundColor;
  final bool showBackground;

  const GeoRuLogo({
    super.key,
    this.size,
    this.showText = true,
    this.showSlogan = false,
    this.backgroundColor,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? 120.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contenedor del logo con fondo opcional (solo si size > 0)
        if (logoSize > 0)
          Container(
            width: logoSize,
            height: logoSize,
            decoration: showBackground
                ? BoxDecoration(
                    color: backgroundColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  )
                : null,
            child: _buildLogoIcon(logoSize),
          ),
        if (showText) ...[
          if (logoSize > 0) const SizedBox(height: 16),
          _buildLogoText(),
        ],
        if (showSlogan) ...[
          const SizedBox(height: 8),
          _buildSlogan(),
        ],
      ],
    );
  }

  Widget _buildLogoIcon(double size) {
    // Intentar cargar la imagen del logo desde assets
    // Primero intenta WebP, luego PNG, y finalmente usa el CustomPainter como fallback
    return _buildLogoImage(size) ??
        CustomPaint(
          size: Size(size, size),
          painter: GeoRuLogoPainter(),
        );
  }

  Widget? _buildLogoImage(double size) {
    // En web, Flutter maneja los assets de forma diferente
    // Si estamos en web y no hay imagen, usar directamente el fallback
    if (kIsWeb) {
      // En web, intentar cargar pero si falla, usar CustomPainter directamente
      // Esto evita los errores 404 en consola
      return null; // Retornar null para usar el fallback directamente
    }

    // Lista de posibles rutas de la imagen del logo (en orden de prioridad)
    final possiblePaths = [
      'assets/images/georu_logo.webp',
      'assets/images/georu_logo.png',
      'assets/images/logo.webp',
      'assets/images/logo.png',
    ];

    // Widget que intenta cargar una imagen y muestra CustomPainter si falla
    return _LogoImageLoader(
      paths: possiblePaths,
      size: size,
      fallback: CustomPaint(
        size: Size(size, size),
        painter: GeoRuLogoPainter(),
      ),
    );
  }

  Widget _buildLogoText() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'sans-serif',
        ),
        children: [
          TextSpan(
            text: 'Geo',
            style: TextStyle(color: Color(0xFF424242)), // Gris oscuro
          ),
          TextSpan(
            text: 'Ru',
            style: TextStyle(color: Color(0xFF2E7D32)), // Verde
          ),
        ],
      ),
    );
  }

  Widget _buildSlogan() {
    return const Text(
      'App Rural en Tiempo Real',
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF757575), // Gris claro
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

/// Widget auxiliar para cargar imágenes del logo con fallback
class _LogoImageLoader extends StatelessWidget {
  final List<String> paths;
  final double size;
  final Widget fallback;

  const _LogoImageLoader({
    required this.paths,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // Intentar cargar cada imagen hasta encontrar una que exista
    for (final path in paths) {
      // Usar Image.asset con errorBuilder para manejar archivos faltantes
      // Si la imagen no existe, errorBuilder retornará el fallback
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Si esta imagen no existe, intentar la siguiente
          // Si es la última, mostrar el fallback
          final currentIndex = paths.indexOf(path);
          if (currentIndex < paths.length - 1) {
            // Intentar con la siguiente ruta recursivamente
            return _LogoImageLoader(
              paths: paths.sublist(currentIndex + 1),
              size: size,
              fallback: fallback,
            );
          }
          // Si no hay más rutas, mostrar el fallback (CustomPainter)
          return fallback;
        },
      );
    }

    // Si no hay rutas, mostrar el fallback
    return fallback;
  }
}

/// CustomPainter para dibujar el logo GeoRu
///
/// Dibuja un pin de mapa con:
/// - Parte superior izquierda: verde oscuro
/// - Parte superior derecha: azul claro
/// - Camino sinuoso dentro del pin (verde claro a marrón tierra)
class GeoRuLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final pinWidth = size.width * 0.65;
    final pinHeight = size.height * 0.75;

    // Dibujar el pin de mapa
    final pinPath = Path();

    // Parte superior redondeada del pin
    pinPath.moveTo(centerX, centerY - pinHeight / 2);
    pinPath.quadraticBezierTo(
      centerX - pinWidth / 2,
      centerY - pinHeight / 2,
      centerX - pinWidth / 2,
      centerY - pinHeight / 3,
    );

    // Lado izquierdo
    pinPath.lineTo(centerX - pinWidth / 2, centerY + pinHeight / 3);

    // Punta inferior
    pinPath.lineTo(centerX, centerY + pinHeight / 2);
    pinPath.lineTo(centerX + pinWidth / 2, centerY + pinHeight / 3);

    // Lado derecho
    pinPath.lineTo(centerX + pinWidth / 2, centerY - pinHeight / 3);

    // Cerrar el pin
    pinPath.quadraticBezierTo(
      centerX + pinWidth / 2,
      centerY - pinHeight / 2,
      centerX,
      centerY - pinHeight / 2,
    );
    pinPath.close();

    // Dividir el pin en dos secciones de color
    final clipPath = Path()
      ..moveTo(centerX, centerY - pinHeight / 2)
      ..lineTo(centerX, centerY + pinHeight / 2)
      ..lineTo(centerX - pinWidth / 2, centerY + pinHeight / 3)
      ..lineTo(centerX - pinWidth / 2, centerY - pinHeight / 3)
      ..close();

    // Dibujar parte izquierda (verde oscuro)
    canvas.save();
    canvas.clipPath(clipPath);
    paint.color = const Color(0xFF1B5E20); // Verde oscuro
    canvas.drawPath(pinPath, paint);
    canvas.restore();

    // Dibujar parte derecha (azul claro)
    final rightClipPath = Path()
      ..moveTo(centerX, centerY - pinHeight / 2)
      ..lineTo(centerX, centerY + pinHeight / 2)
      ..lineTo(centerX + pinWidth / 2, centerY + pinHeight / 3)
      ..lineTo(centerX + pinWidth / 2, centerY - pinHeight / 3)
      ..close();

    canvas.save();
    canvas.clipPath(rightClipPath);
    paint.color = const Color(0xFF81D4FA); // Azul claro
    canvas.drawPath(pinPath, paint);
    canvas.restore();

    // Dibujar borde del pin para mejor visibilidad
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawPath(pinPath, borderPaint);

    // Dibujar el camino sinuoso dentro del pin
    final roadPath = Path();
    final roadStartX = centerX - pinWidth / 3;
    final roadStartY = centerY - pinHeight / 3;
    final roadEndX = centerX;
    final roadEndY = centerY + pinHeight / 3;

    roadPath.moveTo(roadStartX, roadStartY);
    roadPath.quadraticBezierTo(
      centerX - pinWidth / 6,
      centerY - pinHeight / 6,
      centerX,
      centerY,
    );
    roadPath.quadraticBezierTo(
      centerX + pinWidth / 6,
      centerY + pinHeight / 6,
      roadEndX,
      roadEndY,
    );

    // Gradiente del camino (verde claro a marrón tierra)
    final roadGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFA5D6A7), // Verde claro
          Color(0xFF8D6E63), // Marrón tierra
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(roadPath, roadGradient);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
