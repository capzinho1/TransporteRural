const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Importar rutas
const rutasRoutes = require('./routes/rutas');
const busesRoutes = require('./routes/buses');
const usuariosRoutes = require('./routes/usuarios');
const recorridosRoutes = require('./routes/recorridos');

// Rutas de la API
app.use('/api/routes', rutasRoutes);
app.use('/api/bus-locations', busesRoutes);
app.use('/api/users', usuariosRoutes);

// Ruta de salud
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'TransporteRural API funcionando correctamente',
    timestamp: new Date().toISOString()
  });
});

// Ruta raíz
app.get('/', (req, res) => {
  res.json({
    message: 'TransporteRural API',
    version: '1.0.0',
    endpoints: {
      routes: '/api/routes',
      busLocations: '/api/bus-locations',
      users: '/api/users',
      health: '/health'
    }
  });
});

// Manejo de errores
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Error interno del servidor',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Algo salió mal'
  });
});

// Ruta 404
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Ruta no encontrada',
    message: 'La ruta solicitada no existe'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚌 TransporteRural API ejecutándose en puerto ${PORT}`);
  console.log(`🌐 Acceso: http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;

