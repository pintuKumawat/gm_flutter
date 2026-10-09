import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/location/user_address_model.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';

/// Modal bottom sheet for adding a new delivery address
/// matching the Next.js `AddressModal.js` structure and UX.
class AddAddressModal extends StatefulWidget {
  final UserAddressModel? existingAddress;

  const AddAddressModal({super.key, this.existingAddress});

  static Future<UserAddressModel?> show(BuildContext context,
      {UserAddressModel? existingAddress}) {
    return showModalBottomSheet<UserAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAddressModal(existingAddress: existingAddress),
    );
  }

  @override
  State<AddAddressModal> createState() => _AddAddressModalState();
}

class _AddAddressModalState extends State<AddAddressModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _streetController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _receiverNameController;
  late TextEditingController _receiverPhoneController;

  String _addressType = 'home';
  bool _isPrimary = false;
  bool _isForOther = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _streetController = TextEditingController(text: addr?.streetAddress ?? '');
    _landmarkController = TextEditingController(text: addr?.landmark ?? '');
    _cityController = TextEditingController(text: addr?.city ?? 'Noida');
    _stateController =
        TextEditingController(text: addr?.state ?? 'Uttar Pradesh');
    _pincodeController = TextEditingController(text: addr?.pincode ?? '201309');
    _countryController = TextEditingController(text: addr?.country ?? 'India');
    _receiverNameController =
        TextEditingController(text: addr?.receiverName ?? '');
    _receiverPhoneController =
        TextEditingController(text: addr?.receiverPhone ?? '');

    _addressType = addr?.addressType ?? 'home';
    _isPrimary = addr?.isPrimary ?? false;
    _isForOther = addr?.isForOther ?? false;
  }

  @override
  void dispose() {
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isForOther &&
        (_receiverNameController.text.trim().isEmpty ||
            _receiverPhoneController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide receiver name and phone number',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 12.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final locationProv = context.read<LocationProvider>();

    final Map<String, dynamic> data = {
      'street_address': _streetController.text.trim(),
      'landmark': _landmarkController.text.trim().isNotEmpty
          ? _landmarkController.text.trim()
          : null,
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'country': _countryController.text.trim(),
      'address_type': _addressType,
      'is_primary': _isPrimary ? 1 : 0,
      'is_for_other': _isForOther ? 1 : 0,
      'receiver_name': _isForOther &&
              _receiverNameController.text.trim().isNotEmpty
          ? _receiverNameController.text.trim()
          : null,
      'receiver_phone': _isForOther &&
              _receiverPhoneController.text.trim().isNotEmpty
          ? _receiverPhoneController.text.trim()
          : null,
    };

    if (widget.existingAddress != null) {
      final success = await locationProv.updateAddress(
          widget.existingAddress!.id, data);
      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locationProv.errorMessage ?? 'Failed to update address',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } else {
      final created = await locationProv.addNewAddress(data);
      if (mounted) {
        if (created != null) {
          Navigator.pop(context, created);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locationProv.errorMessage ?? 'Failed to save address',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final isSaving = locationProv.isSavingAddress;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingAddress != null
                      ? 'Edit Delivery Address'
                      : 'Add Delivery Address',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16.sp,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1.h, thickness: 1.h, color: const Color(0xFFF1F5F9)),

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                18.w,
                16.h,
                18.w,
                MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Address Details
                    Text(
                      'ADDRESS DETAILS',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    12.height,

                    // Street Address
                    _buildTextField(
                      controller: _streetController,
                      hint: 'Complete address (House no, floor, building)',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Street address is required';
                        }
                        return null;
                      },
                    ),
                    10.height,

                    // Landmark
                    _buildTextField(
                      controller: _landmarkController,
                      hint: 'Nearby landmark (optional)',
                    ),
                    10.height,

                    // City & State Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            hint: 'City',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'City is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        10.width,
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            hint: 'State',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'State is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    10.height,

                    // Pincode & Country Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _pincodeController,
                            hint: 'Pincode',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Pincode is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        10.width,
                        Expanded(
                          child: _buildTextField(
                            controller: _countryController,
                            hint: 'Country',
                          ),
                        ),
                      ],
                    ),
                    10.height,

                    // Make Default Checkbox
                    GestureDetector(
                      onTap: () {
                        setState(() => _isPrimary = !_isPrimary);
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: Checkbox(
                              value: _isPrimary,
                              activeColor: AppColors.brandPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              onChanged: (val) {
                                setState(() => _isPrimary = val ?? false);
                              },
                            ),
                          ),
                          8.width,
                          Text(
                            'Make this my default address',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    18.height,

                    Divider(
                      height: 1.h,
                      thickness: 1.h,
                      color: const Color(0xFFF1F5F9),
                    ),
                    18.height,

                    // Section 2: Save As
                    Text(
                      'SAVE AS',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    12.height,
                    Row(
                      children: [
                        _buildAddressTypePill(
                          'home',
                          'Home',
                          Icons.home_rounded,
                        ),
                        10.width,
                        _buildAddressTypePill(
                          'work',
                          'Work',
                          Icons.work_rounded,
                        ),
                        10.width,
                        _buildAddressTypePill(
                          'other',
                          'Other',
                          Icons.location_on_rounded,
                        ),
                      ],
                    ),
                    18.height,

                    Divider(
                      height: 1.h,
                      thickness: 1.h,
                      color: const Color(0xFFF1F5F9),
                    ),
                    18.height,

                    // Section 3: Ordering for someone else?
                    GestureDetector(
                      onTap: () {
                        setState(() => _isForOther = !_isForOther);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: _isForOther
                                  ? AppColors.brandPurple
                                      .withValues(alpha: 0.1)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_outline_rounded,
                              color: _isForOther
                                  ? AppColors.brandPurple
                                  : const Color(0xFF64748B),
                              size: 20.sp,
                            ),
                          ),
                          12.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ordering for someone else?',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Add receiver\'s name and phone number',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isForOther,
                            activeTrackColor: AppColors.brandPurple,
                            onChanged: (val) {
                              setState(() => _isForOther = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_isForOther) ...[
                      14.height,
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _receiverNameController,
                              hint: 'Receiver\'s Name',
                            ),
                          ),
                          10.width,
                          Expanded(
                            child: _buildTextField(
                              controller: _receiverPhoneController,
                              hint: 'Receiver\'s Phone',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                    ],

                    24.height,

                    // Save Address CTA Button
                    GestureDetector(
                      onTap: isSaving ? null : _submitAddress,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPurple
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isSaving
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.existingAddress != null
                                      ? 'Update Address'
                                      : 'Save Address',
                                  style: AppTextStyles.plusJakartaSans(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: AppTextStyles.plusJakartaSans(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.plusJakartaSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.brandPurple, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  Widget _buildAddressTypePill(String type, String label, IconData icon) {
    final isSelected = _addressType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _addressType = type);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPurple.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandPurple
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isSelected
                    ? AppColors.brandPurple
                    : const Color(0xFF64748B),
              ),
              4.height,
              Text(
                label,
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.brandPurple
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
