# Plan técnico: Supabase + n8n

## Estado actual

La aplicación es estática. Perfiles, publicaciones, ofertas, tokens, chats, calificaciones y reportes se guardan en `localStorage`; Admin solo ve los datos del mismo origen y navegador. Las métricas de demanda cuentan ofertas, no ventas. La recarga de tokens sigue simulada. Ninguna clave privada debe agregarse a JavaScript del navegador.

## Arquitectura objetivo

1. **Supabase Auth** identifica a cada comprador, productor y administrador.
2. **Postgres** guarda el estado central. El navegador consulta mediante una capa de datos y nunca escribe directamente datos privilegiados.
3. **Row Level Security (RLS)** limita perfiles, chats, documentos, contactos, ofertas y calificaciones según usuario, participantes de la subasta y rol administrador.
4. **Edge Functions/API** validan una puja, su incremento, cierre, saldo y la restricción única de una entrada por usuario y subasta. Una tabla `auction_participations` con clave única `(auction_id, buyer_id)` garantiza que el token se descuente una sola vez; las pujas siguientes no consumen tokens.
5. **n8n** recibe eventos de una outbox mediante webhook autenticado, con ID idempotente y reintentos. Puede producir notificaciones, reportes agregados y tareas de soporte. No debe ser el árbitro de la puja ni guardar secretos en el cliente.

## Tablas sugeridas

- `profiles`: `user_id`, `role`, nombre público, celular, foto (ruta de Storage), `identity_status`, `account_status`, fecha de alta.
- `identity_checks`: referencia del proveedor, resultado, fecha y auditoría. Evitar guardar fotos de cédula/selfie o plantillas biométricas si un proveedor puede devolver una verificación sin retenerlas.
- `listings`: vendedor, título, cultivo, variedad, calidad, cantidad/unidad, cosecha, ubicación, foto, alcance y estado.
- `auctions`: publicación, apertura, cierre, incremento, umbral privado del vendedor y ganador. El umbral privado solo debe ser accesible desde funciones autorizadas y para el vendedor.
- `bids`: subasta, comprador, monto, hora y estado.
- `auction_participations`: comprador, subasta, token debitado y fecha; índice único `(auction_id, buyer_id)`.
- `token_ledger`, `token_packages`, `payment_orders`: saldo inmutable, paquete, referencia de pasarela, estado verificado por webhook y auditoría. Nunca acreditar saldo por un retorno del navegador.
- `chat_threads`, `chat_messages`: participantes, texto, fecha y permisos. La revisión administrativa debe tener finalidad declarada, permisos por rol y registro de acceso.
- `reviews`: operación, evaluador, evaluado, estrellas, criterios por rol, comentario y confirmación de entrega.
- `moderation_cases`, `evidence_files`, `sanctions`: motivo, relato, evidencias, estado de revisión, responsable y decisión. Separar suspensión temporal, cierre de caso y bloqueo por documento.
- `event_outbox`, `admin_audit_log`: eventos pendientes para n8n y trazabilidad de cambios administrativos.

## Eventos para n8n

`user.registered`, `identity.review_requested`, `listing.created`, `auction.opened`, `auction.participant_entered`, `bid.accepted`, `auction.closed`, `delivery.confirmed`, `review.submitted`, `moderation.case_opened`, `moderation.case_resolved`, `token.package_paid`.

La integración de pagos debe verificar la firma del webhook de Wompi desde servidor. El monto y el estado que envía el navegador no son prueba de pago.

## Panel Admin y analítica

- Perfil, rol, foto, estado de revisión de cédula, saldo, tokens de cortesía y estado de cuenta.
- Publicaciones por vendedor, ofertas y entradas por subasta, paquetes comprados y calificaciones recibidas.
- “Más/menos demandado” calculado con ofertas. Para informar “más comprado” se necesita una operación marcada como entregada por ambas partes; aun así sería entrega reportada, pues el pago ocurre directamente entre ellas.
- Indicadores de palabras clave de chat agregados, con acceso al contenido solo para personal autorizado cuando sea necesario atender un caso.
- Casos graves con evidencia, estado, persona revisora y motivo de la decisión.

## Identidad y biometría

Esta demo puede marcar una revisión manual de cédula, pero no valida el documento contra una entidad ni hace reconocimiento facial. En Colombia, los datos biométricos son sensibles y la autorización debe ser explícita e informada; no se debe tratar como un requisito técnico ya habilitado. Antes de elegir un proveedor se debe definir una alternativa no biométrica, finalidad, retención, seguridad y proceso de derechos del titular.

## Orden de migración

1. Configurar proyecto Supabase, Auth, Storage privado, tablas, restricciones y RLS.
2. Migrar perfiles/publicaciones y sustituir escrituras de `localStorage` por funciones autorizadas.
3. Implementar pujas atómicas y ledger de tokens; validar pagos solo por webhook.
4. Añadir chats, confirmaciones, calificaciones y revisión de casos con permisos.
5. Conectar n8n a la outbox y probar idempotencia, reintentos, privacidad y auditoría.
6. Ejecutar una revisión de seguridad y privacidad antes de abrir el registro público.

No colocar `service_role`, secretos de Wompi, tokens de n8n ni credenciales administrativas en archivos `app.html` o `.js` públicos.
