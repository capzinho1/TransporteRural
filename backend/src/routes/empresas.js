const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// GET /api/empresas - Obtener todas las empresas
router.get('/', async (req, res) => {
  try {
    const { data: empresas, error } = await supabase
      .from('companies')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: empresas,
      count: empresas.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener empresas',
      message: error.message
    });
  }
});

// GET /api/empresas/:id - Obtener empresa por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: empresa, error } = await supabase
      .from('companies')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!empresa) {
      return res.status(404).json({
        success: false,
        error: 'Empresa no encontrada'
      });
    }
    
    res.json({
      success: true,
      data: empresa
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener empresa',
      message: error.message
    });
  }
});

// POST /api/empresas - Crear nueva empresa
router.post('/', async (req, res) => {
  try {
    const { name, email, password, phone, address, active } = req.body;
    
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
    
    if (!password || password.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'La contraseña es requerida',
        message: 'El campo "password" no puede estar vacío'
      });
    }
    
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        error: 'La contraseña es muy corta',
        message: 'La contraseña debe tener al menos 6 caracteres'
      });
    }
    
    // Construir objeto de inserción
    const insertData = {
      name: name.trim(),
      email: email.trim(),
      password: password.trim(), // En producción, debería hashearse
      active: active !== undefined ? active : true
    };
    
    // Solo agregar campos opcionales si están presentes
    if (phone !== undefined && phone !== null && phone.trim() !== '') {
      insertData.phone = phone.trim();
    }
    if (address !== undefined && address !== null && address.trim() !== '') {
      insertData.address = address.trim();
    }
    
    // Crear la empresa
    const { data: nuevaEmpresa, error: empresaError } = await supabase
      .from('companies')
      .insert([insertData])
      .select()
      .single();
    
    if (empresaError) {
      console.error('Error al insertar empresa:', empresaError);
      throw empresaError;
    }
    
    // Crear automáticamente un usuario company_admin para esta empresa
    const emailTrimmed = email.trim();
    const passwordTrimmed = password.trim();
    const usuarioData = {
      email: emailTrimmed,
      password: passwordTrimmed, // En producción, debería hashearse igual que en companies
      role: 'company_admin',
      company_id: nuevaEmpresa.id,
      name: `Admin de ${name.trim()}`
    };
    
    console.log('Creando usuario admin para empresa:');
    console.log('  - Email:', emailTrimmed);
    console.log('  - Password (length):', passwordTrimmed.length);
    console.log('  - Password (value):', passwordTrimmed);
    console.log('  - Role: company_admin');
    console.log('  - Company ID:', nuevaEmpresa.id);
    
    const { data: nuevoUsuario, error: usuarioError } = await supabase
      .from('users')
      .insert([usuarioData])
      .select()
      .single();
    
    if (usuarioError) {
      console.error('Error al crear usuario admin:', usuarioError);
      // No fallar la creación de la empresa si el usuario ya existe
      if (usuarioError.message.includes('duplicate') || usuarioError.message.includes('unique') || usuarioError.code === '23505') {
        console.warn('El usuario admin ya existe, continuando...');
      } else {
        console.error('Error crítico al crear usuario admin:', usuarioError);
        // Aún así, continuamos porque la empresa ya fue creada
      }
    } else {
      console.log('Usuario admin creado exitosamente:');
      console.log('  - Email:', nuevoUsuario.email);
      console.log('  - Password guardada (length):', nuevoUsuario.password ? nuevoUsuario.password.length : 'NULL');
      console.log('  - Password guardada (value):', nuevoUsuario.password);
      console.log('  - Role:', nuevoUsuario.role);
      console.log('  - Company ID:', nuevoUsuario.company_id);
      
      // Verificar que la contraseña se guardó correctamente haciendo una consulta
      const { data: usuarioVerificado, error: errorVerificacion } = await supabase
        .from('users')
        .select('email, password, role, company_id')
        .eq('id', nuevoUsuario.id)
        .single();
      
      if (!errorVerificacion && usuarioVerificado) {
        console.log('  - Verificación post-insert:');
        console.log('    - Password en BD:', usuarioVerificado.password ? `"${usuarioVerificado.password}" (length: ${usuarioVerificado.password.length})` : 'NULL');
      }
    }
    
    res.status(201).json({
      success: true,
      data: nuevaEmpresa,
      message: 'Empresa creada exitosamente. El administrador puede acceder con el email y contraseña proporcionados.'
    });
  } catch (error) {
    console.error('Error completo:', error);
    res.status(500).json({
      success: false,
      error: 'Error al crear empresa',
      message: error.message || error.details || 'Error desconocido'
    });
  }
});

// PUT /api/empresas/:id - Actualizar empresa
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, password, phone, address, active } = req.body;
    
    // Validar campos obligatorios si se están actualizando
    if (name !== undefined && (!name || name.trim() === '')) {
      return res.status(400).json({
        success: false,
        error: 'El nombre es requerido',
        message: 'El campo "name" no puede estar vacío'
      });
    }
    
    if (email !== undefined && (!email || email.trim() === '')) {
      return res.status(400).json({
        success: false,
        error: 'El email es requerido',
        message: 'El campo "email" no puede estar vacío'
      });
    }
    
    if (password !== undefined && password !== null && password.trim() !== '') {
      if (password.length < 6) {
        return res.status(400).json({
          success: false,
          error: 'La contraseña es muy corta',
          message: 'La contraseña debe tener al menos 6 caracteres'
        });
      }
    }
    
    const updateData = {};
    if (name !== undefined) updateData.name = name.trim();
    if (email !== undefined) updateData.email = email.trim();
    if (password !== undefined && password !== null && password.trim() !== '') {
      updateData.password = password.trim(); // En producción, debería hashearse
    }
    if (phone !== undefined) updateData.phone = phone ? phone.trim() : null;
    if (address !== undefined) updateData.address = address ? address.trim() : null;
    if (active !== undefined) updateData.active = active;
    
    // Si se actualiza el email o password, también actualizar el usuario admin asociado
    if (email !== undefined || (password !== undefined && password !== null && password.trim() !== '')) {
      // Buscar el usuario company_admin asociado a esta empresa
      const { data: usuarios, error: usuariosError } = await supabase
        .from('users')
        .select('id')
        .eq('company_id', id)
        .eq('role', 'company_admin')
        .limit(1);
      
      if (!usuariosError && usuarios && usuarios.length > 0) {
        const usuarioUpdate = {};
        if (email !== undefined) usuarioUpdate.email = email.trim();
        if (password !== undefined && password !== null && password.trim() !== '') {
          usuarioUpdate.password = password.trim(); // En producción, debería hashearse igual
        }
        
        await supabase
          .from('users')
          .update(usuarioUpdate)
          .eq('id', usuarios[0].id);
      }
    }
    
    const { data: empresaActualizada, error } = await supabase
      .from('companies')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: empresaActualizada,
      message: 'Empresa actualizada exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar empresa',
      message: error.message
    });
  }
});

// DELETE /api/empresas/:id - Eliminar empresa
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { error } = await supabase
      .from('companies')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    
    res.json({
      success: true,
      message: `Empresa ${id} eliminada exitosamente`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al eliminar empresa',
      message: error.message
    });
  }
});

module.exports = router;

