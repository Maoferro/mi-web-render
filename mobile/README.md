# App de Subastas del Campo

## Aplicación móvil

El código compartido de la app está en `mobile/flutter`. Está hecho con Flutter y muestra su interfaz desde código móvil; no carga la web en un WebView. El mismo código Dart sirve como base para Android e iOS.

El APK que compila `.github/workflows/build-android-apk.yml` usa esta app Flutter. El anterior APK basado en WebView fue retirado para evitar confundirlo con la app móvil nativa.

## Alcance de esta versión

Esta es una demostración interactiva de un solo dispositivo. Se puede crear un perfil de prueba, explorar y filtrar subastas, revisar el reloj y las cinco ofertas más altas, publicar como productor, ofertar con la regla de un token por subasta y administrar el saldo de demostración. Las publicaciones, los perfiles, los tokens y las ofertas se guardan localmente y no se comparten entre teléfonos.

El saldo de prueba no cobra dinero. Esta versión tampoco valida cédulas ni reconocimiento facial, no procesa pagos, no envía notificaciones entre usuarios y no ofrece una conexión real entre comprador y vendedor. No usar datos personales reales ni tomar decisiones comerciales basadas en esta demo.

## Preparar el proyecto local

Los archivos nativos de Android ya están en `mobile/flutter/android`. Instala Flutter y Android Studio con el SDK de Android; luego ejecuta:

```powershell
cd mobile/flutter
flutter pub get
flutter run
```

En macOS, Flutter puede generar la plataforma iOS alrededor del mismo código con `flutter create --platforms=ios --org co.fumigo --project-name subastas_del_campo .` y compilarla con Xcode. Para distribuir por TestFlight o App Store se necesitan la cuenta y el proceso de Apple.

## Generar APK desde GitHub

Cada actualización del código Flutter genera un APK instalable como artefacto de GitHub Actions desde el proyecto ubicado en esta carpeta. El workflow también permite crear un Release manual ingresando una etiqueta. Es una versión de prueba sin firma de publicación de Play Store.

## Próxima etapa antes de operar

Conectar autenticación, subastas en tiempo real, tokens, cierre y permisos administrativos a Supabase mediante políticas de servidor y RLS. Luego integrar el pago real y diseñar el flujo de privacidad/verificación antes de solicitar documentos de identidad. Render sigue alojando la página web; no es el backend de esta aplicación móvil.
