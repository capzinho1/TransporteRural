/**
 * Tests automatizados para las mejoras del dashboard y asignaciones
 * 
 * Ejecutar con: node tests/test_dashboard_improvements.js
 * 
 * Requisitos:
 * - Backend corriendo en http://localhost:3000
 * - Base de datos configurada
 * - Variables de entorno configuradas
 */

const http = require('http');

const BASE_URL = 'http://localhost:3000/api';
let testResults = [];
let testCount = 0;
let passCount = 0;
let failCount = 0;

// Colores para la consola
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTest(name) {
  testCount++;
  log(`\n[TEST ${testCount}] ${name}`, 'cyan');
}

function logPass(message) {
  passCount++;
  log(`  ✅ PASS: ${message}`, 'green');
}

function logFail(message, error = null) {
  failCount++;
  log(`  ❌ FAIL: ${message}`, 'red');
  if (error) {
    log(`     Error: ${error}`, 'red');
  }
}

function logInfo(message) {
  log(`  ℹ️  INFO: ${message}`, 'blue');
}

// Helper para hacer requests HTTP
function makeRequest(method, path, data = null, headers = {}) {
  return new Promise((resolve, reject) => {
    // Construir URL completa
    const fullPath = path.startsWith('/') ? path : `/${path}`;
    const fullUrl = `${BASE_URL}${fullPath}`;
    const url = new URL(fullUrl);
    
    const options = {
      hostname: url.hostname || 'localhost',
      port: url.port || 3000,
      path: url.pathname + (url.search || ''),
      method,
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = body ? JSON.parse(body) : {};
          resolve({
            statusCode: res.statusCode,
            body: parsed,
            headers: res.headers,
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            body: body,
            headers: res.headers,
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// Variables globales para almacenar datos de prueba
let testRouteId = null;
let testBusId = null;
let testDriverId = null;
let testCompanyId = null;
let testUserId = null;

// Función para configurar los IDs desde fuera del módulo
function setTestIds(userId, companyId, driverId) {
  testUserId = userId;
  testCompanyId = companyId;
  testDriverId = driverId;
}

/**
 * PRUEBA 1: Verificar sincronización de nombreRuta
 */
async function testNombreRutaSync() {
  logTest('Sincronización de nombreRuta al asignar bus a ruta');

  try {
    // 1. Crear una ruta de prueba
    logInfo('Creando ruta de prueba...');
    const routeName = `Test Ruta ${Date.now()}`;
    const routeResponse = await makeRequest('POST', '/routes', {
      route_id: `TEST_ROUTE_${Date.now()}`,
      name: routeName,
      company_id: testCompanyId,
      active: true,
    }, {
      'x-user-id': testUserId,
    });

    if (routeResponse.statusCode !== 201) {
      logFail('No se pudo crear ruta de prueba', JSON.stringify(routeResponse.body, null, 2));
      logInfo(`Status Code: ${routeResponse.statusCode}`);
      return false;
    }

    testRouteId = routeResponse.body.data?.route_id;
    logInfo(`Ruta creada: ${testRouteId}`);

    // 2. Crear un bus de prueba
    logInfo('Creando bus de prueba...');
    const busResponse = await makeRequest('POST', '/bus-locations', {
      bus_id: `TEST_BUS_${Date.now()}`,
      latitude: -35.4264,
      longitude: -71.6554,
      status: 'inactive',
      company_id: testCompanyId,
    }, {
      'x-user-id': testUserId,
    });

    if (busResponse.statusCode !== 201) {
      logFail('No se pudo crear bus de prueba', JSON.stringify(busResponse.body, null, 2));
      logInfo(`Status Code: ${busResponse.statusCode}`);
      return false;
    }

    testBusId = busResponse.body.data?.id;
    const testBusBusId = busResponse.body.data?.bus_id;
    logInfo(`Bus creado: ${testBusBusId} (ID: ${testBusId})`);

    // 3. Asignar bus a ruta (el backend sincronizará nombre_ruta automáticamente)
    logInfo('Asignando bus a ruta...');
    logInfo(`Usando User ID: ${testUserId}, Company ID: ${testCompanyId}`);
    
    const assignResponse = await makeRequest('PUT', `/bus-locations/${testBusId}`, {
      route_id: testRouteId,
      // No enviar nombre_ruta, el backend debe sincronizarlo automáticamente
    }, {
      'x-user-id': testUserId,
    });

    if (assignResponse.statusCode !== 200) {
      logFail('No se pudo asignar bus a ruta', JSON.stringify(assignResponse.body, null, 2));
      logInfo(`Status Code: ${assignResponse.statusCode}`);
      logInfo(`Request: PUT /bus-locations/${testBusId} con route_id=${testRouteId}`);
      logInfo(`⚠️  Si el error es 403, verifica que el usuario tenga permisos o sea super_admin`);
      return false;
    }
    
    logInfo('Bus asignado exitosamente, esperando sincronización de nombre_ruta...');

    // 4. Verificar que nombre_ruta se sincronizó
    logInfo('Verificando sincronización de nombre_ruta...');
    const verifyResponse = await makeRequest('GET', `/bus-locations/${testBusId}`, null, {
      'x-user-id': testUserId,
    });

    if (verifyResponse.statusCode !== 200) {
      logFail('No se pudo verificar bus', verifyResponse.body);
      return false;
    }

    const busData = verifyResponse.body.data;
    if (busData.nombre_ruta === routeName) {
      logPass(`nombre_ruta sincronizado correctamente: "${busData.nombre_ruta}"`);
      return true;
    } else {
      logFail(`nombre_ruta no sincronizado. Esperado: "${routeName}", Obtenido: "${busData.nombre_ruta}"`);
      return false;
    }
  } catch (error) {
    logFail('Error en prueba de sincronización', error.message);
    return false;
  }
}

/**
 * PRUEBA 2: Verificar actualización del estado del conductor
 */
async function testDriverStatusUpdate() {
  logTest('Actualización del estado del conductor al asignar/desasignar');

  try {
    // 1. Verificar estado inicial del conductor
    logInfo('Verificando estado inicial del conductor...');
    const initialDriverResponse = await makeRequest('GET', `/users/${testDriverId}`, null, {
      'x-user-id': testUserId,
    });

    if (initialDriverResponse.statusCode !== 200) {
      logFail('No se pudo obtener conductor', JSON.stringify(initialDriverResponse.body, null, 2));
      logInfo(`Status Code: ${initialDriverResponse.statusCode}`);
      logInfo(`Endpoint usado: GET /users/${testDriverId}`);
      return false;
    }

    const initialStatus = initialDriverResponse.body.data?.driver_status;
    logInfo(`Estado inicial del conductor: ${initialStatus || 'null'}`);

    // 2. Asignar conductor a bus
    logInfo('Asignando conductor a bus...');
    const assignResponse = await makeRequest('PUT', `/bus-locations/${testBusId}`, {
      driver_id: testDriverId,
    }, {
      'x-user-id': testUserId,
    });

    if (assignResponse.statusCode !== 200) {
      logFail('No se pudo asignar conductor', JSON.stringify(assignResponse.body, null, 2));
      logInfo(`Status Code: ${assignResponse.statusCode}`);
      logInfo(`Request: PUT /bus-locations/${testBusId} con driver_id=${testDriverId}`);
      return false;
    }

    // 3. Verificar que el estado cambió a 'en_ruta'
    logInfo('Verificando cambio de estado a "en_ruta"...');
    await new Promise(resolve => setTimeout(resolve, 500)); // Esperar un poco

    const driverAfterAssign = await makeRequest('GET', `/users/${testDriverId}`, null, {
      'x-user-id': testUserId,
    });

    if (driverAfterAssign.statusCode !== 200) {
      logFail('No se pudo verificar estado del conductor', driverAfterAssign.body);
      return false;
    }

    const statusAfterAssign = driverAfterAssign.body.data?.driver_status;
    if (statusAfterAssign === 'en_ruta') {
      logPass(`Estado del conductor actualizado a "en_ruta"`);
    } else {
      logFail(`Estado del conductor no actualizado. Esperado: "en_ruta", Obtenido: "${statusAfterAssign}"`);
      return false;
    }

    // 4. Desasignar conductor
    logInfo('Desasignando conductor...');
    const unassignResponse = await makeRequest('PUT', `/bus-locations/${testBusId}`, {
      driver_id: null,
    }, {
      'x-user-id': testUserId,
    });

    if (unassignResponse.statusCode !== 200) {
      logFail('No se pudo desasignar conductor', unassignResponse.body);
      return false;
    }

    // 5. Verificar que el estado cambió a 'disponible'
    logInfo('Verificando cambio de estado a "disponible"...');
    await new Promise(resolve => setTimeout(resolve, 500)); // Esperar un poco

    const driverAfterUnassign = await makeRequest('GET', `/users/${testDriverId}`, null, {
      'x-user-id': testUserId,
    });

    if (driverAfterUnassign.statusCode !== 200) {
      logFail('No se pudo verificar estado del conductor', driverAfterUnassign.body);
      return false;
    }

    const statusAfterUnassign = driverAfterUnassign.body.data?.driver_status;
    if (statusAfterUnassign === 'disponible') {
      logPass(`Estado del conductor actualizado a "disponible"`);
      return true;
    } else {
      logFail(`Estado del conductor no actualizado. Esperado: "disponible", Obtenido: "${statusAfterUnassign}"`);
      return false;
    }
  } catch (error) {
    logFail('Error en prueba de estado del conductor', error.message);
    return false;
  }
}

/**
 * PRUEBA 3: Verificar validación antes de eliminar rutas
 */
async function testRouteDeletionValidation() {
  logTest('Validación antes de eliminar rutas con buses asignados');

  try {
    // 1. Intentar eliminar ruta con bus asignado
    logInfo('Intentando eliminar ruta con bus asignado...');
    const deleteResponse = await makeRequest('DELETE', `/routes/${testRouteId}`, null, {
      'x-user-id': testUserId,
    });

    if (deleteResponse.statusCode === 400) {
      logPass('Backend correctamente rechaza eliminar ruta con buses asignados');
      logInfo(`Mensaje: ${deleteResponse.body.message || deleteResponse.body.error}`);
      return true;
    } else if (deleteResponse.statusCode === 200) {
      logFail('Backend permitió eliminar ruta con buses asignados (no debería)');
      logInfo(`Respuesta: ${JSON.stringify(deleteResponse.body, null, 2)}`);
      return false;
    } else {
      logFail(`Respuesta inesperada: ${deleteResponse.statusCode}`, JSON.stringify(deleteResponse.body, null, 2));
      return false;
    }
  } catch (error) {
    logFail('Error en prueba de validación de eliminación', error.message);
    return false;
  }
}

/**
 * PRUEBA 4: Verificar múltiples buses por ruta
 */
async function testMultipleBusesPerRoute() {
  logTest('Múltiples buses por ruta');

  try {
    // 1. Crear segundo bus
    logInfo('Creando segundo bus de prueba...');
    const bus2Response = await makeRequest('POST', '/bus-locations', {
      bus_id: `TEST_BUS_2_${Date.now()}`,
      latitude: -35.4264,
      longitude: -71.6554,
      status: 'inactive',
      company_id: testCompanyId,
    }, {
      'x-user-id': testUserId,
    });

    if (bus2Response.statusCode !== 201) {
      logFail('No se pudo crear segundo bus', bus2Response.body);
      return false;
    }

    const bus2Id = bus2Response.body.data?.id;
    logInfo(`Segundo bus creado: ${bus2Response.body.data?.bus_id} (ID: ${bus2Id})`);

    // 2. Asignar segundo bus a la misma ruta
    logInfo('Asignando segundo bus a la misma ruta...');
    const assignResponse = await makeRequest('PUT', `/bus-locations/${bus2Id}`, {
      route_id: testRouteId,
      nombre_ruta: `Test Ruta ${Date.now()}`, // Nombre de la ruta
    }, {
      'x-user-id': testUserId,
    });

    if (assignResponse.statusCode !== 200) {
      logFail('No se pudo asignar segundo bus', JSON.stringify(assignResponse.body, null, 2));
      logInfo(`Status Code: ${assignResponse.statusCode}`);
      return false;
    }

    // 3. Verificar que ambos buses están asignados a la ruta
    logInfo('Verificando que ambos buses están asignados...');
    const busesResponse = await makeRequest('GET', '/bus-locations', null, {
      'x-user-id': testUserId,
    });

    if (busesResponse.statusCode !== 200) {
      logFail('No se pudieron obtener buses', busesResponse.body);
      return false;
    }

    const buses = busesResponse.body.data || [];
    const busesInRoute = buses.filter(b => b.route_id === testRouteId);

    if (busesInRoute.length >= 2) {
      logPass(`Múltiples buses asignados correctamente: ${busesInRoute.length} buses en la ruta`);
      return true;
    } else {
      logFail(`No se encontraron múltiples buses. Encontrados: ${busesInRoute.length}`);
      return false;
    }
  } catch (error) {
    logFail('Error en prueba de múltiples buses', error.message);
    return false;
  }
}

/**
 * PRUEBA 5: Limpiar datos de prueba
 */
async function cleanupTestData() {
  logTest('Limpieza de datos de prueba');

  try {
    // Desasignar buses
    if (testBusId) {
      logInfo('Desasignando buses...');
      await makeRequest('PUT', `/bus-locations/${testBusId}`, {
        route_id: null,
        driver_id: null,
        nombre_ruta: null,
      }, {
        'x-user-id': testUserId,
      });
    }

    // Eliminar buses de prueba
    logInfo('Eliminando buses de prueba...');
    const busesResponse = await makeRequest('GET', '/bus-locations', null, {
      'x-user-id': testUserId,
    });

    if (busesResponse.statusCode === 200) {
      const buses = busesResponse.body.data || [];
      const testBuses = buses.filter(b => 
        b.bus_id?.startsWith('TEST_BUS') || b.id === testBusId
      );

      for (const bus of testBuses) {
        await makeRequest('DELETE', `/bus-locations/${bus.id}`, null, {
          'x-user-id': testUserId,
        });
      }
    }

    // Eliminar ruta de prueba (después de desasignar)
    if (testRouteId) {
      logInfo('Eliminando ruta de prueba...');
      // Primero intentar desasignar todo
      const busesResponse = await makeRequest('GET', '/bus-locations', null, {
        'x-user-id': testUserId,
      });

      if (busesResponse.statusCode === 200) {
        const buses = busesResponse.body.data || [];
        const busesInRoute = buses.filter(b => b.route_id === testRouteId);

        for (const bus of busesInRoute) {
          await makeRequest('PUT', `/bus-locations/${bus.id}`, {
            route_id: null,
            nombre_ruta: null,
          }, {
            'x-user-id': testUserId,
          });
        }
      }

      // Ahora eliminar la ruta
      await makeRequest('DELETE', `/routes/${testRouteId}`, null, {
        'x-user-id': testUserId,
      });
    }

    logPass('Datos de prueba limpiados');
    return true;
  } catch (error) {
    logFail('Error al limpiar datos de prueba', error.message);
    return false;
  }
}

/**
 * Función principal
 */
async function runTests() {
  log('\n' + '='.repeat(60), 'blue');
  log('🧪 INICIANDO TESTS AUTOMATIZADOS', 'cyan');
  log('='.repeat(60) + '\n', 'blue');

  // NOTA: Estas variables deben ser configuradas con valores reales
  // Por ahora, el usuario debe proporcionarlas
  log('⚠️  IMPORTANTE: Debes configurar las siguientes variables:', 'yellow');
  log('   - testUserId: ID de un usuario admin válido', 'yellow');
  log('   - testCompanyId: ID de una empresa válida', 'yellow');
  log('   - testDriverId: ID de un conductor válido', 'yellow');
  log('', 'yellow');

  // Estas variables deben ser proporcionadas por el usuario
  // Por ahora, las dejamos como null para que el usuario las configure
  if (!testUserId || !testCompanyId || !testDriverId) {
    log('❌ ERROR: Variables de prueba no configuradas', 'red');
    log('   Por favor, edita este archivo y configura:', 'red');
    log('   - testUserId', 'red');
    log('   - testCompanyId', 'red');
    log('   - testDriverId', 'red');
    log('\n   O ejecuta: node tests/test_dashboard_improvements.js --setup', 'yellow');
    return;
  }

  try {
    // Ejecutar pruebas
    const results = [];

    results.push(await testNombreRutaSync());
    results.push(await testDriverStatusUpdate());
    results.push(await testRouteDeletionValidation());
    results.push(await testMultipleBusesPerRoute());

    // Limpiar
    await cleanupTestData();

    // Resumen
    log('\n' + '='.repeat(60), 'blue');
    log('📊 RESUMEN DE TESTS', 'cyan');
    log('='.repeat(60), 'blue');
    log(`Total de tests: ${testCount}`, 'blue');
    log(`✅ Pasados: ${passCount}`, 'green');
    log(`❌ Fallidos: ${failCount}`, 'red');
    log(`Porcentaje de éxito: ${((passCount / testCount) * 100).toFixed(1)}%`, 
        passCount === testCount ? 'green' : 'yellow');
    log('='.repeat(60) + '\n', 'blue');

    if (failCount === 0) {
      log('🎉 ¡TODOS LOS TESTS PASARON!', 'green');
      process.exit(0);
    } else {
      log('⚠️  ALGUNOS TESTS FALLARON', 'yellow');
      process.exit(1);
    }
  } catch (error) {
    log(`\n❌ ERROR CRÍTICO: ${error.message}`, 'red');
    console.error(error);
    process.exit(1);
  }
}

// Si se ejecuta directamente
if (require.main === module) {
  // Verificar argumentos
  if (process.argv.includes('--setup')) {
    log('\n📝 CONFIGURACIÓN DE VARIABLES DE PRUEBA\n', 'cyan');
    log('Para ejecutar los tests, necesitas configurar:', 'yellow');
    log('1. testUserId: ID de un usuario admin', 'yellow');
    log('2. testCompanyId: ID de una empresa', 'yellow');
    log('3. testDriverId: ID de un conductor\n', 'yellow');
    log('Edita el archivo y busca las variables al inicio de runTests()', 'yellow');
    log('O proporciona los valores como variables de entorno:\n', 'yellow');
    log('TEST_USER_ID=1 TEST_COMPANY_ID=1 TEST_DRIVER_ID=1 node tests/test_dashboard_improvements.js\n', 'blue');
    process.exit(0);
  }

  // Intentar leer de variables de entorno
  testUserId = process.env.TEST_USER_ID || null;
  testCompanyId = process.env.TEST_COMPANY_ID || null;
  testDriverId = process.env.TEST_DRIVER_ID || null;

  runTests();
}

module.exports = {
  runTests,
  setTestIds,
  testNombreRutaSync,
  testDriverStatusUpdate,
  testRouteDeletionValidation,
  testMultipleBusesPerRoute,
};

