import 'package:flutter/material.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final List<Address> _addresses = [
    Address(
      id: '1',
      title: 'Home',
      name: 'John Doe',
      address: '123 Main Street, Apt 4B',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      phone: '+1 234 567 8900',
      isDefault: true,
    ),
    Address(
      id: '2',
      title: 'Office',
      name: 'John Doe',
      address: '456 Business Ave, Suite 200',
      city: 'New York',
      state: 'NY',
      zipCode: '10002',
      phone: '+1 234 567 8900',
      isDefault: false,
    ),
    Address(
      id: '3',
      title: 'Mom\'s House',
      name: 'Jane Doe',
      address: '789 Family Road',
      city: 'Brooklyn',
      state: 'NY',
      zipCode: '11201',
      phone: '+1 234 567 8901',
      isDefault: false,
    ),
  ];

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
          'Address Book',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: () => NavigationHelper.goToAddEditAddress(),
          ),
        ],
      ),
      body: _addresses.isEmpty ? _buildEmptyState() : _buildAddressList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NavigationHelper.goToAddEditAddress(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      title: 'No addresses saved',
      subtitle: 'Add your first address to get started',
      icon: Icons.location_on_outlined,
      buttonText: 'Add Address',
      onButtonPressed: () => NavigationHelper.goToAddEditAddress(),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _buildAddressCard(address, index);
      },
    );
  }

  Widget _buildAddressCard(Address address, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: address.isDefault
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and default badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    address.title,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Default',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, address, index),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: AppTheme.textSecondary),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 20, color: AppTheme.textSecondary),
                            SizedBox(width: 12),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              address.name,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Address
            Text(
              address.address,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),

            // City, State, ZIP
            Text(
              '${address.city}, ${address.state} ${address.zipCode}',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Phone
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 8),
                Text(
                  address.phone,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => NavigationHelper.goToAddEditAddress(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    child: Text(
                      'Edit',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Use this address for delivery
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${address.title} address selected'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Use Address',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Address address, int index) {
    switch (action) {
      case 'edit':
        NavigationHelper.goToAddEditAddress();
        break;
      case 'default':
        _setAsDefault(index);
        break;
      case 'delete':
        _showDeleteDialog(address, index);
        break;
    }
  }

  void _setAsDefault(int index) {
    setState(() {
      // Remove default from all addresses
      for (var address in _addresses) {
        address.isDefault = false;
      }
      // Set selected address as default
      _addresses[index].isDefault = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showDeleteDialog(Address address, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Address',
          style: AppTheme.heading3,
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(index);
            },
            child: Text(
              'Delete',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAddress(int index) {
    final deletedAddress = _addresses[index];
    setState(() {
      _addresses.removeAt(index);
      
      // If deleted address was default and there are other addresses, make first one default
      if (deletedAddress.isDefault && _addresses.isNotEmpty) {
        _addresses[0].isDefault = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedAddress.title} address deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _addresses.insert(index, deletedAddress);
            });
          },
        ),
      ),
    );
  }
}

class Address {
  final String id;
  final String title;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  bool isDefault;

  Address({
    required this.id,
    required this.title,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.isDefault,
  });
}
