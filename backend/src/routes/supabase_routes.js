const express = require('express');
const router = express.Router();
const { UsersService, RoutesService, BusLocationsService, RealtimeService } = require('../services/supabase');

// =============================================
// USERS ROUTES
// =============================================

// GET /api/users - Get all users
router.get('/', async (req, res) => {
  try {
    const result = await UsersService.getAllUsers();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener usuarios',
      message: error.message
    });
  }
});

// GET /api/users/:uid - Get user by ID
router.get('/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const result = await UsersService.getUserById(uid);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener usuario',
      message: error.message
    });
  }
});

// POST /api/users - Create user
router.post('/', async (req, res) => {
  try {
    const userData = req.body;
    const result = await UsersService.createUser(userData);
    
    if (result.success) {
      res.status(201).json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear usuario',
      message: error.message
    });
  }
});

// PUT /api/users/:uid - Update user
router.put('/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const userData = req.body;
    const result = await UsersService.updateUser(uid, userData);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar usuario',
      message: error.message
    });
  }
});

// DELETE /api/users/:uid - Delete user
router.delete('/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const result = await UsersService.deleteUser(uid);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al eliminar usuario',
      message: error.message
    });
  }
});

// POST /api/users/login - User login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // TODO: Implementar autenticación real con Supabase Auth
    // Por ahora, simular login
    if (email === 'usuario@transporterural.com' && password === 'usuario123') {
      const token = 'jwt_token_example_' + Date.now();
      
      res.json({
        success: true,
        data: {
          token,
          usuario: {
            uid: '550e8400-e29b-41d4-a716-446655440000',
            name: 'Usuario de Prueba',
            email: 'usuario@transporterural.com',
            role: 'user',
            fcm_tokens: []
          }
        },
        message: 'Login exitoso'
      });
    } else {
      res.status(401).json({
        success: false,
        error: 'Credenciales inválidas'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error en autenticación',
      message: error.message
    });
  }
});

module.exports = router;

