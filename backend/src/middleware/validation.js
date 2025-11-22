/**
 * Middleware de validación y sanitización para prevenir SQL injection y validar entradas
 */

/**
 * Sanitiza un string eliminando caracteres peligrosos
 */
const sanitizeString = (str) => {
  if (typeof str !== 'string') return str;
  // Eliminar caracteres peligrosos para SQL
  return str
    .replace(/['";\\]/g, '') // Eliminar comillas simples, dobles, punto y coma, backslash
    .replace(/--/g, '') // Eliminar comentarios SQL
    .replace(/\/\*/g, '') // Eliminar comentarios multilínea
    .replace(/\*\//g, '') // Eliminar comentarios multilínea
    .trim();
};

/**
 * Valida y sanitiza un ID numérico
 */
const validateAndSanitizeId = (id) => {
  if (!id) return null;
  
  // Convertir a número
  const numId = parseInt(id, 10);
  
  // Verificar que sea un número válido y positivo
  if (isNaN(numId) || numId <= 0) {
    return null;
  }
  
  return numId;
};

/**
 * Valida un email
 */
const validateEmail = (email) => {
  if (!email || typeof email !== 'string') return false;
  
  // Regex para validar email
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  
  // Verificar longitud máxima
  if (email.length > 255) return false;
  
  return emailRegex.test(email.trim());
};

/**
 * Sanitiza un email
 */
const sanitizeEmail = (email) => {
  if (!email || typeof email !== 'string') return null;
  return email.trim().toLowerCase();
};

/**
 * Valida y sanitiza un string con longitud máxima
 */
const validateAndSanitizeString = (str, maxLength = 255, minLength = 0) => {
  if (!str || typeof str !== 'string') return null;
  
  const sanitized = sanitizeString(str);
  
  if (sanitized.length < minLength) return null;
  if (maxLength && sanitized.length > maxLength) return null;
  
  return sanitized;
};

/**
 * Valida que un valor sea un número válido
 */
const validateNumber = (value, min = null, max = null) => {
  if (value === null || value === undefined) return null;
  
  const num = typeof value === 'string' ? parseFloat(value) : value;
  
  if (isNaN(num)) return null;
  
  if (min !== null && num < min) return null;
  if (max !== null && num > max) return null;
  
  return num;
};

/**
 * Valida parámetros de ruta (req.params)
 */
const validateParams = (req, res, next) => {
  // Validar y sanitizar IDs en params
  if (req.params.id) {
    const sanitizedId = validateAndSanitizeId(req.params.id);
    if (!sanitizedId) {
      return res.status(400).json({
        success: false,
        error: 'ID inválido'
      });
    }
    req.params.id = sanitizedId;
  }
  
  // Validar otros parámetros comunes
  Object.keys(req.params).forEach(key => {
    if (key !== 'id' && req.params[key]) {
      req.params[key] = sanitizeString(String(req.params[key]));
    }
  });
  
  next();
};

/**
 * Valida query parameters (req.query)
 */
const validateQuery = (req, res, next) => {
  // Validar y sanitizar query params
  Object.keys(req.query).forEach(key => {
    const value = req.query[key];
    
    if (value === null || value === undefined) return;
    
    // Si es un ID, validar como número
    if (key.includes('id') || key.includes('Id') || key === 'user_id') {
      const sanitized = validateAndSanitizeId(value);
      if (sanitized) {
        req.query[key] = sanitized;
      } else {
        delete req.query[key];
      }
    } else if (key === 'email') {
      // Validar email
      const sanitized = sanitizeEmail(value);
      if (sanitized && validateEmail(sanitized)) {
        req.query[key] = sanitized;
      } else {
        delete req.query[key];
      }
    } else {
      // Sanitizar strings
      req.query[key] = sanitizeString(String(value));
    }
  });
  
  next();
};

/**
 * Valida body parameters (req.body)
 */
const validateBody = (req, res, next) => {
  if (!req.body || typeof req.body !== 'object') {
    return next();
  }
  
  // Validar y sanitizar body
  Object.keys(req.body).forEach(key => {
    const value = req.body[key];
    
    if (value === null || value === undefined) return;
    
    // Preservar supabase_auth_id sin modificar (es un UUID que no debe ser sanitizado)
    if (key === 'supabase_auth_id') {
      // Solo asegurar que sea string, sin sanitizar (UUID puede tener guiones)
      req.body[key] = String(value);
      // Salir temprano - no procesar este campo más
      return; // Esto sale de la función callback para esta iteración
    }
    
    // Validar emails
    if (key === 'email' || key.includes('email')) {
      const sanitized = sanitizeEmail(value);
      if (sanitized && validateEmail(sanitized)) {
        req.body[key] = sanitized;
      } else {
        req.body[key] = null; // Invalid email
      }
    }
    // Validar IDs (pero no UUIDs como supabase_auth_id)
    else if ((key.includes('id') || key.includes('Id') || key === 'user_id' || key === 'driver_id' || key === 'company_id') 
             && key !== 'supabase_auth_id') {
      const sanitized = validateAndSanitizeId(value);
      req.body[key] = sanitized;
    }
    // Validar números
    else if (typeof value === 'number' || (!isNaN(parseFloat(value)) && typeof value !== 'string')) {
      const sanitized = validateNumber(value);
      req.body[key] = sanitized;
    }
    // Sanitizar strings (pero NO supabase_auth_id que ya se preservó arriba)
    else if (typeof value === 'string' && key !== 'supabase_auth_id') {
      // Longitudes máximas según el campo
      let maxLength = 255;
      if (key === 'name' || key === 'nombre') maxLength = 100;
      if (key === 'password') maxLength = 500; // Para hashes
      if (key === 'description' || key === 'descripcion') maxLength = 1000;
      
      req.body[key] = validateAndSanitizeString(value, maxLength);
    }
  });
  
  next();
};

/**
 * Middleware combinado para validar params, query y body
 */
const validateAll = (req, res, next) => {
  validateParams(req, res, () => {
    validateQuery(req, res, () => {
      validateBody(req, res, next);
    });
  });
};

module.exports = {
  sanitizeString,
  validateAndSanitizeId,
  validateEmail,
  sanitizeEmail,
  validateAndSanitizeString,
  validateNumber,
  validateParams,
  validateQuery,
  validateBody,
  validateAll
};

