/**
 * Script simplificado para ejecutar los tests
 * 
 * Uso:
 *   node tests/run_tests.js --driver-id 21
 *   node tests/run_tests.js --driver-id 21 --user-id 1 --company-id 1
 */

const { runTests } = require('./test_dashboard_improvements');

// Leer argumentos de línea de comandos
const args = process.argv.slice(2);
let testUserId = null;
let testCompanyId = null;
let testDriverId = null;

// Parsear argumentos
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--user-id' && args[i + 1]) {
    testUserId = parseInt(args[i + 1]);
  } else if (args[i] === '--company-id' && args[i + 1]) {
    testCompanyId = parseInt(args[i + 1]);
  } else if (args[i] === '--driver-id' && args[i + 1]) {
    testDriverId = parseInt(args[i + 1]);
  }
}

// También leer de variables de entorno
testUserId = testUserId || (process.env.TEST_USER_ID ? parseInt(process.env.TEST_USER_ID) : null);
testCompanyId = testCompanyId || (process.env.TEST_COMPANY_ID ? parseInt(process.env.TEST_COMPANY_ID) : null);
testDriverId = testDriverId || (process.env.TEST_DRIVER_ID ? parseInt(process.env.TEST_DRIVER_ID) : null);

// Si no se proporcionó driver-id, mostrar ayuda
if (!testDriverId) {
  console.log('\n❌ ERROR: Se requiere --driver-id');
  console.log('\n📝 Uso:');
  console.log('   node tests/run_tests.js --driver-id 21');
  console.log('   node tests/run_tests.js --driver-id 21 --user-id 1 --company-id 1');
  console.log('\n💡 O con variables de entorno:');
  console.log('   TEST_DRIVER_ID=21 TEST_USER_ID=1 TEST_COMPANY_ID=1 node tests/run_tests.js');
  process.exit(1);
}

// Si faltan otros IDs, intentar obtenerlos automáticamente
if (!testUserId || !testCompanyId) {
  console.log('\n⚠️  Intentando obtener IDs automáticamente...\n');
  
  const http = require('http');
  
  // Función para obtener usuarios
  function getUsers() {
    return new Promise((resolve, reject) => {
      http.get('http://localhost:3000/api/users', {
        headers: { 'Content-Type': 'application/json' }
      }, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve(response.data || []);
          } catch (e) {
            reject(e);
          }
        });
      }).on('error', reject);
    });
  }
  
  // Intentar obtener IDs
  getUsers()
    .then(users => {
      // Buscar admin
      if (!testUserId) {
        const admin = users.find(u => 
          u.role === 'super_admin' || u.role === 'company_admin'
        );
        if (admin) {
          testUserId = admin.id;
          console.log(`✅ User ID (Admin) encontrado: ${testUserId} (${admin.name})`);
        }
      }
      
      // Buscar company_id del conductor o de un admin
      if (!testCompanyId) {
        const driver = users.find(u => u.id === testDriverId);
        if (driver && driver.company_id) {
          testCompanyId = driver.company_id;
          console.log(`✅ Company ID encontrado: ${testCompanyId} (del conductor)`);
        } else {
          const admin = users.find(u => 
            (u.role === 'super_admin' || u.role === 'company_admin') && u.company_id
          );
          if (admin && admin.company_id) {
            testCompanyId = admin.company_id;
            console.log(`✅ Company ID encontrado: ${testCompanyId} (del admin)`);
          }
        }
      }
      
      // Verificar que tenemos todo
      if (!testUserId || !testCompanyId) {
        console.log('\n❌ No se pudieron obtener todos los IDs automáticamente');
        console.log('\n📝 Por favor, proporciona los IDs faltantes:');
        if (!testUserId) console.log('   --user-id <ID>');
        if (!testCompanyId) console.log('   --company-id <ID>');
        process.exit(1);
      }
      
      // Configurar variables globales en el módulo de tests
      const testModule = require('./test_dashboard_improvements');
      testModule.setTestIds(testUserId, testCompanyId, testDriverId);
      
      // Ejecutar tests
      runTests();
    })
    .catch(error => {
      console.log(`\n❌ Error al obtener IDs: ${error.message}`);
      console.log('\n💡 Asegúrate de que:');
      console.log('   1. El backend esté corriendo en http://localhost:3000');
      console.log('   2. Proporciones los IDs manualmente:');
      console.log('      node tests/run_tests.js --driver-id 21 --user-id <ID> --company-id <ID>');
      process.exit(1);
    });
} else {
  // Ya tenemos todos los IDs, ejecutar directamente
  const testModule = require('./test_dashboard_improvements');
  testModule.setTestIds(testUserId, testCompanyId, testDriverId);
  runTests();
}

