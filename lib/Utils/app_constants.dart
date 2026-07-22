enum DeploymentEnvironment { local, dev, prod }

class AppConstants {
  // ---- Deploy on Production or Development by changing this ----
  static const DeploymentEnvironment deploymentEnvironment =
      DeploymentEnvironment.prod;

  // Other constant classes
  static final Roles roles = Roles();
  static final AuctionStatuses auctionStatuses = AuctionStatuses();
  static final ImagesSectionIds imagesSectionIds = ImagesSectionIds();
  static final TabBarWidgetControllerTags tabBarWidgetControllerTags =
      TabBarWidgetControllerTags();
  static final HomeScreenSections homeScreenSections = HomeScreenSections();
  static final UserActivityLogEvents userActivityLogEvents =
      UserActivityLogEvents();

  // App Key for update app info
  static const String appKey = 'dealer';

  // App pkg and Display name
  static const String appPkgName = 'com.otobix.auctionapp';
  static const String appDisplayName = 'OtoBix Dealer App';

  static const List<String> indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli",
    "Delhi",
    "Jammu and Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry",
  ];

  // ---- configuration per environment ----
  static const _localConfiguration = _EnvConfig(
    deploymentEnvironmentName: 'local',
    renderBaseUrl: 'http://192.168.10.234:4000/api/',
    oneSignalAppId: 'a6697fe1-be34-420f-9aa7-1fa369e1b07c',
  );

  static const _devConfiguration = _EnvConfig(
    deploymentEnvironmentName: 'dev',
    renderBaseUrl: 'https://otobix-app-backend-development.onrender.com/api/',
    oneSignalAppId: 'a6697fe1-be34-420f-9aa7-1fa369e1b07c',
  );

  static const _prodConfiguration = _EnvConfig(
    deploymentEnvironmentName: 'prod',
    // renderBaseUrl: 'https://otobix-app-backend-rq8m.onrender.com/api/',
    renderBaseUrl: 'https://ob-dealerapp-kong.onrender.com/api/',
    oneSignalAppId: 'a6697fe1-be34-420f-9aa7-1fa369e1b07c',
  );

  static _EnvConfig get env =>
      deploymentEnvironment == DeploymentEnvironment.prod
      ? _prodConfiguration
      : deploymentEnvironment == DeploymentEnvironment.dev
      ? _devConfiguration
      : _localConfiguration;

  // convenience getters
  static String get envName => env.deploymentEnvironmentName; // 'dev' | 'prod'
  static bool get isProd => deploymentEnvironment == DeploymentEnvironment.prod;
  static String get renderBaseUrl => env.renderBaseUrl;
  static String get oneSignalAppId => env.oneSignalAppId;
  static String externalIdForNotifications(String mongoUserId) =>
      '$envName:$mongoUserId';
}

// User roles class
class Roles {
  // Fields
  final String dealer = 'Dealer';
  final String customer = 'Customer';
  final String salesManager = 'Sales Manager';
  final String admin = 'Admin';

  final String userStatusPending = 'Pending';
  final String userStatusApproved = 'Approved';
  final String userStatusRejected = 'Rejected';

  List<String> get all => [dealer, customer, salesManager, admin];
}

// Auction statuses class
class AuctionStatuses {
  final String all = 'all';
  final String upcoming = 'upcoming';
  final String live = 'live';
  final String otobuy = 'otobuy';
  final String marketplace = 'marketplace';
  final String liveAuctionEnded = 'liveAuctionEnded';
  final String sold = 'sold';
  final String otobuyEnded = 'otobuyEnded';
  final String removed = 'removed';

  // List<String> get all => [
  //   upcoming,
  //   live,
  //   otobuy,
  //   marketplace,
  //   liveAuctionEnded,
  //   otobuyEnded,
  // ];
}

// Images section ids
class ImagesSectionIds {
  final String exterior = 'exterior';
  final String interior = 'interior';
  final String engine = 'engine';
  final String suspension = 'suspension';
  final String ac = 'ac';
  final String tyres = 'tyres';
  final String damages = 'damages';

  List<String> get all => [exterior, interior, engine, suspension, ac];
}

//  TabBarWidgetController tags
class TabBarWidgetControllerTags {
  final String homeTabs = 'home_tabs';
  final String myCarsTabs = 'mycars_tabs';

  List<String> get all => [homeTabs, myCarsTabs];
}

// Home Screen Sections e.g. live, upcoming, otobuy, marketplace
class HomeScreenSections {
  // final String liveBidsSectionScreen = 'live_bids';
  final String liveBidsSectionScreen = 'live';
  final String upcomingSectionScreen = 'upcoming';
  final String otobuySectionScreen = 'otobuy';
  final String marketplaceSectionScreen = 'marketplace';
}

// User activity log events
class UserActivityLogEvents {
  // GENERAL
  final String appLaunched = 'app_launched';
  final String login = 'login';
}

// Environments Configuration class
class _EnvConfig {
  final String deploymentEnvironmentName; // 'dev' or 'prod'
  final String renderBaseUrl;
  final String oneSignalAppId;
  const _EnvConfig({
    required this.deploymentEnvironmentName,
    required this.renderBaseUrl,
    required this.oneSignalAppId,
  });
}
