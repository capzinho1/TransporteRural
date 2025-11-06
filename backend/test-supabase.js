// Script de prueba para verificar conexión a Supabase
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

console.log('🔍 Verificando configuración de Supabase...\n');

// Verificar variables de entorno
console.log('1. Variables de Entorno:');
console.log('   SUPABASE_URL:', supabaseUrl || '❌ NO CONFIGURADA');
console.log('   SUPABASE_KEY:', supabaseKey ? `✅ Configurada (${supabaseKey.substring(0, 20)}...)` : '❌ NO CONFIGURADA');
console.log('');

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Error: Falta configurar SUPABASE_URL o SUPABASE_KEY en el archivo .env');
  console.log('\nCrea el archivo backend/.env con:');
  console.log('SUPABASE_URL=https://tu-proyecto.supabase.co');
  console.log('SUPABASE_KEY=tu_anon_key_aqui');
  process.exit(1);
}

// Crear cliente
const supabase = createClient(supabaseUrl, supabaseKey);

// Función de prueba
async function testConnection() {
  console.log('2. Probando conexión a Supabase...');
  
  try {
    // Test 1: Verificar tabla users
    console.log('\n   Test 1: Consultando tabla "users"...');
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id, email, name, role')
      .limit(5);
    
    if (usersError) {
      console.error('   ❌ Error:', usersError.message);
      console.error('   Detalles:', usersError.details || usersError.hint);
    } else {
      console.log(`   ✅ Usuarios encontrados: ${users.length}`);
      users.forEach(u => console.log(`      - ${u.email} (${u.role})`));
    }
    
    // Test 2: Verificar tabla routes
    console.log('\n   Test 2: Consultando tabla "routes"...');
    const { data: routes, error: routesError } = await supabase
      .from('routes')
      .select('route_id, name')
      .limit(5);
    
    if (routesError) {
      console.error('   ❌ Error:', routesError.message);
      console.error('   Detalles:', routesError.details || routesError.hint);
    } else {
      console.log(`   ✅ Rutas encontradas: ${routes.length}`);
      routes.forEach(r => console.log(`      - ${r.route_id}: ${r.name}`));
    }
    
    // Test 3: Verificar tabla bus_locations
    console.log('\n   Test 3: Consultando tabla "bus_locations"...');
    const { data: buses, error: busesError } = await supabase
      .from('bus_locations')
      .select('id, bus_id, status')
      .limit(5);
    
    if (busesError) {
      console.error('   ❌ Error:', busesError.message);
      console.error('   Detalles:', busesError.details || busesError.hint);
    } else {
      console.log(`   ✅ Buses encontrados: ${buses.length}`);
      buses.forEach(b => console.log(`      - ${b.bus_id} (${b.status})`));
    }
    
    console.log('\n✅ Conexión a Supabase exitosa!');
    
  } catch (error) {
    console.error('\n❌ Error general:', error.message);
    console.error(error);
  }
}

testConnection();


