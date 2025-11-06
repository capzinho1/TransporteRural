const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// GET /api/usuarios - Obtener todos los usuarios
router.get('/', async (req, res) => {
  try {
    const { data: usuarios, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false });
    
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
    const { name, email, role, notification_tokens } = req.body;
    
    const { data: nuevoUsuario, error } = await supabase
      .from('users')
      .insert([
        {
          name,
          email,
          role: role || 'user',
          notification_tokens: notification_tokens || null
        }
      ])
      .select()
      .single();
    
    if (error) throw error;
    
    res.status(201).json({
      success: true,
      data: nuevoUsuario,
      message: 'Usuario creado exitosamente'
    });
  } catch (error) {
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
    
    // TODO: Implementar verificación real de contraseña con bcrypt
    // Por ahora, aceptamos credenciales de prueba
    const validPasswords = {
      'admin@transporterural.com': 'admin123',
      'usuario@transporterural.com': 'usuario123',
      'conductor1@transporterural.com': 'conductor123',
      'conductor2@transporterural.com': 'conductor123'
    };
    
    if (validPasswords[email] !== password) {
      return res.status(401).json({
        success: false,
        error: 'Credenciales inválidas'
      });
    }
    
    // Generar token simple (TODO: implementar JWT real)
    const token = 'jwt_token_' + Date.now();
    
    res.json({
      success: true,
      data: {
        token,
        usuario: usuario
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
    const { name, email, role, notification_tokens } = req.body;
    
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (role !== undefined) updateData.role = role;
    if (notification_tokens !== undefined) updateData.notification_tokens = notification_tokens;
    
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

