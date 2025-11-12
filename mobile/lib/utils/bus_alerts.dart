import 'package:flutter/material.dart';
import 'app_localizations.dart';

// Lista de alertas predefinidas para buses
class BusAlerts {
  static const List<BusAlertOption> predefinedAlerts = [
    BusAlertOption(
      id: 'bus_sucio',
      label: 'Bus Sucio',
      icon: Icons.cleaning_services,
      color: Colors.brown,
    ),
    BusAlertOption(
      id: 'bus_mal_estado',
      label: 'Bus en Mal Estado',
      icon: Icons.build,
      color: Colors.orange,
    ),
    BusAlertOption(
      id: 'chofer_mal_humorado',
      label: 'Chofer Mal Humorado',
      icon: Icons.sentiment_dissatisfied,
      color: Colors.red,
    ),
    BusAlertOption(
      id: 'no_acepta_tne',
      label: 'No Acepta TNE',
      icon: Icons.credit_card_off,
      color: Colors.purple,
    ),
    BusAlertOption(
      id: 'sobrecarga',
      label: 'Bus Sobrecargado',
      icon: Icons.people_outline,
      color: Colors.deepOrange,
    ),
    BusAlertOption(
      id: 'no_respeta_paradas',
      label: 'No Respeta Paradas',
      icon: Icons.stop_circle_outlined,
      color: Colors.red,
    ),
    BusAlertOption(
      id: 'exceso_velocidad',
      label: 'Exceso de Velocidad',
      icon: Icons.speed,
      color: Colors.orange,
    ),
    BusAlertOption(
      id: 'mal_servicio',
      label: 'Mal Servicio',
      icon: Icons.thumb_down,
      color: Colors.red,
    ),
    BusAlertOption(
      id: 'aire_acondicionado_roto',
      label: 'Aire Acondicionado Roto',
      icon: Icons.ac_unit,
      color: Colors.blue,
    ),
    BusAlertOption(
      id: 'asientos_rotos',
      label: 'Asientos Rotos',
      icon: Icons.event_seat,
      color: Colors.brown,
    ),
    BusAlertOption(
      id: 'puertas_no_funcionan',
      label: 'Puertas No Funcionan',
      icon: Icons.door_sliding,
      color: Colors.orange,
    ),
    BusAlertOption(
      id: 'mal_olor',
      label: 'Mal Olor',
      icon: Icons.air,
      color: Colors.green,
    ),
  ];

  static BusAlertOption? getAlertById(String id) {
    try {
      return predefinedAlerts.firstWhere((alert) => alert.id == id);
    } catch (e) {
      return null;
    }
  }

  static String getTranslatedLabel(String id, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      final alert = getAlertById(id);
      return alert?.label ?? id;
    }

    final translationKey = 'alert_$id';
    final translated = localizations.translate(translationKey);
    // Si la traducción no existe, usar el label original
    if (translated == translationKey) {
      final alert = getAlertById(id);
      return alert?.label ?? id;
    }
    return translated;
  }

  static Map<String, String> getTranslationKeyMap() {
    return {
      'bus_sucio': 'alert_bus_dirty',
      'bus_mal_estado': 'alert_bus_bad_condition',
      'chofer_mal_humorado': 'alert_driver_bad_mood',
      'no_acepta_tne': 'alert_no_tne',
      'sobrecarga': 'alert_overloaded',
      'no_respeta_paradas': 'alert_no_stops',
      'exceso_velocidad': 'alert_speed_excess',
      'mal_servicio': 'alert_bad_service',
      'aire_acondicionado_roto': 'alert_ac_broken',
      'asientos_rotos': 'alert_broken_seats',
      'puertas_no_funcionan': 'alert_doors_not_working',
      'mal_olor': 'alert_bad_smell',
    };
  }
}

class BusAlertOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const BusAlertOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}
