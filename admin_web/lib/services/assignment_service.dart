import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';

/// Resultado de una validación de asignación
class AssignmentValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  AssignmentValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
  });
}

/// Servicio centralizado para gestionar asignaciones de conductores y buses a rutas
class AssignmentService {
  /// Valida si un bus puede ser asignado a una ruta
  static AssignmentValidationResult validateBusAssignment({
    required BusLocation? bus,
    required String targetRouteId,
    required List<BusLocation> allBuses,
    required int? currentCompanyId,
  }) {
    if (bus == null) {
      return AssignmentValidationResult(
        isValid: true,
      );
    }

    final warnings = <String>[];

    // Validar que el bus pertenezca a la misma empresa
    if (currentCompanyId != null && bus.companyId != null) {
      if (bus.companyId != currentCompanyId) {
        return AssignmentValidationResult(
          isValid: false,
          errorMessage: 'El bus ${bus.busId} pertenece a otra empresa y no puede ser asignado.',
        );
      }
    }

    // Verificar si el bus ya está asignado a otra ruta
    if (bus.routeId != null && bus.routeId!.isNotEmpty && bus.routeId != targetRouteId) {
      warnings.add('El bus ${bus.busId} ya está asignado a otra ruta. La asignación anterior será removida.');
    }

    return AssignmentValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// Valida si un conductor puede ser asignado
  static AssignmentValidationResult validateDriverAssignment({
    required int? driverId,
    required String targetRouteId,
    required List<BusLocation> allBuses,
    required List<Usuario> allUsers,
    required int? currentCompanyId,
  }) {
    if (driverId == null) {
      return AssignmentValidationResult(
        isValid: true,
      );
    }

    // Verificar que el conductor existe y es realmente un conductor
    Usuario? driver;
    try {
      driver = allUsers.firstWhere(
        (u) => u.id == driverId && u.role == 'driver',
      );
    } catch (e) {
      return AssignmentValidationResult(
        isValid: false,
        errorMessage: 'El conductor seleccionado no existe o no es un conductor válido.',
      );
    }

    // Validar que el conductor pertenezca a la misma empresa
    if (currentCompanyId != null && driver.companyId != null) {
      if (driver.companyId != currentCompanyId) {
        return AssignmentValidationResult(
          isValid: false,
          errorMessage: 'El conductor ${driver.name} pertenece a otra empresa y no puede ser asignado.',
        );
      }
    }

    final warnings = <String>[];

    // Verificar si el conductor ya tiene un bus asignado en otra ruta
    final existingBus = getBusAssignedToDriver(driverId, allBuses);

    if (existingBus != null) {
      if (existingBus.routeId != null && existingBus.routeId != targetRouteId) {
        warnings.add('El conductor ${driver.name} ya tiene un bus asignado en otra ruta. La asignación anterior será actualizada.');
      }
    }

    return AssignmentValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// Valida que la ruta pertenezca a la misma empresa
  static AssignmentValidationResult validateRouteCompany({
    required Ruta route,
    required int? currentCompanyId,
  }) {
    if (currentCompanyId != null && route.companyId != null) {
      if (route.companyId != currentCompanyId) {
        return AssignmentValidationResult(
          isValid: false,
          errorMessage: 'La ruta ${route.name} pertenece a otra empresa.',
        );
      }
    }

    return AssignmentValidationResult(
      isValid: true,
    );
  }

  /// Valida una asignación completa (bus, conductor y ruta)
  static AssignmentValidationResult validateFullAssignment({
    required BusLocation? bus,
    required int? driverId,
    required Ruta route,
    required List<BusLocation> allBuses,
    required List<Usuario> allUsers,
    required int? currentCompanyId,
  }) {
    // Validar que la ruta pertenezca a la misma empresa
    final routeValidation = validateRouteCompany(
      route: route,
      currentCompanyId: currentCompanyId,
    );
    if (!routeValidation.isValid) {
      return routeValidation;
    }

    // Validar el bus
    final busValidation = validateBusAssignment(
      bus: bus,
      targetRouteId: route.routeId,
      allBuses: allBuses,
      currentCompanyId: currentCompanyId,
    );
    if (!busValidation.isValid) {
      return busValidation;
    }

    // Validar el conductor
    final driverValidation = validateDriverAssignment(
      driverId: driverId,
      targetRouteId: route.routeId,
      allBuses: allBuses,
      allUsers: allUsers,
      currentCompanyId: currentCompanyId,
    );
    if (!driverValidation.isValid) {
      return driverValidation;
    }

    // Combinar advertencias
    final allWarnings = <String>[
      ...busValidation.warnings,
      ...driverValidation.warnings,
    ];

    // Validación adicional CRÍTICA: Si el bus ya tiene otro conductor asignado (y se está cambiando)
    if (bus != null && driverId != null) {
      // Verificar si el bus tiene un conductor asignado diferente
      if (bus.driverId != null) {
        if (bus.driverId != driverId) {
          // El bus tiene un conductor diferente al que se está asignando
          print('⚠️ [ASSIGNMENT_SERVICE] Detectado: Bus ${bus.busId} tiene conductor ${bus.driverId}, se está asignando ${driverId}');
          try {
            final currentDriver = allUsers.firstWhere(
              (u) => u.id == bus.driverId && u.role == 'driver',
            );
            final newDriver = allUsers.firstWhere(
              (u) => u.id == driverId && u.role == 'driver',
            );
            final warningMsg = 'El bus ${bus.busId} ya tiene asignado al conductor ${currentDriver.name}. Será reasignado a ${newDriver.name}.';
            print('⚠️ [ASSIGNMENT_SERVICE] Agregando advertencia: $warningMsg');
            allWarnings.add(warningMsg);
          } catch (e) {
            print('⚠️ [ASSIGNMENT_SERVICE] Error al buscar conductores: $e');
            final warningMsg = 'El bus ${bus.busId} ya tiene otro conductor asignado. Será reasignado al nuevo conductor.';
            print('⚠️ [ASSIGNMENT_SERVICE] Agregando advertencia genérica: $warningMsg');
            allWarnings.add(warningMsg);
          }
        } else {
          print('✅ [ASSIGNMENT_SERVICE] Bus ${bus.busId} ya tiene el mismo conductor asignado');
        }
      } else {
        print('✅ [ASSIGNMENT_SERVICE] Bus ${bus.busId} no tiene conductor asignado, se puede asignar directamente');
      }
    }

    // Validación adicional: Si el conductor ya tiene otro bus asignado
    if (driverId != null && bus != null) {
      final existingDriverBus = getBusAssignedToDriver(driverId, allBuses);
      if (existingDriverBus != null &&
          existingDriverBus.id != bus.id &&
          existingDriverBus.routeId != null &&
          existingDriverBus.routeId != route.routeId) {
        final driver = allUsers.firstWhere(
          (u) => u.id == driverId && u.role == 'driver',
          orElse: () => Usuario(id: 0, name: 'Desconocido', email: '', role: ''),
        );
        if (driver.id != 0) {
          allWarnings.add(
            'El conductor ${driver.name} ya tiene un bus asignado en otra ruta. El bus anterior será desasignado.',
          );
        }
      }
    }

    return AssignmentValidationResult(
      isValid: true,
      warnings: allWarnings,
    );
  }

  /// Obtiene información sobre buses ya asignados a una ruta
  static List<BusLocation> getBusesAssignedToRoute(String routeId, List<BusLocation> allBuses) {
    return allBuses.where((b) => b.routeId == routeId).toList();
  }

  /// Obtiene el conductor asignado a una ruta (a través del bus)
  static Usuario? getDriverAssignedToRoute(String routeId, List<BusLocation> allBuses, List<Usuario> allUsers) {
    final bus = allBuses.firstWhere(
      (b) => b.routeId == routeId && b.driverId != null,
      orElse: () => BusLocation(
        id: null,
        busId: '',
        latitude: 0,
        longitude: 0,
        status: 'inactive',
      ),
    );

    if (bus.driverId != null) {
      try {
        return allUsers.firstWhere(
          (u) => u.id == bus.driverId && u.role == 'driver',
        );
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Verifica si un bus está disponible (sin ruta ni conductor asignados)
  static bool isBusAvailable(BusLocation bus) {
    return (bus.routeId == null || bus.routeId!.isEmpty) && bus.driverId == null;
  }

  /// Verifica si un conductor está disponible (sin bus asignado)
  static bool isDriverAvailable(int driverId, List<BusLocation> allBuses) {
    return !allBuses.any((b) => b.driverId == driverId);
  }

  /// Obtiene el bus actualmente asignado a un conductor
  static BusLocation? getBusAssignedToDriver(int driverId, List<BusLocation> allBuses) {
    try {
      return allBuses.firstWhere((b) => b.driverId == driverId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el bus asignado a una ruta (primer bus encontrado)
  static BusLocation? getBusAssignedToRoute(String routeId, List<BusLocation> allBuses) {
    try {
      return allBuses.firstWhere((b) => b.routeId == routeId);
    } catch (e) {
      return null;
    }
  }

  /// Prepara los datos de actualización para una asignación
  /// 
  /// IMPORTANTE: Para desasignar explícitamente, pasar null como valor del parámetro.
  /// Si el parámetro no se proporciona (omisión), no se actualizará ese campo.
  /// 
  /// Ejemplo para desasignar ruta y conductor:
  /// ```dart
  /// prepareAssignmentUpdate(
  ///   bus: bus,
  ///   driverId: null,  // null explícito = desasignar
  ///   routeId: null,   // null explícito = desasignar
  /// )
  /// ```
  static Map<String, dynamic> prepareAssignmentUpdate({
    required BusLocation? bus,
    required int? driverId, // null explícito = desasignar, omitir = mantener
    required String? routeId, // null explícito = desasignar, omitir = mantener
    String? status,
  }) {
    final updateData = <String, dynamic>{};

    if (bus == null) {
      return updateData;
    }

    // IMPORTANTE: En este método, si routeId o driverId son null,
    // significa que queremos desasignar (no mantener el valor actual).
    // Si queremos mantener el valor actual, no incluimos el campo en updateData.

    // Determinar si debemos actualizar routeId
    // Si routeId es null (explícito), desasignar
    // Si routeId es una string no vacía, asignar esa ruta
    // Si routeId no se proporciona (pero eso no es posible aquí porque es required), mantener actual
    
    // Para routeId: null explícito significa desasignar
    if (routeId != null) {
      // Se proporcionó una ruta, asignarla
      updateData['route_id'] = routeId;
    } else if (bus.routeId != null) {
      // routeId es null pero el bus tenía ruta asignada -> desasignar
      updateData['route_id'] = null;
    }
    // Si routeId es null y el bus no tenía ruta, no hacer nada

    // Para driverId: null explícito significa desasignar
    if (driverId != null) {
      // Se proporcionó un conductor, asignarlo
      updateData['driver_id'] = driverId;
    } else if (bus.driverId != null) {
      // driverId es null pero el bus tenía conductor asignado -> desasignar
      updateData['driver_id'] = null;
    }
    // Si driverId es null y el bus no tenía conductor, no hacer nada

    // Auto-determinar estado basado en las asignaciones finales
    final finalDriverId = driverId ?? bus.driverId;
    final finalRouteId = routeId ?? bus.routeId;
    final willHaveDriverFinal = finalDriverId != null;
    final willHaveRouteFinal = finalRouteId != null && finalRouteId.isNotEmpty;

    // Si estamos desasignando ambos explícitamente, el estado debe ser inactive
    if (driverId == null && routeId == null && bus.driverId != null && bus.routeId != null) {
      // Desasignando todo explícitamente
      updateData['status'] = 'inactive';
    } else if (status != null) {
      // Si se proporciona explícitamente, usar ese estado
      updateData['status'] = status;
    } else {
      // Auto-determinar estado basado en las asignaciones finales
      if (willHaveDriverFinal && willHaveRouteFinal) {
        // Si tiene conductor y ruta, debe estar activo
        updateData['status'] = 'active';
      } else if (!willHaveDriverFinal && !willHaveRouteFinal) {
        // Si no tiene conductor ni ruta, debe estar inactivo
        updateData['status'] = 'inactive';
      }
      // Si tiene solo uno de los dos, mantener el estado actual (no actualizar)
    }

    print('🔍 [ASSIGNMENT_SERVICE] prepareAssignmentUpdate:');
    print('  - Bus: ${bus.busId}');
    print('  - driverId actual: ${bus.driverId}, nuevo: $driverId');
    print('  - routeId actual: ${bus.routeId}, nuevo: $routeId');
    print('  - updateData: $updateData');

    return updateData;
  }

  /// Desasigna un bus de su ruta actual (para reasignarlo a otra)
  static Future<void> desassignBusFromRoute(
    BusLocation bus,
    dynamic apiService,
  ) async {
    if (bus.id != null && bus.routeId != null) {
      await apiService.updateBusLocationDirect(bus.id!, {
        'route_id': null,
      });
    }
  }

  /// Desasigna un conductor de su bus actual (para reasignarlo a otro bus/ruta)
  static Future<void> desassignDriverFromBus(
    int driverId,
    List<BusLocation> allBuses,
    dynamic apiService,
  ) async {
    final existingBus = getBusAssignedToDriver(driverId, allBuses);
    if (existingBus != null && existingBus.id != null) {
      await apiService.updateBusLocationDirect(existingBus.id!, {
        'driver_id': null,
      });
    }
  }
}
