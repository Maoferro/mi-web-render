# Registro operativo para Subastas del Campo

## Flujo deseado

La plataforma publica lotes, recibe ofertas con fichas y conecta vendedor y comprador por chat. Cada parte coordina directamente el pago del producto, la fecha y el transporte. La plataforma no recibe el precio de la cosecha ni gestiona la entrega.

## Google Sheet privado

El Sheet sirve como registro administrativo y reporte. No debe compartirse con compradores ni vendedores ni conectarse directamente desde el JavaScript público de Render.

Pestañas propuestas:

- **Usuarios:** ID, rol, nombre, correo/teléfono de contacto, fecha de registro y aceptación del aviso de privacidad.
- **Lotes:** ID del lote, ID del vendedor, tipo de cosecha, producto, departamento, municipio, cantidad, precio mínimo, apertura/cierre y estado.
- **Ofertas:** ID de oferta, lote, ID del comprador, monto, fichas usadas, hora y estado.
- **Fichas:** movimientos por usuario, cantidad, motivo, fecha y referencia de pago del paquete cuando se active la venta de fichas.
- **Acuerdos:** lote, vendedor y comprador, resumen de condiciones que ambas partes confirman, precio convenido, fecha y lugar acordados, estado de confirmación y fecha.

## Conversaciones y datos personales

El chat necesita autenticación y almacenamiento con permisos por conversación para que solo quienes participan puedan leerlo. El Sheet debe recibir el registro mínimo de operación y el resumen del acuerdo confirmado por ambas partes. No copiar mensajes completos ni datos de pago sensibles a una hoja sin definir previamente aviso, autorización, acceso y tiempo de conservación.

## Conexión técnica pendiente

La web actual es estática y guarda la demostración en el navegador de cada persona; no sincroniza chats, cuentas u ofertas entre usuarios. En esta sesión el conector de Google Drive/Sheets aparece deshabilitado por administración, así que no se puede crear ni enlazar el Sheet desde aquí.

Para una puesta en marcha real: autenticar usuarios, guardar lotes/ofertas/chats en un backend con reglas de acceso, validar ofertas y descontar fichas de forma atómica en el servidor, y sincronizar al Sheet privado solo los registros administrativos necesarios. No poner credenciales de Google en el JavaScript del navegador.
