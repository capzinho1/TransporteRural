const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { validateAll, validateParams, validateQuery, validateEmail, sanitizeEmail, validateAndSanitizeId, validateAndSanitizeString } = require('../middleware/validation');

// Helper para obtener usuario desde header o query
const getUserFromRequest = async (req) => {
  let userId = req.headers['x-user-id'] || req.query.user_id;
  if (!userId) return null;
  
  // Validar y sanitizar el ID del usuario
  userId = validateAndSanitizeId(userId);
  if (!userId) return null;
  
  const { data: user } = await supabase
    .from('users')
    .select('role, company_id')
    .eq('id', userId)
    .single();
  
  return user;
};

// GET /api/usuarios - Obtener todos los usuarios
router.get('/', validateQuery, async (req, res) => {
  try {
    let query = supabase
      .from('users')
      .select('*');
    
    // Filtrar por empresa si es company_admin
    const user = await getUserFromRequest(req);
    if (user && user.role === 'company_admin' && user.company_id) {
      query = query.eq('company_id', user.company_id);
    }
    
    query = query.order('created_at', { ascending: false });
    
    const { data: usuarios, error } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: usuarios,
      count: usuarios.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener usuarios',
      message: error.message
    });
  }
});

// GET /api/usuarios/:id/status - Verificar estado del usuario (para verificación periódica)
// IMPORTANTE: Esta ruta debe estar ANTES de /:id para que Express la capture correctamente
router.get('/:id/status', validateParams, async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: usuario, error } = await supabase
      .from('users')
      .select('id, active, role')
      .eq('id', id)
      .single();
    
    if (error || !usuario) {
      return res.status(404).json({
        success: false,
        error: 'Usuario no encontrado'
      });
    }
    
    res.json({
      success: true,
      data: {
        id: usuario.id,
        active: usuario.active !== false, // null o undefined se considera activo
        role: usuario.role
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al verificar estado del usuario',
      message: error.message
    });
  }
});

// GET /api/usuarios/:id - Obtener usuario por ID
router.get('/:id', validateParams, async (req, res) => {
  try {
    const { id } = req.params;
    
    // El ID ya fue validado y sanitizado por validateParams
    const { data: usuario, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!usuario) {
      return res.status(404).json({
        success: false,
        error: 'Usuario no encontrado'
      });
    }
    
    res.json({
      success: true,
      data: usuario
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener usuario',
      message: error.message
    });
  }
});

// POST /api/usuarios - Crear nuevo usuario
router.post('/', validateAll, async (req, res) => {
  try {
    const { name, email, role, password, notification_tokens, company_id } = req.body;
    
    // Validar campos obligatorios
    if (!name || name.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'El nombre es requerido',
        message: 'El campo "name" no puede estar vacío'
      });
    }
    
    if (!email || email.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'El email es requerido',
        message: 'El campo "email" no puede estar vacío'
      });
    }
    
    // Obtener usuario y asignar company_id automáticamente si es company_admin
    const user = await getUserFromRequest(req);
    let finalCompanyId = company_id;
    if (!finalCompanyId && user && user.role === 'company_admin' && user.company_id) {
      finalCompanyId = user.company_id;
    }
    
    // Sanitizar y validar campos
    name = validateAndSanitizeString(name, 100, 1);
    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'El nombre es inválido'
      });
    }
    
    email = sanitizeEmail(email);
    if (!email || !validateEmail(email)) {
      return res.status(400).json({
        success: false,
        error: 'El email es inválido'
      });
    }
    
    // Validar role (solo valores permitidos)
    const allowedRoles = ['super_admin', 'company_admin', 'driver', 'user'];
    role = role ? String(role).toLowerCase() : 'user';
    if (!allowedRoles.includes(role)) {
      role = 'user';
    }
    
    // Validar company_id si se proporciona
    if (finalCompanyId) {
      finalCompanyId = validateAndSanitizeId(finalCompanyId);
    }
    
    // Construir objeto de inserción
    const insertData = {
      name,
      email,
      role,
      notification_tokens: notification_tokens ? validateAndSanitizeString(notification_tokens, 500) : null,
      company_id: finalCompanyId || null
    };
    
    // Agregar password si se proporciona (para nuevos usuarios)
    if (password && typeof password === 'string' && password.trim() !== '') {
      // Validar longitud mínima de password
      if (password.length < 6) {
        return res.status(400).json({
          success: false,
          error: 'La contraseña debe tener al menos 6 caracteres'
        });
      }
      insertData.password = password; // No sanitizar password (puede tener caracteres especiales)
    } else if (!password) {
      // Si no se proporciona password, establecer uno por defecto según el rol
      // En producción, esto debería requerirse siempre
      insertData.password = role === 'driver' ? 'conductor123' : 'usuario123';
    }
    
    const { data: nuevoUsuario, error } = await supabase
      .from('users')
      .insert([insertData])
      .select()
      .single();
    
    if (error) {
      console.error('Error al crear usuario:', error);
      throw error;
    }
    
    // Remover password del objeto antes de enviarlo
    const { password: _, ...usuarioSinPassword } = nuevoUsuario;
    
    res.status(201).json({
      success: true,
      data: usuarioSinPassword,
      message: 'Usuario creado exitosamente'
    });
  } catch (error) {
    console.error('Error al crear usuario:', error);
    res.status(500).json({
      success: false,
      error: 'Error al crear usuario',
      message: error.message
    });
  }
});

// POST /api/usuarios/login - Autenticación de usuario
// Soporta tanto usuarios locales (conductores) como usuarios de Supabase Auth (pasajeros)
router.post('/login', validateAll, async (req, res) => {
  try {
    let { email, password } = req.body;
    
    // Validar y sanitizar email
    if (!email || typeof email !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Email es requerido'
      });
    }
    
    email = sanitizeEmail(email);
    if (!email || !validateEmail(email)) {
      return res.status(400).json({
        success: false,
        error: 'Email inválido'
      });
    }
    
    // Validar password
    if (!password || typeof password !== 'string' || password.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Contraseña es requerida'
      });
    }
    
    // Buscar usuario en Supabase (Supabase usa parámetros preparados, seguro contra SQL injection)
    const { data: usuario, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();
    
    if (error || !usuario) {
      return res.status(401).json({
        success: false,
        error: 'Credenciales inválidas'
      });
    }
    
    // Verificar el método de autenticación del usuario
    const authProvider = usuario.auth_provider || 'local'; // Por defecto 'local' para usuarios antiguos
    
    // Si el usuario usa Supabase Auth, autenticar con Supabase Auth
    if (authProvider === 'supabase' || usuario.supabase_auth_id) {
      try {
        // Autenticar con Supabase Auth
        const { createClient } = require('@supabase/supabase-js');
        const supabaseUrl = process.env.SUPABASE_URL || 'https://aghbbmbbfcgtpipnrjev.supabase.co';
        const supabaseKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY;
        
        const supabaseAuth = createClient(supabaseUrl, supabaseKey);
        
        const { data: authData, error: authError } = await supabaseAuth.auth.signInWithPassword({
          email: email,
          password: password,
        });
        
        if (authError || !authData.user) {
          console.error(`Login fallido para ${email} (Supabase Auth):`, authError?.message);
          return res.status(401).json({
            success: false,
            error: 'Credenciales inválidas',
            message: 'Email o contraseña incorrectos'
          });
        }
        
        // Verificar si el usuario está activo
        const isActive = usuario.active !== false;
        if (!isActive) {
          return res.status(403).json({
            success: false,
            error: 'Cuenta desactivada',
            message: 'Su cuenta ha sido desactivada. Por favor, contacte al administrador.'
          });
        }
        
        console.log(`Login exitoso para usuario: ${email} (Supabase Auth)`);
        
        // Remover password del objeto usuario antes de enviarlo
        const { password: _, ...usuarioSinPassword } = usuario;
        
        return res.json({
          success: true,
          data: {
            token: authData.session?.access_token || 'supabase_token',
            usuario: usuarioSinPassword
          },
          message: 'Login exitoso'
        });
      } catch (authErr) {
        console.error(`Error en autenticación Supabase Auth para ${email}:`, authErr);
        return res.status(401).json({
          success: false,
          error: 'Credenciales inválidas',
          message: 'Error al autenticar. Por favor, intente nuevamente.'
        });
      }
    }
    
    // Usuario local (conductor) - autenticación tradicional
    // Verificar que el usuario tenga contraseña en la BD
    if (!usuario.password || usuario.password.trim() === '') {
      console.error(`Login rechazado: Usuario ${email} no tiene contraseña en la BD`);
      return res.status(401).json({
        success: false,
        error: 'Credenciales inválidas',
        message: 'El usuario no tiene contraseña configurada. Contacte al administrador.'
      });
    }
    
    // Comparar contraseña ingresada con la almacenada en la BD
    const passwordBD = String(usuario.password).trim();
    const passwordIngresada = String(password).trim();
    
    // Comparación directa (en producción debería usar bcrypt.compare)
    const isValidPassword = passwordBD === passwordIngresada;
    
    if (!isValidPassword) {
      // No revelar información específica por seguridad (no loggear contraseñas)
      console.error(`Login fallido para ${email}`);
      return res.status(401).json({
        success: false,
        error: 'Credenciales inválidas',
        message: 'Email o contraseña incorrectos'
      });
    }
    
    // Verificar si el usuario está activo (especialmente importante para conductores)
    const isActive = usuario.active !== false; // null o undefined se considera activo por defecto
    if (!isActive) {
      console.error(`Login rechazado: Usuario ${email} tiene cuenta desactivada`);
      return res.status(403).json({
        success: false,
        error: 'Cuenta desactivada',
        message: usuario.role === 'driver' 
          ? 'Su cuenta de conductor ha sido desactivada. Por favor, contacte al administrador de su empresa.'
          : 'Su cuenta ha sido desactivada. Por favor, contacte al administrador.'
      });
    }
    
    // Log básico sin información sensible
    console.log(`Login exitoso para usuario: ${email}`);
    
    // Generar token simple (TODO: implementar JWT real)
    const token = 'jwt_token_' + Date.now();
    
    // Remover password del objeto usuario antes de enviarlo
    const { password: _, ...usuarioSinPassword } = usuario;
    
    res.json({
      success: true,
      data: {
        token,
        usuario: usuarioSinPassword
      },
      message: 'Login exitoso'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error en autenticación',
      message: error.message
    });
  }
});

// PUT /api/usuarios/:id - Actualizar usuario
router.put('/:id', validateAll, async (req, res) => {
  try {
    const { id } = req.params;
    // Los datos ya fueron validados y sanitizados por validateAll
    let { name, email, role, notification_tokens, active, driver_status } = req.body;
    
    const updateData = {};
    
    // Sanitizar y validar cada campo si está presente
    if (name !== undefined) {
      name = validateAndSanitizeString(name, 100, 1);
      if (name) updateData.name = name;
    }
    
    if (email !== undefined) {
      email = sanitizeEmail(email);
      if (email && validateEmail(email)) {
        updateData.email = email;
      }
    }
    
    // Validar role (solo valores permitidos)
    if (role !== undefined) {
      const allowedRoles = ['super_admin', 'company_admin', 'driver', 'user'];
      if (allowedRoles.includes(String(role).toLowerCase())) {
        updateData.role = String(role).toLowerCase();
      }
    }
    
    if (notification_tokens !== undefined) {
      updateData.notification_tokens = validateAndSanitizeString(notification_tokens, 500);
    }
    
    if (active !== undefined) {
      updateData.active = Boolean(active);
    }
    
    if (driver_status !== undefined && role === 'driver') {
      const allowedStatuses = ['disponible', 'en_ruta', 'fuera_de_servicio', 'en_descanso'];
      const status = String(driver_status).toLowerCase();
      if (allowedStatuses.includes(status)) {
        updateData.driver_status = status;
      }
    }
    
    const { data: usuarioActualizado, error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: usuarioActualizado,
      message: 'Usuario actualizado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar usuario',
      message: error.message
    });
  }
});

// DELETE /api/usuarios/:id - Eliminar usuario
router.delete('/:id', validateParams, async (req, res) => {
  try {
    const { id } = req.params;
    
    // El ID ya fue validado y sanitizado por validateParams
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    
    res.json({
      success: true,
      message: `Usuario ${id} eliminado exitosamente`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al eliminar usuario',
      message: error.message
    });
  }
});

// POST /api/usuarios/sync-supabase - Sincronizar usuario de Supabase Auth con tabla users
router.post('/sync-supabase', validateAll, async (req, res) => {
  try {
    let { supabase_auth_id, email, name, region } = req.body;

    console.log('📝 [SYNC_SUPABASE] Recibida petición de sincronización:');
    console.log('   - supabase_auth_id:', supabase_auth_id);
    console.log('   - email:', email);
    console.log('   - name:', name);
    console.log('   - region:', region);

    // Validar supabase_auth_id (UUID)
    if (!supabase_auth_id || typeof supabase_auth_id !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'supabase_auth_id es requerido'
      });
    }
    supabase_auth_id = String(supabase_auth_id).replace(/[^a-fA-F0-9-]/g, '');
    if (supabase_auth_id.length !== 36) {
      return res.status(400).json({
        success: false,
        error: 'supabase_auth_id inválido (debe ser un UUID válido)'
      });
    }

    // Validar y sanitizar email
    if (!email || typeof email !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'email es requerido'
      });
    }
    email = sanitizeEmail(email);
    if (!email || !validateEmail(email)) {
      return res.status(400).json({
        success: false,
        error: 'email inválido'
      });
    }

    // Validar y sanitizar name
    if (!name || typeof name !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'name es requerido'
      });
    }
    name = validateAndSanitizeString(name, 100, 1);
    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'name inválido (debe tener entre 1 y 100 caracteres)'
      });
    }

    // Sanitizar region (opcional)
    region = region ? validateAndSanitizeString(region, 100) : null;

    // Verificar si el usuario ya existe por supabase_auth_id
    console.log('🔍 [SYNC_SUPABASE] Buscando usuario existente por supabase_auth_id...');
    const { data: existingUser, error: existingUserError } = await supabase
      .from('users')
      .select('*')
      .eq('supabase_auth_id', supabase_auth_id)
      .single();

    if (existingUserError && existingUserError.code !== 'PGRST116') {
      // PGRST116 = no rows returned (no es un error, solo que no existe)
      console.error('❌ [SYNC_SUPABASE] Error al buscar usuario existente:', existingUserError);
      throw existingUserError;
    }

    if (existingUser) {
      console.log('✅ [SYNC_SUPABASE] Usuario existente encontrado, actualizando...');
      // Usuario ya existe, actualizar si es necesario
      const { data: updatedUser, error } = await supabase
        .from('users')
        .update({
          email: email,
          name: name,
          region: region || null,
          updated_at: new Date().toISOString()
        })
        .eq('supabase_auth_id', supabase_auth_id)
        .select()
        .single();

      if (error) throw error;

      return res.json({
        success: true,
        usuario: updatedUser
      });
    }

    // Verificar si el email ya existe (pero con otro auth_provider)
    console.log('🔍 [SYNC_SUPABASE] Buscando usuario existente por email...');
    const { data: emailUser, error: emailUserError } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();

    if (emailUserError && emailUserError.code !== 'PGRST116') {
      // PGRST116 = no rows returned (no es un error, solo que no existe)
      console.error('❌ [SYNC_SUPABASE] Error al buscar usuario por email:', emailUserError);
      throw emailUserError;
    }

    if (emailUser) {
      console.log('✅ [SYNC_SUPABASE] Email existente encontrado, actualizando para usar Supabase Auth...');
      // Email existe pero con otro método de autenticación
      // Actualizar para usar Supabase Auth
      const { data: updatedUser, error } = await supabase
        .from('users')
        .update({
          supabase_auth_id: supabase_auth_id,
          auth_provider: 'supabase',
          password: null, // Eliminar password ya que usa Supabase Auth
          region: region || emailUser.region || null,
          updated_at: new Date().toISOString()
        })
        .eq('email', email)
        .select()
        .single();

      if (error) throw error;

      return res.json({
        success: true,
        usuario: updatedUser
      });
    }

    // Crear nuevo usuario
    console.log('📝 [SYNC_SUPABASE] Creando nuevo usuario...');
    const insertData = {
      email: email.trim(),
      name: name.trim(),
      role: 'user', // Pasajeros siempre tienen role 'user'
      auth_provider: 'supabase',
      supabase_auth_id: supabase_auth_id,
      region: region ? region.trim() : null,
      password: null, // No se almacena password para usuarios de Supabase Auth
      active: true
    };
    
    console.log('📝 [SYNC_SUPABASE] Datos a insertar:', JSON.stringify(insertData, null, 2));
    
    const { data: newUser, error } = await supabase
      .from('users')
      .insert([insertData])
      .select()
      .single();

    if (error) {
      console.error('❌ [SYNC_SUPABASE] Error al crear usuario:', error);
      console.error('❌ [SYNC_SUPABASE] Código de error:', error.code);
      console.error('❌ [SYNC_SUPABASE] Mensaje:', error.message);
      console.error('❌ [SYNC_SUPABASE] Detalles:', error.details);
      throw error;
    }

    console.log('✅ [SYNC_SUPABASE] Usuario creado exitosamente:', newUser.id);

    res.json({
      success: true,
      usuario: newUser
    });
  } catch (error) {
    console.error('Error sincronizando usuario de Supabase:', error);
    res.status(500).json({
      success: false,
      error: 'Error al sincronizar usuario',
      message: error.message
    });
  }
});

// GET /api/usuarios/supabase/:supabaseAuthId - Obtener usuario por Supabase Auth ID
router.get('/supabase/:supabaseAuthId', validateParams, async (req, res) => {
  try {
    const { supabaseAuthId } = req.params;
    
    console.log('🔍 [GET_USER_BY_SUPABASE_ID] Buscando usuario con supabase_auth_id:', supabaseAuthId);

    const { data: usuario, error } = await supabase
      .from('users')
      .select('*')
      .eq('supabase_auth_id', supabaseAuthId)
      .single();

    if (error) {
      // PGRST116 = no rows returned (no es un error crítico, solo que no existe)
      if (error.code === 'PGRST116') {
        console.log('ℹ️ [GET_USER_BY_SUPABASE_ID] Usuario no encontrado (esto es normal para nuevos usuarios)');
        return res.status(404).json({
          success: false,
          error: 'Usuario no encontrado'
        });
      }
      console.error('❌ [GET_USER_BY_SUPABASE_ID] Error de Supabase:', error);
      throw error;
    }

    if (!usuario) {
      console.log('ℹ️ [GET_USER_BY_SUPABASE_ID] Usuario no encontrado');
      return res.status(404).json({
        success: false,
        error: 'Usuario no encontrado'
      });
    }

    console.log('✅ [GET_USER_BY_SUPABASE_ID] Usuario encontrado:', usuario.id, usuario.email);

    res.json({
      success: true,
      usuario: usuario
    });
  } catch (error) {
    console.error('❌ [GET_USER_BY_SUPABASE_ID] Error obteniendo usuario por Supabase Auth ID:', error);
    res.status(500).json({
      success: false,
      error: 'Error al obtener usuario',
      message: error.message
    });
  }
});

module.exports = router;

