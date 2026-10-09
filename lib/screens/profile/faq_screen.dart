import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grahmitracus/core/constants/constants.dart';
import 'package:grahmitracus/core/responsive/size__extensions.dart';
import 'package:grahmitracus/screens/profile/customer_support_screen.dart';

class FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem({required this.question, required this.answer, this.isExpanded = false});
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Empty FAQ list to trigger empty state, ready for data
  final List<FaqItem> _allFaqs = [];
  List<FaqItem> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _allFaqs;
  }

  void _filterFaqs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _allFaqs;
      } else {
        _filteredFaqs = _allFaqs
            .where((faq) =>
                faq.question.toLowerCase().contains(query.toLowerCase()) ||
                faq.answer.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FAQ',
          style: AppTextStyles.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.subtleBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterFaqs,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search questions...',
                    hintStyle: AppTextStyles.plusJakartaSans(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.iconSubtle,
                      size: 20.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _allFaqs.isEmpty
                  ? _buildNoFaqState()
                  : _filteredFaqs.isEmpty
                      ? _buildNoResultsState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          itemCount: _filteredFaqs.length,
                          itemBuilder: (context, index) {
                            return _buildFaqItem(_filteredFaqs[index]);
                          },
                        ),
            ),
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(FaqItem faq) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            faq.isExpanded = !faq.isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.subtleBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: AppTextStyles.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    faq.isExpanded ? Icons.remove_rounded : Icons.add_rounded,
                    color: AppColors.iconSubtle,
                    size: 20.sp,
                  ),
                ],
              ),
              if (faq.isExpanded) ...[
                12.height,
                Text(
                  faq.answer,
                  style: AppTextStyles.plusJakartaSans(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFaqState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64.sp,
              color: AppColors.iconSubtle,
            ),
            16.height,
            Text(
              'No FAQs Available',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            8.height,
            Text(
              'We\'re working on adding helpful answers.',
              textAlign: TextAlign.center,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64.sp,
              color: AppColors.iconSubtle,
            ),
            16.height,
            Text(
              'No results found',
              style: AppTextStyles.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            8.height,
            Text(
              'Try searching with different keywords.',
              textAlign: TextAlign.center,
              style: AppTextStyles.plusJakartaSans(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Still need help?',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          4.height,
          Text(
            'Our support team is here to help.',
            style: AppTextStyles.plusJakartaSans(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          16.height,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerSupportScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Contact Customer Support',
                style: AppTextStyles.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
