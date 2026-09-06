import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/api_endpoints.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'data/local/database_helper.dart';
import 'data/remote/auth_api_service.dart';
import 'data/remote/inspection_api_service.dart';
import 'data/remote/checklist_api_service.dart';
import 'data/remote/evidence_api_service.dart';
import 'data/remote/report_api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/inspection_detail_provider.dart';
import 'providers/inspections_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/evidence_service.dart';
import 'services/sync_manager.dart';

// =====================================================================
// DRISHTI Field Inspector Mobile Application
// Ministry of Social Justice and Empowerment (MoSJE) - Govt. of India
// Production-Ready Phase 5 Offline-First Client
// =====================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configured backend URL from persistent preferences
  await ApiEndpoints.init();

  // Instantiate core infrastructure singletons
  final dbHelper = DatabaseHelper.instance;
  final apiClient = ApiClient();

  // Instantiate remote API service clients
  final authApi = AuthApiService(apiClient);
  final inspectionApi = InspectionApiService(apiClient);
  final checklistApi = ChecklistApiService(apiClient);
  final evidenceApi = EvidenceApiService(apiClient);
  final reportApi = ReportApiService(apiClient);

  // Instantiate hardware & sync services
  final evidenceService = EvidenceService(dbHelper: dbHelper);
  final syncManager = SyncManager(
    dbHelper: dbHelper,
    checklistApi: checklistApi,
    evidenceApi: evidenceApi,
    reportApi: reportApi,
    inspectionApi: inspectionApi,
  );

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<ApiClient>.value(value: apiClient),
        Provider<DatabaseHelper>.value(value: dbHelper),
        Provider<SyncManager>.value(value: syncManager),
        Provider<EvidenceService>.value(value: evidenceService),

        // State Providers
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authApi: authApi, dbHelper: dbHelper)..restoreSession(),
        ),
        ChangeNotifierProvider<InspectionsProvider>(
          create: (_) => InspectionsProvider(apiService: inspectionApi, dbHelper: dbHelper),
        ),
        ChangeNotifierProvider<InspectionDetailProvider>(
          create: (_) => InspectionDetailProvider(
            dbHelper: dbHelper,
            inspectionApi: inspectionApi,
            checklistApi: checklistApi,
            evidenceService: evidenceService,
            syncManager: syncManager,
          ),
        ),
      ],
      child: const DrishtiInspectorApp(),
    ),
  );
}

class DrishtiInspectorApp extends StatelessWidget {
  const DrishtiInspectorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primaryNavy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryNavy,
          primary: AppColors.primaryNavy,
          secondary: AppColors.saffronAccent,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading && auth.currentUser == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
