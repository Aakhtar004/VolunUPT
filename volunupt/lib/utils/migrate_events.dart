import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

/// Script de migración para actualizar eventos existentes
/// Ejecutar UNA SOLA VEZ para migrar de totalHoursForCertificate a startDate/endDate
Future<void> migrateEventsToDateRange() async {
  final firestore = FirebaseFirestore.instance;
  
  debugPrint('🔄 Iniciando migración de eventos...');
  
  try {
    // Obtener todos los eventos
    final eventsSnapshot = await firestore.collection('events').get();
    
    debugPrint('📊 Encontrados ${eventsSnapshot.docs.length} eventos');
    
    int migrated = 0;
    int skipped = 0;
    int errors = 0;
    
    for (final eventDoc in eventsSnapshot.docs) {
      try {
        final eventData = eventDoc.data();
        final eventId = eventDoc.id;
        
        // Verificar si ya tiene startDate y endDate
        if (eventData.containsKey('startDate') && eventData.containsKey('endDate')) {
          debugPrint('⏭️  Evento "${eventData['title']}" ya migrado, saltando...');
          skipped++;
          continue;
        }
        
        // Obtener actividades del evento
        final subEventsSnapshot = await firestore
            .collection('subEvents')
            .where('baseEventId', isEqualTo: eventId)
            .get();
        
        DateTime startDate;
        DateTime endDate;
        
        if (subEventsSnapshot.docs.isNotEmpty) {
          // Si tiene actividades, usar la fecha más temprana y más tardía
          final dates = subEventsSnapshot.docs
              .map((doc) => (doc.data()['date'] as Timestamp).toDate())
              .toList()
            ..sort();
          
          startDate = dates.first;
          endDate = dates.last;
          
          debugPrint('✅ Evento "${eventData['title']}": ${dates.length} actividades encontradas');
          debugPrint('   Rango: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
        } else {
          // Si no tiene actividades, usar fechas por defecto
          final now = DateTime.now();
          startDate = now;
          endDate = now.add(const Duration(days: 30));
          
          debugPrint('⚠️  Evento "${eventData['title']}": Sin actividades, usando fechas por defecto');
          debugPrint('   Rango: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
        }
        
        // Actualizar evento con fechas
        await eventDoc.reference.update({
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
        });
        
        // Remover campo antiguo (opcional)
        if (eventData.containsKey('totalHoursForCertificate')) {
          await eventDoc.reference.update({
            'totalHoursForCertificate': FieldValue.delete(),
          });
        }
        
        migrated++;
      } catch (e) {
        debugPrint('❌ Error migrando evento ${eventDoc.id}: $e');
        errors++;
      }
    }
    
    debugPrint('\n✨ Migración completada!');
    debugPrint('   ✅ Migrados: $migrated');
    debugPrint('   ⏭️  Saltados: $skipped');
    debugPrint('   ❌ Errores: $errors');
    
  } catch (e) {
    debugPrint('❌ Error general en migración: $e');
    rethrow;
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
