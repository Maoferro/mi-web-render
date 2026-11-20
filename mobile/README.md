# App de Subastas del Campo

## Aplicación móvil

El código compartido de la app está en `mobile/flutter`. Está hecho con Flutter y muestra su interfaz desde código móvil; no carga la web en un WebView. El mismo código Dart sirve como base para Android e iOS.

El APK que compila `.github/workflows/build-android-apk.yml` usa esta app Flutter y el icono propio de Subastas del Campo. El anterior APK basado en WebView fue retirado para evitar confundirlo con la app móvil nativa.

## Alcance de esta versión

La interfaz móvil nativa cubre los principales recorridos de la web: mercado con búsqueda tolerante a tildes, filtros por ubicación/categoría y orden, detalle con cronómetro semáforo, gráfico y cinco mejores ofertas, publicación de producto individual o paquete con foto, alcance geográfico y reglas de cierre, ofertas con token único por subasta, favoritos, actividad del comprador/vendedor, conversación habilitada al ganador, confirmación de entrega y calificación, reglas y saldo con checkout simulado.

Sigue siendo una demostración de un solo dispositivo. Perfiles, lotes, fotos, chats y ofertas se guardan localmente y no se comparten entre teléfonos. La simulación de Nequi/DaviPlata/PSE no cobra; no existe verificación de identidad, push, moderación de cuentas ni panel de superadministrador seguro. Estos servicios necesitan backend y autenticación real. La calificación se guarda como evento local; la app no puede congelar o expulsar cuentas de forma segura sin revisión/servidor.

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
