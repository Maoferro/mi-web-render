# Subastas del Campo — prototipo

Página informativa independiente en `/subastas/` y aplicación demostrativa en `/subastas/app.html`.

## Incluye

- Búsqueda, filtros por departamento y tipo de cosecha, y ordenamiento.
- Vistas para mercado, ofertas, publicaciones, favoritos, conversaciones y fichas.
- Una ficha por oferta válida como regla demostrativa; publicar y conversar no consumen fichas.
- Chat de demostración y formulario para registrar lotes localmente.
- Modelo de operación directa: productor y comprador acuerdan pago y entrega entre ellos.

## Límites del prototipo

No hay cuentas de usuario, base de datos compartida, mensajería entre personas distintas, notificaciones ni cobro de fichas. Las publicaciones, mensajes y ofertas no salen del dispositivo y no tienen validez comercial. Para una app real se necesita backend con autenticación, registro verificable de ofertas, mensajes privados y gestión de fichas en servidor. El plan de Google Sheets está en `GOOGLE_SHEETS_PLAN.md`.

## Archivos

- `index.html`: página y modales.
- `styles.css`: estilos aislados de la app.
- `app.js`: datos de muestra, búsqueda, filtros, publicaciones y pujas locales.
