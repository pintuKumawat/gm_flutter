import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/responsive.dart';
import 'package:grahmitracus/models/location/serviceable_location_model.dart';
import 'package:grahmitracus/models/location/user_address_model.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/screens/location/add_address_modal.dart';

/// Location Picker Screen matching Next.js `LocationPicker.js`
/// Allows users to detect location, pick deliverable areas, manage saved addresses,
/// and add new delivery addresses.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _expandedCities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<LocationProvider>();
      prov.init();
      if (prov.serviceableLocations.isNotEmpty) {
        setState(() {
          _expandedCities[prov.serviceableLocations.first.cityId] = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAreaSelected(AreaLocationModel area) {
    HapticFeedback.lightImpact();
    context.read<LocationProvider>().selectArea(area);
    Navigator.pop(context);
  }

  void _onAddressSelected(UserAddressModel address) {
    HapticFeedback.lightImpact();
    context.read<LocationProvider>().selectAddress(address);
    Navigator.pop(context);
  }

  Future<void> _handleDetectLocation() async {
    HapticFeedback.mediumImpact();
    final prov = context.read<LocationProvider>();
    final success = await prov.detectLocation();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location detected: ${prov.currentLocation.displayString}',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF0C831F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not auto-detect location. Please select an area below.',
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
      }
    }
  }

  void _openAddAddressModal([UserAddressModel? existing]) {
    HapticFeedback.lightImpact();
    AddAddressModal.show(context, existingAddress: existing);
  }

  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'work':
      case 'office':
        return Icons.work_outline_rounded;
      case 'other':
        return Icons.location_on_outlined;
      case 'home':
      default:
        return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final query = _searchController.text.trim().toLowerCase();

    // Filter Deliverable Cities & Areas
    final filteredLocations = locationProv.serviceableLocations
        .map((cityGroup) {
          if (query.isEmpty) return cityGroup;
          if (cityGroup.cityName.toLowerCase().contains(query))
            return cityGroup;

          final matchedAreas = cityGroup.areas
              .where(
                (a) =>
                    a.areaName.toLowerCase().contains(query) ||
                    (a.pincode != null && a.pincode!.contains(query)),
              )
              .toList();

          if (matchedAreas.isNotEmpty) {
            return CityLocationsModel(
              cityId: cityGroup.cityId,
              cityName: cityGroup.cityName,
              areas: matchedAreas,
            );
          }
          return null;
        })
        .whereType<CityLocationsModel>()
        .toList();

    // Filter Saved Addresses
    final filteredAddresses = locationProv.savedAddresses.where((addr) {
      if (query.isEmpty) return true;
      return addr.formattedAddress.toLowerCase().contains(query) ||
          addr.addressType.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(locationProv),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // 1. Search Input Field
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF64748B),
                    size: 20.sp,
                  ),
                  10.width,
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for area, street name, pincode...',
                        hintStyle: AppTextStyles.plusJakartaSans(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Detect My Location Action
          InkWell(
            onTap: locationProv.isDetecting ? null : _handleDetectLocation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              child: Row(
                children: [
                  locationProv.isDetecting
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0084FF),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.my_location_rounded,
                          color: const Color(0xFF0084FF),
                          size: 20.sp,
                        ),
                  12.width,
                  Text(
                    locationProv.isDetecting
                        ? 'Detecting your location...'
                        : 'Detect my location',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0084FF),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Add New Address Card Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: GestureDetector(
              onTap: () => _openAddAddressModal(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.brandPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.brandPurple,
                        size: 18.sp,
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Address',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandPurple,
                            ),
                          ),
                          Text(
                            'Save delivery location for faster checkout',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.brandPurple,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),

          10.height,
          Divider(height: 8.h, thickness: 8.h, color: const Color(0xFFF8FAFC)),

          // 4. Deliverable Areas Section (Accordion)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
            child: Row(
              children: [
                Icon(
                  Icons.store_mall_directory_rounded,
                  size: 16.sp,
                  color: const Color(0xFF64748B),
                ),
                6.width,
                Text(
                  'DELIVERABLE AREAS',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          if (locationProv.isLoadingLocations)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.brandPurple,
                    ),
                  ),
                ),
              ),
            )
          else if (filteredLocations.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                'No matching deliverable areas found.',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: filteredLocations.map((cityGroup) {
                  final isExpanded =
                      query.isNotEmpty ||
                      (_expandedCities[cityGroup.cityId] ?? false);

                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // City Accordion Header
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedCities[cityGroup.cityId] = !isExpanded;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_city_rounded,
                                      size: 18.sp,
                                      color: AppColors.brandPurple,
                                    ),
                                    8.width,
                                    Text(
                                      cityGroup.cityName,
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 20.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Areas Pills
                        if (isExpanded) ...[
                          Divider(
                            height: 1.h,
                            thickness: 1.h,
                            color: const Color(0xFFF1F5F9),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: cityGroup.areas.map((area) {
                                final isSelected =
                                    locationProv.currentLocation.areaId ==
                                    area.areaId;

                                return GestureDetector(
                                  onTap: () => _onAreaSelected(area),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.brandPurple.withValues(
                                              alpha: 0.1,
                                            )
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.brandPurple
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.4 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          area.areaName,
                                          style: AppTextStyles.plusJakartaSans(
                                            fontSize: 12.sp,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.brandPurple
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                        if (area.pincode != null &&
                                            area.pincode!.isNotEmpty) ...[
                                          4.width,
                                          Text(
                                            '(${area.pincode})',
                                            style:
                                                AppTextStyles.plusJakartaSans(
                                                  fontSize: 10.5.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF94A3B8,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          10.height,
          Divider(height: 8.h, thickness: 8.h, color: const Color(0xFFF8FAFC)),

          // 5. Your Saved Addresses Section
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 16.sp,
                      color: const Color(0xFF64748B),
                    ),
                    6.width,
                    Text(
                      'SAVED ADDRESSES',
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _openAddAddressModal(),
                  child: Text(
                    '+ Add New',
                    style: AppTextStyles.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (locationProv.isLoadingAddresses)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.brandPurple,
                    ),
                  ),
                ),
              ),
            )
          else if (filteredAddresses.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                'No saved addresses yet. Add an address to get started!',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: filteredAddresses.map((addr) {
                  final isSelected =
                      locationProv.currentLocation.address?.id == addr.id;

                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandPurple
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () => _onAddressSelected(addr),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.brandPurple.withValues(
                                        alpha: 0.1,
                                      )
                                    : const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getAddressIcon(addr.addressType),
                                size: 20.sp,
                                color: isSelected
                                    ? AppColors.brandPurple
                                    : const Color(0xFF475569),
                              ),
                            ),
                            12.width,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        addr.displayTitle,
                                        style: AppTextStyles.plusJakartaSans(
                                          fontSize: 13.5.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (addr.isPrimary) ...[
                                        8.width,
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(
                                              4.r,
                                            ),
                                          ),
                                          child: Text(
                                            'PRIMARY',
                                            style:
                                                AppTextStyles.plusJakartaSans(
                                                  fontSize: 9.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(
                                                    0xFF15803D,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  4.height,
                                  Text(
                                    addr.formattedAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.plusJakartaSans(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                      height: 1.3,
                                    ),
                                  ),
                                  if (addr.isForOther &&
                                      addr.receiverName != null) ...[
                                    4.height,
                                    Text(
                                      'Receiver: ${addr.receiverName} (${addr.receiverPhone ?? ""})',
                                      style: AppTextStyles.plusJakartaSans(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brandPurple,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Actions Menu (Edit / Delete)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 18.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _openAddAddressModal(addr);
                                } else if (val == 'delete') {
                                  locationProv.deleteAddress(addr.id);
                                } else if (val == 'primary') {
                                  locationProv.setPrimaryAddress(addr.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'primary',
                                  child: Text('Set as Primary'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Address'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          30.height,
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(LocationProvider locationProv) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.chevron_left_rounded,
          size: 28.sp,
          color: const Color(0xFF1F2937),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      titleSpacing: 0,
      title: Text(
        locationProv.currentLocation.displayString,
        style: AppTextStyles.plusJakartaSans(
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
      ),
      actions: [
        if (locationProv.currentLocation.type != 'default')
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              locationProv.clearLocation();
            },
            child: Text(
              'Reset',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        10.width,
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(color: const Color(0xFFF1F5F9), height: 1.h),
      ),
    );
  }
}
