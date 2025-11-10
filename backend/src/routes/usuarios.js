const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// Helper para obtener usuario desde header o query
const getUserFromRequest = async (req) => {
  const userId = req.headers['x-user-id'] || req.query.user_id;
  if (!userId) return null;
  
  const { data: user } = await supabase
    .from('users')
    .select('role, company_id')
    .eq('id', userId)
    .single();
  
  return user;
};

// GET /api/usuarios - Obtener todos los usuarios
router.get('/', async (req, res) => {
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

// GET /api/usuarios/:id - Obtener usuario por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
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
router.post('/', async (req, res) => {
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
    
    // Construir objeto de inserción
    const insertData = {
      name: name.trim(),
      email: email.trim(),
      role: role || 'user',
      notification_tokens: notification_tokens || null,
      company_id: finalCompanyId || null
    };
    
    // Agregar password si se proporciona (para nuevos usuarios)
    if (password && password.trim() !== '') {
      insertData.password = password.trim();
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
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Buscar usuario en Supabase
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
    
    // SEGURIDAD: Solo verificar contraseña desde la base de datos
    // NO usar contraseñas hardcodeadas ni por defecto
    // TODO: Implementar verificación con bcrypt para mayor seguridad
    
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
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, role, notification_tokens, active, driver_status } = req.body;
    
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (role !== undefined) updateData.role = role;
    if (notification_tokens !== undefined) updateData.notification_tokens = notification_tokens;
    if (active !== undefined) updateData.active = active;
    if (driver_status !== undefined && role === 'driver') updateData.driver_status = driver_status;
    
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
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
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

module.exports = router;

