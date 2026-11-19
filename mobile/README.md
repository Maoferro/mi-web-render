# App Android de prueba

Este proyecto genera un APK de prueba de **Subastas del Campo**. La app abre la versión web hospedada en Render dentro de una WebView y necesita conexión a internet. El selector de archivos permite elegir fotos para publicaciones.

El APK es una vista móvil del prototipo web, no un backend nativo. Las pujas, perfiles, tokens y publicaciones continúan siendo una demostración guardada localmente en el navegador/WebView.

## Descargar APK

Cuando se ejecute la acción de GitHub, el APK aparecerá en la sección **Releases** del repositorio. La acción se puede ejecutar desde GitHub → Actions → **Build Android preview APK** → Run workflow.

## Compilar localmente

Se requiere Java 17, Android SDK Platform 35, Build Tools 35.0.0 y Gradle 8.7:

```powershell
gradle --no-daemon -p mobile/android assembleDebug
```

Salida: `mobile/android/app/build/outputs/apk/debug/app-debug.apk`.

## iOS y una misma base para ambas plataformas

La web alojada es la base compartida. El APK Android actual abre esa web en una WebView, así que sus cambios de interfaz aparecen al conectarse a Render; solo hay que reconstruir el APK cuando cambie el contenedor nativo.

Para iPhone se puede añadir un contenedor iOS (por ejemplo, Capacitor) que cargue la misma app. El proyecto iOS se debe compilar y firmar con Xcode en macOS. Para probar en un dispositivo personal se puede usar Xcode; para distribuir por TestFlight o App Store se necesita una membresía del Apple Developer Program y el flujo de revisión de Apple. No es posible producir el paquete iOS firmado desde este equipo Windows.

Antes de publicar cualquiera de las dos apps para usuarios reales, se debe conectar el backend seguro de Supabase: el estado actual de perfiles, tokens, ofertas y publicaciones sigue siendo local a cada navegador o instalación.
