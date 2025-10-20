# Usar imagen oficial de Flutter
FROM ghcr.io/cirruslabs/flutter:stable

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY pubspec.yaml pubspec.lock ./

# Instalar dependencias
RUN flutter pub get

# Copiar código fuente
COPY . .

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S flutter
RUN adduser -S flutter -u 1001

# Cambiar ownership de archivos
RUN chown -R flutter:flutter /app
USER flutter

# Exponer puerto para Flutter web
EXPOSE 8080

# Comando por defecto para ejecutar en modo web
CMD ["flutter", "run", "-d", "chrome", "--web-port", "8080", "--web-hostname", "0.0.0.0"]
