import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:grahmitracus/providers/location/location_provider.dart';
import 'package:grahmitracus/models/location/user_address_model.dart';
import 'package:grahmitracus/screens/location/add_address_modal.dart';
import 'package:grahmitracus/core/responsive/size__extensions.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _openAddAddressModal(BuildContext context, [UserAddressModel? existing]) {
    AddAddressModal.show(context, existingAddress: existing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Addresses',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<LocationProvider>(
          builder: (context, locationProv, child) {
            final addresses = locationProv.savedAddresses;

            return Column(
              children: [
                // Add New Address Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: InkWell(
                    onTap: () => _openAddAddressModal(context),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.brandPurple.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: AppColors.brandPurple,
                            size: 20.sp,
                          ),
                          8.width,
                          Text(
                            'Add New Address',
                            style: AppTextStyles.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: addresses.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          itemCount: addresses.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final addr = addresses[index];
                            return _buildAddressCard(context, addr, locationProv);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    UserAddressModel addr,
    LocationProvider locationProv,
  ) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.subtleBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getAddressIcon(addr.addressType),
              color: AppColors.brandPurple,
              size: 20.sp,
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      addr.displayTitle,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: AppColors.iconSubtle, size: 20.sp),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openAddAddressModal(context, addr);
                        } else if (value == 'delete') {
                          locationProv.deleteAddress(addr.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                4.height,
                Text(
                  addr.receiverName ?? 'Pintu Kumar',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                4.height,
                Text(
                  addr.streetAddress,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                2.height,
                Text(
                  '${addr.city}, ${addr.state} - ${addr.pincode}',
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 48.sp,
                color: AppColors.brandPurple,
              ),
            ),
            16.height,
            Text(
              'No Saved Addresses',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            8.height,
            Text(
              "You haven't saved any delivery addresses yet.",
              textAlign: TextAlign.center,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
