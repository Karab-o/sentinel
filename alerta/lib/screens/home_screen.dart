import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';
import '../providers/app_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/emergency_alert.dart';

/// Home screen with emergency panic button and quick actions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // ignore: unused_field
  bool _isEmergencyMode = false;
  // ignore: unused_field
  final int _emergencyCountdown = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleEmergencyPress() async {
    final appProvider = context.read<AppProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Check if user has emergency contacts
    if (appProvider.activeContacts.isEmpty) {
      _showNoContactsDialog();
      return;
    }

    // Enter emergency mode
    setState(() {
      _isEmergencyMode = true;
    });
    navigationProvider.enterEmergencyMode();

    // Show emergency options dialog
    _showEmergencyOptionsDialog();
  }

  void _showNoContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Emergency Contacts'),
        content: const Text(
          'You need to add at least one emergency contact before you can send alerts. Would you like to add contacts now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NavigationProvider>().navigateToContacts();
            },
            child: const Text('Add Contacts'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.warning,
              color: AppColors.emergencyRed,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Emergency Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the type of emergency:',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildEmergencyTypeButton(
              AlertType.general,
              Icons.emergency,
              'General Emergency',
            ),
            const SizedBox(height: 8),
            _buildEmergencyTypeButton(
              AlertType.medical,
              Icons.medical_services,
              'Medical Emergency',
            ),
            const SizedBox(height: 8),
            _buildEmergencyTypeButton(
              AlertType.violence,
              Icons.security,
              'Violence/Assault',
            ),
            const SizedBox(height: 8),
            _buildEmergencyTypeButton(
              AlertType.harassment,
              Icons.report_problem,
              'Harassment',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _cancelEmergency,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeButton(
    AlertType type,
    IconData icon,
    String label,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _sendEmergencyAlert(type),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emergencyRed,
          foregroundColor: AppColors.textOnDark,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Future<void> _sendEmergencyAlert(AlertType type) async {
    Navigator.of(context).pop(); // Close dialog
    
    final appProvider = context.read<AppProvider>();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sending emergency alert...'),
          ],
        ),
      ),
    );

    try {
      final alert = await appProvider.sendEmergencyAlert(
        type: type,
        includeLocation: true,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (alert != null) {
          _showAlertSentDialog(alert);
        } else {
          _showAlertFailedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showAlertFailedDialog();
      }
    } finally {
      _cancelEmergency();
    }
  }

  void _showAlertSentDialog(EmergencyAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.safeGreen,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Alert Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency alert sent to ${context.read<AppProvider>().activeContacts.length} contacts.',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Alert Type: ${alert.type.displayName}',
              style: AppTextStyles.bodyMedium,
            ),
            if (alert.location != null) ...[
              const SizedBox(height: 4),
              const Text(
                'Location included in alert',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAlertFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.error,
              color: AppColors.error,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Alert Failed'),
          ],
        ),
        content: const Text(
          'Failed to send emergency alert. Please try again or contact emergency services directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleEmergencyPress(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _cancelEmergency() {
    setState(() {
      _isEmergencyMode = false;
    });
    context.read<NavigationProvider>().exitEmergencyMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Safety'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              final contactCount = appProvider.activeContacts.length;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: contactCount > 0 
                      ? AppColors.safeGreenLight 
                      : AppColors.warningOrangeLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.contacts,
                      size: 16,
                      color: contactCount > 0 
                          ? AppColors.safeGreen 
                          : AppColors.warningOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$contactCount',
                      style: AppTextStyles.caption.copyWith(
                        color: contactCount > 0 
                            ? AppColors.safeGreen 
                            : AppColors.warningOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Welcome Message
                  _buildWelcomeSection(appProvider),
                  
                  const SizedBox(height: AppDimensions.paddingXL),
                  
                  // Emergency Button
                  _buildEmergencyButton(),
                  
                  const SizedBox(height: AppDimensions.paddingXL),
                  
                  // Quick Actions
                  _buildQuickActions(appProvider),
                  
                  const SizedBox(height: AppDimensions.paddingL),
                  
                  // Recent Alerts
                  _buildRecentAlerts(appProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AppProvider appProvider) {
    final userName = appProvider.userProfile?.name ?? 'User';
    final contactCount = appProvider.activeContacts.length;
    
    return Column(
      children: [
        Text(
          'Hello, $userName',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppDimensions.paddingS),
        
        if (contactCount == 0)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.warningOrangeLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: AppColors.warningOrange,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setup Required',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.warningOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add emergency contacts to enable alerts',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.safeGreenLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.safeGreen,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Text(
                    'Ready to send alerts to $contactCount emergency contacts',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.safeGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyButton() {
    return Column(
      children: [
        const Text(
          'Emergency Alert',
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppDimensions.paddingM),
        
        Text(
          'Press and hold for emergency',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppDimensions.paddingL),
        
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: _handleEmergencyPress,
                child: ElevatedButton.icon(
                  onPressed: _handleEmergencyPress,
                  icon: const Icon(Icons.emergency),
                  label: const Text('SOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    foregroundColor: AppColors.textOnDark,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: AppTextStyles.h3,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppDimensions.paddingM),
        
        Text(
          'This will alert your emergency contacts\nwith your location',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: AppTextStyles.h3,
        ),
        
        const SizedBox(height: AppDimensions.paddingM),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.phone,
                title: 'Call 911',
                subtitle: 'Emergency services',
                onTap: () {
                  // TODO: Implement emergency call
                },
              ),
            ),
            
            const SizedBox(width: AppDimensions.paddingM),
            
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.location_on,
                title: 'Share Location',
                subtitle: 'Send current location',
                onTap: () {
                  // TODO: Implement location sharing
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingM),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.contacts,
                title: 'Contacts',
                subtitle: '${appProvider.activeContacts.length} active',
                onTap: () {
                  context.read<NavigationProvider>().navigateToContacts();
                },
              ),
            ),
            
            const SizedBox(width: AppDimensions.paddingM),
            
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.west_outlined,
                title: 'Test System',
                subtitle: 'Test emergency alerts',
                onTap: () => _testEmergencySystem(appProvider),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconL,
                color: AppColors.emergencyRed,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                title,
                style: AppTextStyles.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAlerts(AppProvider appProvider) {
    final recentAlerts = appProvider.emergencyAlerts.take(3).toList();
    
    if (recentAlerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Alerts',
              style: AppTextStyles.h3,
            ),
            TextButton(
              onPressed: () {
                context.read<NavigationProvider>().navigateToAlerts();
              },
              child: const Text('View All'),
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingM),
        
        ...recentAlerts.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(EmergencyAlert alert) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAlertStatusColor(alert.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                _getAlertTypeIcon(alert.type),
                color: _getAlertStatusColor(alert.status),
                size: AppDimensions.iconM,
              ),
            ),
            
            const SizedBox(width: AppDimensions.paddingM),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.type.displayName,
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(alert.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getAlertStatusColor(alert.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                alert.status.displayName,
                style: AppTextStyles.caption.copyWith(
                  color: _getAlertStatusColor(alert.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testEmergencySystem(AppProvider appProvider) async {
    if (appProvider.activeContacts.isEmpty) {
      _showNoContactsDialog();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Emergency System'),
        content: const Text(
          'This will send a test message to your first emergency contact. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Test'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await appProvider.testEmergencySystem();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test message sent successfully'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      }
    }
  }

  IconData _getAlertTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.general:
        return Icons.emergency;
      case AlertType.medical:
        return Icons.medical_services;
      case AlertType.violence:
        return Icons.security;
      case AlertType.harassment:
        return Icons.report_problem;
      case AlertType.stalking:
        return Icons.visibility;
      case AlertType.accident:
        return Icons.car_crash;
      case AlertType.fire:
        return Icons.local_fire_department;
      case AlertType.naturalDisaster:
        return Icons.warning;
    }
  }

  Color _getAlertStatusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.pending:
        return AppColors.warningOrange;
      case AlertStatus.sent:
      case AlertStatus.delivered:
        return AppColors.info;
      case AlertStatus.acknowledged:
      case AlertStatus.resolved:
        return AppColors.safeGreen;
      case AlertStatus.failed:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}