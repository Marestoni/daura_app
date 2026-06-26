# daura_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



# 1. Sair do projeto
cd ..

# 2. Fechar completamente o emulador e Android Studio

# 3. Limpar TODOS os caches
# Cache do Gradle
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\caches\ -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\daemon\ -ErrorAction SilentlyContinue

# Cache do projeto
Remove-Item -Recurse -Force .\daura_app\build\ -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\daura_app\android\.gradle\ -ErrorAction SilentlyContinue

# 4. Voltar para o projeto
cd daura_app

# 5. Limpar com flutter
flutter clean