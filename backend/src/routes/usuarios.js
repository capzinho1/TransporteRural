const express = require('express');
const router = express.Router();

// GET /api/usuarios - Obtener todos los usuarios
router.get('/', async (req, res) => {
  try {
    // TODO: Implementar consulta a base de datos
    const usuarios = [
      {
        id: 1,
        nombre: 'María González',
        email: 'maria@email.com',
        telefono: '+56987654321',
        tipo: 'pasajero',
        activo: true,
        createdAt: '2024-01-15T10:30:00Z'
      },
      {
        id: 2,
        nombre: 'Carlos López',
        email: 'carlos@email.com',
        telefono: '+56912345678',
        tipo: 'conductor',
        activo: true,
        createdAt: '2024-01-10T08:15:00Z'
      }
    ];
    
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
    
    // TODO: Implementar consulta a base de datos
    const usuario = {
      id: parseInt(id),
      nombre: 'María González',
      email: 'maria@email.com',
      telefono: '+56987654321',
      tipo: 'pasajero',
      activo: true,
      preferencias: {
        notificaciones: true,
        idioma: 'es'
      },
      createdAt: '2024-01-15T10:30:00Z'
    };
    
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
    const { nombre, email, telefono, tipo, password } = req.body;
    
    // TODO: Implementar validación y guardado en base de datos
    const nuevoUsuario = {
      id: Date.now(),
      nombre,
      email,
      telefono,
      tipo,
      activo: true,
      preferencias: {
        notificaciones: true,
        idioma: 'es'
      },
      createdAt: new Date().toISOString()
    };
    
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
    
        // TODO: Implementar autenticación real
        if (email === 'usuario@transporterural.com' && password === 'usuario123') {
          const token = 'jwt_token_example_' + Date.now();
          
          res.json({
            success: true,
            data: {
              token,
              usuario: {
                id: 1,
                name: 'Usuario de Prueba',
                email: 'usuario@transporterural.com',
                role: 'user',
                notification_tokens: null
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

// PUT /api/usuarios/:id - Actualizar usuario
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, telefono, preferencias } = req.body;
    
    // TODO: Implementar actualización en base de datos
    const usuarioActualizado = {
      id: parseInt(id),
      nombre,
      telefono,
      preferencias,
      updatedAt: new Date().toISOString()
    };
    
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
    
    // TODO: Implementar eliminación en base de datos
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

