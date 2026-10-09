/// Centralized API endpoint routes
class ApiEndpoints {
  ApiEndpoints._();

  // Auth endpoints
  static const String login = '/api/login';
  static const String register = '/auth/register';
  static const String registerRequest = '/api/register-request';
  static const String registerVerify = '/api/register-verify';
  static const String logout = '/auth/logout';
  static const String updateFcmToken = '/api/update-fcm-token';
  static const String refreshToken = '/api/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/api/login-with-otp';
  static const String loginWithOtp = '/api/login-with-otp';
  static const String verifyMsg91 = '/api/auth/verify-msg91';
  static const String msg91SendOtp = 'https://api.msg91.com/api/v5/widget/sendOtp';
  static const String msg91VerifyOtp = 'https://api.msg91.com/api/v5/widget/verifyOtp';

  // User / Profile endpoints
  static const String userProfile = '/api/me';
  static const String updateProfile = '/api/update-profile';

  // Categories & Products
  static const String groups = '/api/groups';
  static const String categoryGroups = '/api/category-groups';
  static const String categoryGroupsProducts = '/api/category-groups-products';
  static const String categories = '/api/categories';
  static const String products = '/api/products';
  static const String trendingProducts = '/api/products/trendings';
  static const String activeDeals = '/api/deals/active';
  static const String spotlight = '/api/spotlight';
  static const String vendors = '/api/vendors';
  static const String relatedProducts = '/api/products/related';
  static const String searchSuggest = '/api/search/suggest';
  static String productDetail(String idOrSlug) => '/api/products/$idOrSlug';

  // Master Location & Serviceability
  static const String serviceableLocations = '/api/master/serviceable-locations';
  static const String validatePincode = '/api/master/validate-pincode';
  static const String resolveLocation = '/api/master/resolve-location';
  static const String countries = '/api/master/countries';
  static const String states = '/api/master/states';
  static const String cities = '/api/master/cities';
  static const String areas = '/api/master/areas';

  // Customer Addresses
  static const String customerAddress = '/api/customer/address';
  static String customerAddressDelete(int id) => '/api/customer/address/delete/$id';
  static String customerAddressSetPrimary(int id) => '/api/customer/address/$id/set-primary';
  static String customerAddressUpdate(int id) => '/api/customer/address/$id';

  // Customer Wallet
  static const String wallet = '/api/customer/my-wallet';
  static const String customerWallet = '/api/customer/my-wallet';

  // Orders
  static const String orders = '/api/customer/orders';
  static const String createOrder = '/api/place/orders';
  static String orderDetail(String id) => '/api/customer/orders/detail/$id';
  static String orderTracking(String id) => '/api/customer/orders/tracking/$id';

  // Cart & Checkout
  static const String cartRevalidate = '/api/cart/revalidate';
  static const String checkoutValidate = '/api/checkout/validate';

  // Payment
  static const String createKvontechPayment = '/api/create-kvontech-payment';
  static const String verifyRazorpayPayment = '/api/verify-razorpay-payment';

  // Coupons
  static const String activeCoupons = '/api/coupons/active';
  static const String applyCoupon = '/api/coupons/apply';
}

