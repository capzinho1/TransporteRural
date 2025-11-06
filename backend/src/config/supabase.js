// Configuración de Supabase
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || 'https://aghbbmbbfcgtpipnrjev.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY;

if (!supabaseKey) {
  console.error('⚠️  SUPABASE_KEY no está configurada');
  console.error('⚠️  Por favor, configura SUPABASE_KEY en el archivo .env');
}

console.log('📊 Configuración Supabase:');
console.log('   URL:', supabaseUrl);
console.log('   Key:', supabaseKey ? `${supabaseKey.substring(0, 20)}...` : 'NO CONFIGURADA');

// Cliente de Supabase
const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: false
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
});

// Verificar conexión
const testConnection = async () => {
  try {
    const { data, error } = await supabase.from('users').select('count');
    if (error) throw error;
    console.log('✅ Conexión a Supabase establecida');
    return true;
  } catch (error) {
    console.error('❌ Error conectando a Supabase:', error.message);
    return false;
  }
};

module.exports = {
  supabase,
  testConnection
};

