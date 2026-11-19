# Subastas del Campo — prototipo

Página informativa independiente en `/subastas/` y aplicación demostrativa en `/subastas/app.html`.

## Incluye

- Búsqueda por producto, marca o vendedor; filtros por departamento y tipo de cosecha; orden por precio actual, precio inicial y cantidad de ofertas.
- Publicaciones tanto de cosecha a granel como de producto empacado o marca propia.
- Historial de pujas de demostración por participante, incremento mínimo configurable, cierre y selección de ganador.
- Vistas para mercado, ofertas, publicaciones, favoritos, conversaciones y fichas.
- Una ficha por oferta válida como regla demostrativa; publicar y conversar no consumen fichas.
- Billetera con paquetes y un checkout simulado para probar el abono de fichas, sin procesar pagos reales.
- Campo de oferta con separador de miles automático, accesos rápidos de incremento y aviso de saldo bajo o agotado.
- Chat y formulario para registrar productos localmente.
- Modelo de operación directa: productor y comprador acuerdan pago y entrega entre ellos.

## Límites del prototipo

No hay cobro real de fichas ni integración activa con Wompi. El checkout solo simula el resultado localmente; los medios Nequi, DaviPlata, PSE y Bancolombia son opciones de prueba, no botones conectados. Tampoco hay base de datos compartida, mensajería entre personas distintas ni notificaciones. Las publicaciones, mensajes y ofertas no salen del dispositivo y no tienen validez comercial. Para una app real se necesita backend con autenticación, registro verificable de ofertas, mensajes privados y gestión de fichas en servidor. El plan de Google Sheets está en `GOOGLE_SHEETS_PLAN.md`.

## Archivos

- `index.html`: página y modales.
- `styles.css`: estilos aislados de la app.
- `market-v5.js`: datos de muestra, búsqueda, filtros, publicaciones y pujas locales.
- `app-v5.css`: estilos aislados de la aplicación.
