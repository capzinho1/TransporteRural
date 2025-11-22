const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const { validateAll, validateEmail, sanitizeEmail, validateAndSanitizeString } = require('../middleware/validation');
const { supabase } = require('../config/supabase');

// Crear cliente de Supabase Auth para las operaciones
const supabaseUrl = process.env.SUPABASE_URL || 'https://aghbbmbbfcgtpipnrjev.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY;

// Cliente de Supabase para autenticación
const supabaseAuth = createClient(supabaseUrl, supabaseKey);

// POST /api/auth/signup - Registrar usuario con email y password
router.post('/signup', validateAll, async (req, res) => {
  try {
    let { email, password, name, region } = req.body;

    // Validar campos obligatorios
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email y contraseña son requeridos'
      });
    }

    // Validar y sanitizar email
    email = sanitizeEmail(email);
    if (!email || !validateEmail(email)) {
      return res.status(400).json({
        success: false,
        error: 'Email inválido'
      });
    }

    // Validar longitud de password
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        error: 'La contraseña debe tener al menos 6 caracteres'
      });
    }

    // Sanitizar name y region
    if (name) {
      name = validateAndSanitizeString(name, 100, 1);
    }
    if (region) {
      region = validateAndSanitizeString(region, 100);
    }

    // Registrar en Supabase Auth
    const { data: authData, error: authError } = await supabaseAuth.auth.signUp({
      email: email,
      password: password,
      options: {
        data: {
          name: name || email.split('@')[0],
          region: region || null
        }
      }
    });

    if (authError) {
      console.error('❌ [AUTH_PROXY] Error al registrar en Supabase Auth:', authError);
      return res.status(400).json({
        success: false,
        error: 'Error al registrar usuario',
        message: authError.message
      });
    }

    if (!authData.user) {
      return res.status(400).json({
        success: false,
        error: 'Error al crear usuario'
      });
    }

    // Sincronizar con la tabla users usando el endpoint existente
    try {
      const syncResponse = await supabase
        .from('users')
        .select('*')
        .eq('supabase_auth_id', authData.user.id)
        .single();

      let usuario;
      if (!syncResponse.data) {
        // Crear usuario en la tabla users
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert([{
            email: email,
            name: name || email.split('@')[0],
            role: 'user',
            auth_provider: 'supabase',
            supabase_auth_id: authData.user.id,
            region: region || null,
            active: true
          }])
          .select()
          .single();

        if (createError) throw createError;
        usuario = newUser;
      } else {
        usuario = syncResponse.data;
      }

      // Remover password del objeto
      const { password: _, ...usuarioSinPassword } = usuario;

      res.status(201).json({
        success: true,
        data: {
          user: authData.user,
          session: authData.session,
          usuario: usuarioSinPassword
        },
        message: 'Usuario registrado exitosamente'
      });
    } catch (syncError) {
      console.error('❌ [AUTH_PROXY] Error al sincronizar usuario:', syncError);
      // Aunque falle la sincronización, devolvemos los datos de Supabase Auth
      res.status(201).json({
        success: true,
        data: {
          user: authData.user,
          session: authData.session
        },
        message: 'Usuario registrado en Supabase Auth, pero hubo un error al sincronizar con la tabla users'
      });
    }
  } catch (error) {
    console.error('❌ [AUTH_PROXY] Error en signup:', error);
    res.status(500).json({
      success: false,
      error: 'Error al registrar usuario',
      message: error.message
    });
  }
});

// POST /api/auth/signin - Iniciar sesión con email y password
router.post('/signin', validateAll, async (req, res) => {
  try {
    let { email, password } = req.body;

    // Validar campos obligatorios
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email y contraseña son requeridos'
      });
    }

    // Validar y sanitizar email
    email = sanitizeEmail(email);
    if (!email || !validateEmail(email)) {
      return res.status(400).json({
        success: false,
        error: 'Email inválido'
      });
    }

    // Autenticar con Supabase Auth
    const { data: authData, error: authError } = await supabaseAuth.auth.signInWithPassword({
      email: email,
      password: password
    });

    if (authError || !authData.user) {
      console.error('❌ [AUTH_PROXY] Error al autenticar:', authError?.message);
      return res.status(401).json({
        success: false,
        error: 'Credenciales inválidas',
        message: 'Email o contraseña incorrectos'
      });
    }

    // Obtener usuario de la tabla users
    try {
      const { data: usuario, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('supabase_auth_id', authData.user.id)
        .single();

      if (userError && userError.code !== 'PGRST116') {
        console.error('❌ [AUTH_PROXY] Error al obtener usuario:', userError);
      }

      // Si no existe, crearlo
      if (!usuario || userError?.code === 'PGRST116') {
        const emailName = authData.user.email?.split('@')[0] || 'Usuario';
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert([{
            email: authData.user.email,
            name: authData.user.user_metadata?.name || emailName,
            role: 'user',
            auth_provider: 'supabase',
            supabase_auth_id: authData.user.id,
            region: authData.user.user_metadata?.region || null,
            active: true
          }])
          .select()
          .single();

        if (createError) {
          console.error('❌ [AUTH_PROXY] Error al crear usuario:', createError);
          // Continuar sin el usuario
        }

        const { password: _, ...usuarioSinPassword } = newUser || {};

        return res.json({
          success: true,
          data: {
            user: authData.user,
            session: authData.session,
            usuario: usuarioSinPassword
          },
          message: 'Login exitoso'
        });
      }

      // Remover password del objeto
      const { password: _, ...usuarioSinPassword } = usuario;

      res.json({
        success: true,
        data: {
          user: authData.user,
          session: authData.session,
          usuario: usuarioSinPassword
        },
        message: 'Login exitoso'
      });
    } catch (userError) {
      console.error('❌ [AUTH_PROXY] Error al procesar usuario:', userError);
      // Aunque falle obtener el usuario, devolvemos los datos de Supabase Auth
      res.json({
        success: true,
        data: {
          user: authData.user,
          session: authData.session
        },
        message: 'Login exitoso'
      });
    }
  } catch (error) {
    console.error('❌ [AUTH_PROXY] Error en signin:', error);
    res.status(500).json({
      success: false,
      error: 'Error al iniciar sesión',
      message: error.message
    });
  }
});

// POST /api/auth/signout - Cerrar sesión
router.post('/signout', async (req, res) => {
  try {
    // Si hay un token de sesión en el header, intentar cerrar esa sesión
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      // Usar el token para cerrar sesión en Supabase
      await supabaseAuth.auth.signOut();
    }

    res.json({
      success: true,
      message: 'Sesión cerrada exitosamente'
    });
  } catch (error) {
    console.error('❌ [AUTH_PROXY] Error en signout:', error);
    res.status(500).json({
      success: false,
      error: 'Error al cerrar sesión',
      message: error.message
    });
  }
});

// GET /api/auth/session - Obtener sesión actual
router.get('/session', async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'No autorizado',
        message: 'Token de autenticación requerido'
      });
    }

    const token = authHeader.substring(7);
    
    // Verificar el token con Supabase
    const { data: { user }, error } = await supabaseAuth.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({
        success: false,
        error: 'Token inválido',
        message: 'La sesión ha expirado o no es válida'
      });
    }

    // Obtener usuario de la tabla users
    const { data: usuario, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('supabase_auth_id', user.id)
      .single();

    if (userError) {
      console.error('❌ [AUTH_PROXY] Error al obtener usuario:', userError);
    }

    if (usuario) {
      const { password: _, ...usuarioSinPassword } = usuario;
      return res.json({
        success: true,
        data: {
          user: user,
          usuario: usuarioSinPassword
        }
      });
    }

    res.json({
      success: true,
      data: {
        user: user
      }
    });
  } catch (error) {
    console.error('❌ [AUTH_PROXY] Error al obtener sesión:', error);
    res.status(500).json({
      success: false,
      error: 'Error al obtener sesión',
      message: error.message
    });
  }
});

// GET /api/auth/oauth/google/authorize - Generar URL de OAuth de Google
router.get('/oauth/google/authorize', async (req, res) => {
  try {
    const isWeb = req.query.platform === 'web';
    
    // Para móvil, el redirectTo debe ser el deep link de la app
    // Para web, usar el redirectTo del cliente
    const finalRedirectTo = isWeb
      ? (req.query.redirectTo || req.query.finalRedirectTo || 'http://localhost:8080/')
      : (req.query.finalRedirectTo || 'com.georu.app://login-callback');
    
    console.log('🔐 [AUTH_PROXY] Generando URL OAuth de Google');
    console.log('🔐 [AUTH_PROXY] Platform:', isWeb ? 'web' : 'mobile');
    console.log('🔐 [AUTH_PROXY] Final redirectTo (donde Supabase redirigirá después del callback):', finalRedirectTo);
    console.log('🔐 [AUTH_PROXY] Supabase URL:', supabaseUrl);
    
    // Generar la URL de OAuth de Supabase
    // El redirectTo debe ser el deep link de la app para móvil
    // Supabase redirigirá a este deep link después de procesar el callback de Google
    const { data, error } = await supabaseAuth.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: finalRedirectTo, // Para móvil: deep link de la app, para web: URL de la app web
        queryParams: {
          prompt: 'select_account',
        },
        skipBrowserRedirect: true // No redirigir automáticamente, solo obtener la URL
      }
    });

    if (error || !data?.url) {
      console.error('❌ [AUTH_PROXY] Error al generar URL OAuth:', error);
      return res.status(500).json({
        success: false,
        error: 'Error al generar URL de autenticación',
        message: error?.message || 'No se pudo generar la URL OAuth'
      });
    }

    // Parsear la URL generada para verificar el redirect_uri que Supabase está enviando a Google
    const oauthUrlObj = new URL(data.url);
    const redirectUriParam = oauthUrlObj.searchParams.get('redirect_uri');
    console.log('🔍 [AUTH_PROXY] Redirect URI que Supabase está enviando a Google:', redirectUriParam);
    
    // Si el redirect_uri no es el callback de Supabase, hay un problema de configuración
    const expectedCallback = 'https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback';
    if (redirectUriParam && !redirectUriParam.includes('/auth/v1/callback')) {
      console.error('⚠️ [AUTH_PROXY] ADVERTENCIA: El redirect_uri no apunta al callback de Supabase');
      console.error('⚠️ [AUTH_PROXY] Redirect URI recibido:', redirectUriParam);
      console.error('⚠️ [AUTH_PROXY] Redirect URI esperado:', expectedCallback);
      console.error('⚠️ [AUTH_PROXY] Esto indica que el Site URL en Supabase Dashboard está mal configurado');
    }

    // Modificar la URL para incluir el finalRedirectTo como parámetro de query
    // Esto nos permitirá recuperarlo después en el callback
    const oauthUrl = new URL(data.url);
    oauthUrl.searchParams.set('final_redirect_to', finalRedirectTo);

    console.log('✅ [AUTH_PROXY] URL OAuth generada exitosamente');
    console.log('🔐 [AUTH_PROXY] URL completa:', oauthUrl.toString());

    res.json({
      success: true,
      data: {
        url: oauthUrl.toString(),
        finalRedirectTo: finalRedirectTo
      },
      message: 'URL de autenticación generada exitosamente'
    });
  } catch (error) {
    console.error('❌ [AUTH_PROXY] Error en OAuth authorize:', error);
    res.status(500).json({
      success: false,
      error: 'Error al generar URL de autenticación',
      message: error.message
    });
  }
});

// GET /api/auth/oauth/google/callback - Callback de OAuth de Google
// Este endpoint recibe el código de autorización después de que el usuario autentica
router.get('/oauth/google/callback', async (req, res) => {
  try {
    const { code, state, error: oauthError } = req.query;

    if (oauthError) {
      console.error('❌ [AUTH_PROXY] Error en OAuth callback:', oauthError);
      return res.redirect(`com.georu.app://login-callback?error=${encodeURIComponent(oauthError)}`);
    }

    if (!code) {
      console.error('❌ [AUTH_PROXY] No se recibió código de autorización');
      return res.redirect(`com.georu.app://login-callback?error=${encodeURIComponent('No se recibió código de autorización')}`);
    }

    console.log('✅ [AUTH_PROXY] Código de autorización recibido');
    console.log('🔐 [AUTH_PROXY] State:', state);

    // Intercambiar el código por una sesión con Supabase
    const { data: sessionData, error: sessionError } = await supabaseAuth.auth.exchangeCodeForSession(code);

    if (sessionError || !sessionData.session) {
      console.error('❌ [AUTH_PROXY] Error al intercambiar código por sesión:', sessionError);
      return res.redirect(`com.georu.app://login-callback?error=${encodeURIComponent(sessionError?.message || 'Error al obtener sesión')}`);
    }

    const { session, user } = sessionData;
    console.log('✅ [AUTH_PROXY] Sesión obtenida exitosamente');
    console.log('🔐 [AUTH_PROXY] User ID:', user.id);

    // Sincronizar usuario con la tabla users
    try {
      const { data: existingUser } = await supabase
        .from('users')
        .select('*')
        .eq('supabase_auth_id', user.id)
        .single();

      if (!existingUser) {
        // Crear usuario en la tabla users
        const emailName = user.email?.split('@')[0] || 'Usuario';
        const userName = user.user_metadata?.name || 
                        user.user_metadata?.full_name || 
                        emailName;

        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert([{
            email: user.email,
            name: userName,
            role: 'user',
            auth_provider: 'google',
            supabase_auth_id: user.id,
            region: user.user_metadata?.region || null,
            active: true
          }])
          .select()
          .single();

        if (createError) {
          console.error('⚠️ [AUTH_PROXY] Error al crear usuario:', createError);
          // Continuar de todas formas, el usuario está autenticado en Supabase
        } else {
          console.log('✅ [AUTH_PROXY] Usuario sincronizado exitosamente');
        }
      } else {
        console.log('✅ [AUTH_PROXY] Usuario ya existe en la base de datos');
      }
    } catch (syncError) {
      console.error('⚠️ [AUTH_PROXY] Error al sincronizar usuario:', syncError);
      // Continuar de todas formas
    }

    // Redirigir a la app móvil con el token de acceso
    // La app móvil capturará este deep link y procesará la sesión
    const accessToken = session.access_token;
    const refreshToken = session.refresh_token;
    
    // Redirigir a la app con los tokens codificados
    const redirectUrl = `com.georu.app://login-callback?access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}&user_id=${encodeURIComponent(user.id)}`;
    
    console.log('✅ [AUTH_PROXY] Redirigiendo a la app móvil');
    res.redirect(redirectUrl);
  } catch (error) {
    console.error('❌ [AUTH_PROXY] Error en OAuth callback:', error);
    res.redirect(`com.georu.app://login-callback?error=${encodeURIComponent(error.message)}`);
  }
});

module.exports = router;

