import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_alert.dart';
import '../models/emergency_contact.dart';
import 'location_service.dart';
import 'storage_service.dart';

/// Service for handling emergency alert functionality
class EmergencyService {
  final LocationService _locationService;
  final StorageService _storageService;

  EmergencyService({
    required LocationService locationService,
    required StorageService storageService,
  })  : _locationService = locationService,
        _storageService = storageService;

  /// Send emergency alert to all active contacts
  Future<EmergencyAlert> sendEmergencyAlert({
    required AlertType type,
    String? customMessage,
    bool includeLocation = true,
    bool contactPolice = false,
  }) async {
    try {
      // Get current location if requested
      AlertLocation? location;
      if (includeLocation) {
        location = await _locationService.getCurrentLocationWithAddress();
      }

      // Get active emergency contacts
      final contacts = _storageService.getEmergencyContacts()
          .where((contact) => contact.isActive)
          .toList();

      // Create emergency alert
      final alert = EmergencyAlert(
        type: type,
        message: customMessage ?? _getDefaultMessage(type),
        location: location,
        contactIds: contacts.map((c) => c.id).toList(),
        status: AlertStatus.pending,
      );

      // Save alert to storage
      await _storageService.addEmergencyAlert(alert);

      // Send notifications to contacts
      await _notifyContacts(contacts, alert);

      // Contact police if requested
      if (contactPolice) {
        await _contactEmergencyServices();
      }

      // Update alert status
      final updatedAlert = alert.copyWith(status: AlertStatus.sent);
      await _storageService.updateEmergencyAlert(updatedAlert);

      return updatedAlert;
    } catch (e) {
      // Create failed alert for record keeping
      final failedAlert = EmergencyAlert(
        type: type,
        message: customMessage ?? _getDefaultMessage(type),
        status: AlertStatus.failed,
        metadata: {'error': e.toString()},
      );
      
      await _storageService.addEmergencyAlert(failedAlert);
      rethrow;
    }
  }

  /// Send quick emergency alert (panic button)
  Future<EmergencyAlert> sendQuickAlert() async {
    return await sendEmergencyAlert(
      type: AlertType.general,
      includeLocation: true,
    );
  }

  /// Contact emergency services (police, fire, medical)
  Future<void> _contactEmergencyServices() async {
    // This would typically integrate with local emergency numbers
    // For demo purposes, we'll use a generic emergency number
    const emergencyNumber = '911'; // or local equivalent
    
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: emergencyNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      print('Error contacting emergency services: $e');
    }
  }

  /// Notify emergency contacts via SMS and phone calls
  Future<void> _notifyContacts(
    List<EmergencyContact> contacts,
    EmergencyAlert alert,
  ) async {
    for (final contact in contacts) {
      try {
        // Send SMS
        await _sendSMS(contact, alert);
        
        // Make phone call (optional, based on severity)
        if (alert.type == AlertType.violence || 
            alert.type == AlertType.medical) {
          await _makePhoneCall(contact);
        }
      } catch (e) {
        print('Error notifying contact ${contact.name}: $e');
      }
    }
  }

  /// Send SMS to emergency contact
  Future<void> _sendSMS(EmergencyContact contact, EmergencyAlert alert) async {
    final message = _formatAlertMessage(alert);
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: contact.phoneNumber,
      queryParameters: {'body': message},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      print('Error sending SMS to ${contact.name}: $e');
    }
  }

  /// Make phone call to emergency contact
  Future<void> _makePhoneCall(EmergencyContact contact) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: contact.phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      print('Error calling ${contact.name}: $e');
    }
  }

  /// Format alert message for sharing
  String _formatAlertMessage(EmergencyAlert alert) {
    final buffer = StringBuffer();
    
    buffer.writeln('🚨 EMERGENCY ALERT 🚨');
    buffer.writeln('Type: ${alert.type.displayName}');
    
    if (alert.message != null) {
      buffer.writeln('Message: ${alert.message}');
    }
    
    if (alert.location != null) {
      buffer.writeln('Location: ${alert.location!.address ?? 'Unknown'}');
      buffer.writeln('Coordinates: ${_locationService.formatCoordinates(
        alert.location!.latitude,
        alert.location!.longitude,
      )}');
      buffer.writeln('Maps: ${_locationService.generateMapsUrl(
        alert.location!.latitude,
        alert.location!.longitude,
      )}');
    }
    
    buffer.writeln('Time: ${_formatDateTime(alert.createdAt)}');
    buffer.writeln('');
    buffer.writeln('This is an automated emergency alert. Please respond immediately.');
    
    return buffer.toString();
  }

  /// Get default message for alert type
  String _getDefaultMessage(AlertType type) {
    switch (type) {
      case AlertType.general:
        return 'I need immediate help. Please contact me or emergency services.';
      case AlertType.medical:
        return 'I am having a medical emergency and need immediate assistance.';
      case AlertType.violence:
        return 'I am in danger and need immediate help. Please contact police.';
      case AlertType.harassment:
        return 'I am being harassed and need assistance.';
      case AlertType.stalking:
        return 'I believe I am being stalked and need help.';
      case AlertType.accident:
        return 'I have been in an accident and need assistance.';
      case AlertType.fire:
        return 'There is a fire emergency at my location.';
      case AlertType.naturalDisaster:
        return 'I am affected by a natural disaster and need help.';
    }
  }

  /// Format date time for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Cancel pending alert (if possible)
  Future<void> cancelAlert(String alertId) async {
    final alerts = _storageService.getEmergencyAlerts();
    final alertIndex = alerts.indexWhere((a) => a.id == alertId);
    
    if (alertIndex != -1) {
      final alert = alerts[alertIndex];
      if (alert.status == AlertStatus.pending) {
        final cancelledAlert = alert.copyWith(status: AlertStatus.resolved);
        await _storageService.updateEmergencyAlert(cancelledAlert);
      }
    }
  }

  /// Test emergency system (sends test message)
  Future<void> testEmergencySystem() async {
    final contacts = _storageService.getEmergencyContacts()
        .where((contact) => contact.isActive)
        .toList();

    if (contacts.isEmpty) {
      throw Exception('No emergency contacts configured');
    }

    final testAlert = EmergencyAlert(
      type: AlertType.general,
      message: 'This is a test of your emergency alert system. No action required.',
      status: AlertStatus.sent,
      metadata: {'isTest': true},
    );

    await _storageService.addEmergencyAlert(testAlert);

    // Send test messages
    for (final contact in contacts.take(1)) { // Only test with first contact
      await _sendSMS(contact, testAlert);
    }
  }
}
