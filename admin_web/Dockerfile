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

# Habilitar soporte web
RUN flutter config --enable-web

# Construir la aplicación web en modo release
RUN flutter build web --release

# Comando por defecto para ejecutar en modo desarrollo
# Para producción, usar un servidor web como nginx
CMD ["flutter", "run", "-d", "chrome", "--web-port", "8081"]

