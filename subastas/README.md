# Subastas del Campo — prototipo

Página independiente accesible en `/subastas/` cuando el sitio estático publica la raíz del repositorio.

## Incluye

- Búsqueda y filtros de lotes de demostración.
- Formulario para agregar lotes al almacenamiento local del navegador.
- Registro local de ofertas de prueba.
- Explicación del modelo: productor y comprador acuerdan directamente el pago y la entrega.

## Límites del prototipo

No hay cuentas de usuario, base de datos compartida, notificaciones, pujas en tiempo real, pagos ni logística. Las publicaciones y ofertas no salen del dispositivo y no tienen validez comercial. Para lanzar subastas reales se necesita backend con autenticación, registro inmutable de ofertas, cierre del lote y herramientas administrativas. La integración de pagos divididos queda para una fase posterior, si se elige ese modelo.

## Archivos

- `index.html`: página y modales.
- `styles.css`: estilos aislados de la app.
- `app.js`: datos de muestra, búsqueda, filtros, publicaciones y pujas locales.
