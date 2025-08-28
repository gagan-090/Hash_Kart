import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  
  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _isDataLoading = true;
  Map<String, dynamic>? _userProfile;
  final ApiService _apiService = ApiService();

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isDataLoading = true);
      
      final profile = await _apiService.getUserProfile();
      _userProfile = profile;
      
      // Populate form fields with backend data
      _firstNameController.text = profile['first_name'] ?? '';
      _lastNameController.text = profile['last_name'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _phoneController.text = profile['phone'] ?? profile['phone_number'] ?? '';
      _dobController.text = profile['date_of_birth'] ?? profile['dob'] ?? '';
      _selectedGender = profile['gender'] ?? 'Male';
      
      // Address fields
      final address = profile['address'] ?? {};
      _addressController.text = address['street'] ?? address['address_line_1'] ?? '';
      _cityController.text = address['city'] ?? '';
      _stateController.text = address['state'] ?? '';
      _zipController.text = address['zip'] ?? address['postal_code'] ?? '';
      
      setState(() => _isDataLoading = false);
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isDataLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading || _isDataLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: AppTheme.bodyMedium.copyWith(
                color: _isLoading || _isDataLoading ? AppTheme.textLight : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    _buildProfilePictureSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Personal Information
                    _buildSectionCard(
                      title: 'Personal Information',
                      child: Column(
                        children: [
                    Row(
                      children: [
                        Expanded(
                                child: _buildTextFormField(
                                  controller: _firstNameController,
                            label: 'First Name',
                                  icon: Icons.person_outline,
                            validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                                child: _buildTextFormField(
                                  controller: _lastNameController,
                            label: 'Last Name',
                                  icon: Icons.person_outline,
                            validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _emailController,
                      label: 'Email Address',
                            icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Email is required';
                        }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _phoneController,
                      label: 'Phone Number',
                            icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                          const SizedBox(height: 16),
                          _buildDateField(),
                          const SizedBox(height: 16),
                          _buildGenderDropdown(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address Information
                    _buildSectionCard(
                      title: 'Address Information',
                      child: Column(
                        children: [
                          _buildTextFormField(
                            controller: _addressController,
                            label: 'Street Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _cityController,
                                  label: 'City',
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _stateController,
                                  label: 'State',
                                  icon: Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _zipController,
                            label: 'ZIP/Postal Code',
                            icon: Icons.local_post_office_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Bottom spacing for navigation
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final profileImageUrl = _userProfile?['profile_image'];
    
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: profileImageUrl != null ? null : AppTheme.primaryGradient,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      profileImageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _changeProfilePicture,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _selectedGender = newValue);
        }
      },
      items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            title,
            style: AppTheme.heading3.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    // Placeholder for profile picture change functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture change functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'gender': _selectedGender,
        'address': {
          'street': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zip': _zipController.text.trim(),
        },
      };

      // Update profile via API
      await _apiService.updateUserProfile(updatedData);
      
      // Update the AuthProvider to refresh user data
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshUserProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Go back to previous screen
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}