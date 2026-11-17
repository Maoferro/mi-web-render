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
