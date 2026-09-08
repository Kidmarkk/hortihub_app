class ApiConstants {
  
  //static const String baseUrl = 'http://164.100.123.175/api';
  static const String baseUrl = 'https://hortihub.megagriculture.gov.in/api'; //production
  //static const String baseUrl = 'http://10.0.2.2:8081/hortihub/api';

  // Auth
  static const String login = '/auth/loginApi';
  static const String testPrivate = '/private/hello';
  static const String updatePassword = '/private/updatePassword';

  // Sales
  static const String salesList = '/private/sales/listDetails/';
  static const String salesAdd = '/private/sales/addDetails';
  static const String generateInvoice = '/private/sales/generateInvoice';
  static const String salesReport = '/private/sales/salesReport';

  // Stock
  static const String stockList = '/private/stock/listDetails/';
  static const String stockAdd = '/private/stock/addDetails';
  static const String stockUpdate = '/private/stock/updateDetails';

  // Rates
  static const String ratesList = '/private/rates/listDetails/';
  static const String ratesAdd = '/private/rates/addDetails';
  static const String ratesUpdate = '/private/rates/updateDetails';

  // Production
  static const String productionList = '/private/production/listDetails/';
  static const String productionAdd = '/private/production/addDetails';
  static const String productionUpdate = '/private/production/updateDetails';

  // Collection
  static const String collectionList = '/private/collection/listDetails/';
  static const String collectionAdd = '/private/collection/addDetails';
  static const String collectionUpdate = '/private/collection/updateDetails';
  static const String farmerList = '/hub/farmer/listDetails/';

  // Dropdown lists
  static const String cropCategoryList = '/state/crop-category/listDetails';
  static const String cropList = '/state/crop/listDetails';
  static const String packagingTypeList = '/hub/packaging-type/listDetails';
  static const String unitList = '/hub/unit/listDetails';
  static const String hubListForDistrict = '/district/hub/listDetails/';
  
}
