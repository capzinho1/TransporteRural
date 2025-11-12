import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sección de Notificaciones
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Text(
                            localizations.translate('notifications'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(localizations.translate('receive_notifications')),
                        subtitle: Text(
                          localizations.translate('notifications_description'),
                        ),
                        value: settings.notificationsEnabled,
                        onChanged: (value) {
                          settings.setNotificationsEnabled(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? localizations.translate('notifications_enabled')
                                    : localizations.translate('notifications_disabled'),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              // Sección de Apariencia
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dark_mode, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Text(
                            localizations.translate('appearance'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(localizations.translate('dark_mode')),
                        subtitle: Text(
                          localizations.translate('dark_mode_description'),
                        ),
                        value: settings.darkModeEnabled,
                        onChanged: (value) {
                          settings.setDarkModeEnabled(value);
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              // Sección de Idioma
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language, color: Colors.purple[700]),
                          const SizedBox(width: 12),
                          Text(
                            localizations.translate('language'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('select_language'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...['es', 'en', 'pt', 'zh'].map((code) {
                        return RadioListTile<String>(
                          title: Text(settings.getLanguageName(code)),
                          value: code,
                          groupValue: settings.getLanguageCode(),
                          onChanged: (value) {
                            if (value != null) {
                              settings.setLanguage(value);
                            }
                          },
                          activeColor: Colors.green,
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Información adicional
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Text(
                            localizations.translate('information'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.apps),
                        title: Text(localizations.translate('app_version')),
                        subtitle: const Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: Text(localizations.translate('app_name_full')),
                        subtitle: Text(localizations.translate('app_description')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

