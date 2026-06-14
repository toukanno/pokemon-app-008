import 'package:go_router/go_router.dart';

import '../../presentation/screens/title_screen.dart';
import '../../presentation/screens/starter_screen.dart';
import '../../presentation/screens/world_screen.dart';
import '../../presentation/screens/battle_screen.dart';
import '../../presentation/screens/party_screen.dart';
import '../../presentation/screens/box_screen.dart';
import '../../presentation/screens/dex_screen.dart';
import '../../presentation/screens/dex_detail_screen.dart';
import '../../presentation/screens/bag_screen.dart';
import '../../presentation/screens/shop_screen.dart';
import '../../presentation/screens/menu_screen.dart';
import '../../presentation/screens/settings_screen.dart';

/// アプリ全体のルーティング設定。
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TitleScreen()),
    GoRoute(path: '/starter', builder: (context, state) => const StarterScreen()),
    GoRoute(path: '/world', builder: (context, state) => const WorldScreen()),
    GoRoute(path: '/battle', builder: (context, state) => const BattleScreen()),
    GoRoute(path: '/party', builder: (context, state) => const PartyScreen()),
    GoRoute(path: '/box', builder: (context, state) => const BoxScreen()),
    GoRoute(path: '/dex', builder: (context, state) => const DexScreen()),
    GoRoute(
      path: '/dex/:id',
      builder: (context, state) =>
          DexDetailScreen(speciesId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(path: '/bag', builder: (context, state) => const BagScreen()),
    GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
    GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);
