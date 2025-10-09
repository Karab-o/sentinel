import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';
import '../providers/app_provider.dart';
import '../models/emergency_contact.dart';

/// Screen for managing emergency contacts
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactDialog(),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final contacts = appProvider.emergencyContacts;
          
          if (contacts.isEmpty) {
            return _buildEmptyState();
          }
          
          return Column(
            children: [
              // Status Banner
              _buildStatusBanner(appProvider),
              
              // Contacts List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    return _buildContactCard(contacts[index], appProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(),
        backgroundColor: AppColors.emergencyRed,
        child: const Icon(Icons.add, color: AppColors.textOnDark),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.backgroundGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contacts_outlined,
                size: 60,
                color: AppColors.textLight,
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingL),
            
            const Text(
              'No Emergency Contacts',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppDimensions.paddingM),
            
            Text(
              'Add trusted contacts who will receive your emergency alerts. Having at least 2-3 contacts is recommended.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppDimensions.paddingXL),
            
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => _showAddContactDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add First Contact'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: AppColors.textOnDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildStatusBanner(AppProvider appProvider) {
  final activeCount = appProvider.activeContacts.length;
  final totalCount = appProvider.emergencyContacts.length;
  
  Color backgroundColor;
  Color textColor;
  IconData icon;
  String message;
  
  if (activeCount == 0) {
    backgroundColor = AppColors.error;
    textColor = AppColors.textOnDark;
    icon = Icons.warning;
    message = 'No active contacts - Emergency alerts disabled';
  } else if (activeCount < 2) {
    backgroundColor = AppColors.warningOrange;
    textColor = AppColors.textOnDark;
    icon = Icons.info;
    message = '$activeCount of $totalCount contacts active — consider adding more';
  } else {
    backgroundColor = AppColors.safeGreen;
    textColor = AppColors.textOnDark;
    icon = Icons.check_circle;
    message = '$activeCount of $totalCount contacts ready for emergencies';
  }
  
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppDimensions.paddingM),
    color: backgroundColor,
    child: Row(
      children: [
        Icon(icon, color: textColor, size: AppDimensions.iconM),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildContactCard(EmergencyContact contact, AppProvider appProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Contact Avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: contact.isActive 
                      ? AppColors.safeGreenLight 
                      : AppColors.mediumGray,
                  child: Text(
                    contact.name.isNotEmpty 
                        ? contact.name[0].toUpperCase() 
                        : '?',
                    style: AppTextStyles.h3.copyWith(
                      color: contact.isActive 
                          ? AppColors.safeGreen 
                          : AppColors.textLight,
                    ),
                  ),
                ),
                
                const SizedBox(width: AppDimensions.paddingM),
                
                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: AppTextStyles.h4,
                            ),
                          ),
                          Switch(
                            value: contact.isActive,
                            onChanged: (value) {
                              appProvider.toggleContactActive(contact.id);
                            },
                            activeThumbColor: AppColors.safeGreen,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        contact.phoneNumber,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                      if (contact.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          contact.email!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contact.relationship.displayName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleContactAction(value, contact, appProvider),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'call',
                      child: Row(
                        children: [
                          Icon(Icons.phone, size: 20),
                          SizedBox(width: 8),
                          Text('Call'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'message',
                      child: Row(
                        children: [
                          Icon(Icons.message, size: 20),
                          SizedBox(width: 8),
                          Text('Message'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleContactAction(String action, EmergencyContact contact, AppProvider appProvider) {
    switch (action) {
      case 'edit':
        _showEditContactDialog(contact);
        break;
      case 'call':
        // TODO: Implement phone call
        break;
      case 'message':
        // TODO: Implement SMS
        break;
      case 'delete':
        _showDeleteConfirmation(contact, appProvider);
        break;
    }
  }

  void _showDeleteConfirmation(EmergencyContact contact, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
          'Are you sure you want to delete ${contact.name} from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              appProvider.deleteEmergencyContact(contact.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${contact.name} deleted'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    _showContactDialog();
  }

  void _showEditContactDialog(EmergencyContact contact) {
    _showContactDialog(contact: contact);
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final isEditing = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phoneNumber ?? '');
    final emailController = TextEditingController(text: contact?.email ?? '');
    ContactRelationship selectedRelationship = contact?.relationship ?? ContactRelationship.family;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Contact' : 'Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter contact name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: AppDimensions.paddingM),
                
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'Enter phone number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: AppDimensions.paddingM),
                
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter email address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: AppDimensions.paddingM),
                
                DropdownButtonFormField<ContactRelationship>(
                  initialValue: selectedRelationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                  items: ContactRelationship.values.map((relationship) {
                    return DropdownMenuItem(
                      value: relationship,
                      child: Text(relationship.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRelationship = value;
                      });
                    }
                  },
                ),
                
                const SizedBox(height: AppDimensions.paddingM),
                
                Text(
                  '* Required fields',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                return ElevatedButton(
                  onPressed: appProvider.isLoading ? null : () {
                    _saveContact(
                      appProvider,
                      nameController.text.trim(),
                      phoneController.text.trim(),
                      emailController.text.trim(),
                      selectedRelationship,
                      contact,
                    );
                  },
                  child: appProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update' : 'Add'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContact(
    AppProvider appProvider,
    String name,
    String phone,
    String email,
    ContactRelationship relationship,
    EmergencyContact? existingContact,
  ) async {
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and phone number are required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      if (existingContact != null) {
        // Update existing contact
        final updatedContact = existingContact.copyWith(
          name: name,
          phoneNumber: phone,
          email: email.isEmpty ? null : email,
          relationship: relationship,
        );
        await appProvider.updateEmergencyContact(updatedContact);
      } else {
        // Add new contact
        final newContact = EmergencyContact(
          name: name,
          phoneNumber: phone,
          email: email.isEmpty ? null : email,
          relationship: relationship,
        );
        await appProvider.addEmergencyContact(newContact);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingContact != null 
                  ? 'Contact updated successfully' 
                  : 'Contact added successfully',
            ),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving contact: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}