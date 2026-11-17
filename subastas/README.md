# Subastas del Campo — prototipo

Página informativa independiente en `/subastas/` y aplicación demostrativa en `/subastas/app.html`.

## Incluye

- Búsqueda por producto, marca o vendedor; filtros por departamento y tipo de cosecha; orden por precio actual, precio inicial y cantidad de ofertas.
- Publicaciones tanto de cosecha a granel como de producto empacado o marca propia.
- Historial de pujas de demostración por participante, incremento mínimo configurable, cierre y selección de ganador.
- Vistas para mercado, ofertas, publicaciones, favoritos, conversaciones y fichas.
- Una ficha por oferta válida como regla demostrativa; publicar y conversar no consumen fichas.
- Chat y formulario para registrar productos localmente.
- Modelo de operación directa: productor y comprador acuerdan pago y entrega entre ellos.

## Límites del prototipo

No hay cuentas de usuario, base de datos compartida, mensajería entre personas distintas, notificaciones ni cobro de fichas. Las publicaciones, mensajes y ofertas no salen del dispositivo y no tienen validez comercial. Para una app real se necesita backend con autenticación, registro verificable de ofertas, mensajes privados y gestión de fichas en servidor. El plan de Google Sheets está en `GOOGLE_SHEETS_PLAN.md`.

## Archivos

- `index.html`: página y modales.
- `styles.css`: estilos aislados de la app.
- `market-v5.js`: datos de muestra, búsqueda, filtros, publicaciones y pujas locales.
- `app-v5.css`: estilos aislados de la aplicación.
