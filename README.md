# Gestiones Express

Sitio estático con catálogo público y panel de administración conectado a Supabase.

## Proyecto conectado

- Proyecto: **Gestiones Express**
- Región: Canadá central (`ca-central-1`)
- Project ref: `ztxkffmryvzdfyonpynx`
- API URL: `https://ztxkffmryvzdfyonpynx.supabase.co`
- `config.js` contiene la URL y una clave publicable `sb_publishable_...`, apropiada para código de navegador. Nunca pongas `service_role` ni `sb_secret_...` en archivos públicos.

## Archivos

- `index.html`: catálogo público.
- `admin.html`: panel de administración.
- `config.js`: conexión del frontend a Supabase.
- `supabase-schema.sql`: referencia del esquema y políticas instaladas.

## Estado actual y pendientes

- El esquema está aplicado; RLS está activado en `servicios`, `config` y `admin_users`.
- El WhatsApp de contacto está configurado en la base de datos en formato internacional sin `+`.
- No hay servicios cargados todavía.
- El correo de administrador proporcionado no aparece como usuario en Authentication, por lo que no se le concedió acceso. Esto evita autorizar una identidad que todavía no existe.
- No hay un repositorio GitHub accesible en la conexión actual y esta sesión no dispone de una acción para crear uno; por tanto, todavía no hay URL pública del sitio.

## Habilitar tu administrador sin compartir contraseñas

1. Abre [Supabase Authentication → Users](https://supabase.com/dashboard/project/ztxkffmryvzdfyonpynx/auth/users).
2. Pulsa **Add user → Create new user** y crea una cuenta con el correo del administrador y una contraseña fuerte. No compartas la contraseña en el chat ni la guardes en el repositorio.
3. Copia el UUID de ese usuario recién creado.
4. En [SQL Editor](https://supabase.com/dashboard/project/ztxkffmryvzdfyonpynx/sql/new), ejecuta el siguiente SQL reemplazando el texto de ejemplo por el UUID real:

   ```sql
   insert into public.admin_users (user_id)
   values ('UUID_REAL_DEL_USUARIO');
   ```

5. Después abre `admin.html`, inicia sesión y prueba crear un servicio de prueba. Solo los usuarios incluidos expresamente en `public.admin_users` pueden administrar servicios, la configuración y las imágenes.

No ejecutes el SQL anterior con el texto de ejemplo literal. No insertes usuarios directamente en `auth.users`.

## Publicar en GitHub Pages

1. Crea un repositorio vacío en tu cuenta GitHub (por ejemplo, `gestiones-express`).
2. Sube `index.html`, `admin.html`, `config.js` y `supabase-schema.sql` a la raíz de la rama `main`.
3. En **Settings → Pages**, elige **Deploy from a branch**, selecciona `main` y `/ (root)`.
4. Espera a que GitHub publique el sitio y abre la URL que muestre Pages.

El panel `admin.html` no se enlaza desde el catálogo público; además requiere inicio de sesión y autorización de administrador.

## Seguridad y pruebas

- Los análisis actuales de Supabase no reportan avisos de seguridad ni de rendimiento.
- Visitantes anónimos pueden leer servicios activos y la configuración pública de WhatsApp, pero no insertar ni eliminar servicios ni cambiar la configuración.
- Las imágenes del bucket `servicios` son públicas para lectura; escribir, actualizar o borrar requiere autorización de administrador. Límite: 5 MB; JPEG, PNG, WebP y GIF.
- La función `contar_click` usa `SECURITY INVOKER`; el acceso público está limitado por permisos de columna y políticas RLS.
- El catálogo aún no se puede considerar publicado y probado desde un navegador externo. Las solicitudes HTTP directas desde el entorno de ejecución no pudieron resolver el host DNS de Supabase; el proyecto sí aparece `ACTIVE_HEALTHY` en la API de gestión de Supabase.
