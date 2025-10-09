import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';
import '../providers/app_provider.dart';
// ignore: unused_import
import '../widgets/custom_button.dart';

/// Onboarding screen to introduce the app and collect basic information
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _medicalInfoController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _medicalInfoController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final appProvider = context.read<AppProvider>();
    
    // Create user profile if name is provided
    if (_nameController.text.isNotEmpty) {
      await appProvider.createUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        emergencyMedicalInfo: _medicalInfoController.text.trim().isEmpty 
            ? null 
            : _medicalInfoController.text.trim(),
      );
    }
    
    await appProvider.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),
            
            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildFeaturesPage(),
                  _buildProfilePage(),
                  _buildPermissionsPage(),
                ],
              ),
            ),
            
            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: List.generate(_totalPages, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? AppColors.emergencyRed
                    : AppColors.mediumGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Icon
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.emergencyRedLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security,
              size: 60,
              color: AppColors.emergencyRed,
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          const Text(
            'Welcome to\nPersonal Safety',
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          Text(
            'Your personal safety companion that helps you stay connected with trusted contacts and emergency services when you need help most.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Text(
                    'This app is designed to help in emergency situations. Please set it up carefully.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Key Features',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          _buildFeatureItem(
            icon: Icons.emergency,
            title: 'Emergency Alerts',
            description: 'Send instant alerts to your trusted contacts with your location',
            color: AppColors.emergencyRed,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildFeatureItem(
            icon: Icons.location_on,
            title: 'Location Sharing',
            description: 'Automatically share your location during emergencies',
            color: AppColors.info,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildFeatureItem(
            icon: Icons.contacts,
            title: 'Trusted Contacts',
            description: 'Manage your emergency contacts and trusted circle',
            color: AppColors.safeGreen,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildFeatureItem(
            icon: Icons.history,
            title: 'Alert History',
            description: 'Keep track of all sent alerts and their status',
            color: AppColors.warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Icon(
            icon,
            color: color,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.paddingL),
          
          const Text(
            'Set Up Your Profile',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingS),
          
          Text(
            'This information helps emergency contacts identify you.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          TextField(
            controller: _medicalInfoController,
            decoration: const InputDecoration(
              labelText: 'Emergency Medical Info',
              hintText: 'Allergies, medications, medical conditions...',
              prefixIcon: Icon(Icons.medical_services),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          Text(
            '* Required field',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Permissions Required',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          Text(
            'For the app to work effectively in emergencies, we need access to:',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          _buildPermissionItem(
            icon: Icons.location_on,
            title: 'Location Access',
            description: 'To share your location during emergencies',
            isRequired: true,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildPermissionItem(
            icon: Icons.phone,
            title: 'Phone Access',
            description: 'To make emergency calls and send SMS',
            isRequired: true,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildPermissionItem(
            icon: Icons.contacts,
            title: 'Contacts Access',
            description: 'To easily add emergency contacts',
            isRequired: false,
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.emergencyRedLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: AppColors.emergencyRed,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Text(
                    'Your privacy is important. Location data is only shared during emergencies.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.emergencyRedDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isRequired,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTextStyles.h4),
                  if (isRequired) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Required',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                child: const Text('Back'),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: AppDimensions.paddingM),
          
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (context.watch<AppProvider>().isLoading ||
                        (_currentPage == 2 && _nameController.text.trim().isEmpty))
                    ? null
                    : (_currentPage == _totalPages - 1
                        ? _completeOnboarding
                        : _nextPage),
                child: context.watch<AppProvider>().isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}