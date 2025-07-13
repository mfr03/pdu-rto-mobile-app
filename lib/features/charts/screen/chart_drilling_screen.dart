import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/model/depth_config.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/model/depth_config_result.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/depth_config_dialog.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/page/chart_depth_page.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/page/chart_time_page.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/depth_chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/notification/screen/notification_settings_screen.dart';
import 'package:pdu_mobile_rto_app/features/profiles/screen/user_settings_screen.dart';
import 'package:pdu_mobile_rto_app/features/remarks/screen/remarks_screen.dart';
import '../../../data/services/pdu_api/model/well_active.dart';
import '../../../utils/constants/colors.dart';
import '../components/widget/dialog/add_parameter_dialog.dart';
import '../../home/screen/home_screen_widget.dart';
import '../model/parameter_item.dart';
import 'package:hive_ce/hive.dart';

class DrillingChartScreen extends StatefulWidget {
  final WellActive wellActive;
  const DrillingChartScreen({Key? key, required this.wellActive})
      : super(key: key);

  @override
  State<DrillingChartScreen> createState() => _DrillingChartScreenState();
}

class _DrillingChartScreenState extends State<DrillingChartScreen> {
  // Core data & Hive box
  final DrillingController controller = Get.find<DrillingController>();
  final DepthDrillingController depthController = Get.find<DepthDrillingController>();

  Box<ParameterItem>? parameterBox;
  Box<ParameterItem>? depthParameterBox;
  StreamSubscription<BoxEvent>? _paramSub;
  StreamSubscription<BoxEvent>? _depthParameterSub;
  // Loading & UI state
  bool _isDataLoaded = false;
  bool _isSearching = false;
  bool _isDashboardVisible = true;

  // Bottom nav
  int _selectedIndex = 0;
  int _lastInitializedTab = -1;
  String? _multiMode;

  // Single-chart controllers & notifiers
  final PageController _timeCtrl = PageController();
  final PageController _depthCtrl = PageController();
  late final ValueNotifier<int> _timeNotifier = ValueNotifier(0);
  late final ValueNotifier<int> _depthNotifier = ValueNotifier(0);

  // Multi-chart controllers & notifiers
  final PageController _multiCtrl1 = PageController();
  final PageController _multiCtrl2 = PageController();
  late final ValueNotifier<int> _multiNotifier1 = ValueNotifier(0);
  late final ValueNotifier<int> _multiNotifier2 = ValueNotifier(0);

  // For pop‑up menu positioning
  Offset? _tapPosition;

  late DepthConfig _depthConfig;
  bool _depthConfigLoaded = false;
  bool _depthDialogFirstTime = true;

  @override
  void initState() {
    super.initState();

    _loadDepthConfig();
    _setupPageListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      setState(() => _isSearching = true);

      parameterBox = await HiveService.openParameterBox(
          wellApiToken: widget.wellActive.isApiToken
      );
      // If it's a new box and therefore empty, fill it with defaults.
      if (parameterBox!.isEmpty) {
        await HiveService.initializeDefaultData(parameterBox!);
      }
      _paramSub = parameterBox!.watch().listen((_) => setState(() {}));

      // Open the depth parameter box for the specific well
      depthParameterBox = await HiveService.openDepthParameterBox(
          wellApiToken: widget.wellActive.isApiToken
      );
      // If it's a new box and therefore empty, fill it with defaults.
      if (depthParameterBox!.isEmpty) {
        await HiveService.initializeDefaultDepthData(depthParameterBox!);
      }
      _depthParameterSub = depthParameterBox!.watch().listen((_) => setState(() {}));


      _setupSnackbarListeners();

      setState(() => _isDataLoaded = true);

      await controller.initializeLiveTimeData(wellActive: widget.wellActive);

      if(mounted) {
        setState(() {
          _isDataLoaded = true;
          _isSearching = false;
        });
      }

    });

    // Multi‑chart page listeners
    _multiCtrl1.addListener(() {
      _multiNotifier1.value = (_multiCtrl1.page ?? 0).round();
    });
    _multiCtrl2.addListener(() {
      _multiNotifier2.value = (_multiCtrl2.page ?? 0).round();
    });

  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _depthCtrl.dispose();
    _multiCtrl1.dispose();
    _multiCtrl2.dispose();
    _timeNotifier.dispose();
    _depthNotifier.dispose();
    _multiNotifier1.dispose();
    _multiNotifier2.dispose();
    _paramSub?.cancel();
    _depthParameterSub?.cancel();
    controller.deleteData();
    depthController.deleteData();
    super.dispose();
  }

  void _setupPageListeners() {
    _timeCtrl.addListener(() {
      _timeNotifier.value = (_timeCtrl.page ?? 0).round();
    });
    _depthCtrl.addListener(() {
      _depthNotifier.value = (_depthCtrl.page ?? 0).round();
    });
  }

  void _setupSnackbarListeners() {
    ever(controller.transientNotification, (notification) {
      if(notification != null && mounted) {
        _showSnackbar(context, notification);
        controller.transientNotification.value = null;
      }
    });

    ever(depthController.transientNotification, (notification) {
      if(notification != null && mounted) {
        _showSnackbar(context, notification);
        depthController.transientNotification.value = null;
      }
    });

  }

  void _showSnackbar(BuildContext context, dynamic notification) {
    if (notification != null && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final snackBar = SnackBar(
        margin: const EdgeInsets.all(12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: CColors.tertiaryColor.withOpacity(0.95),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(notification.message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      // Reset the value on the specific controller that triggered it
      if (notification == controller.transientNotification.value) {
        controller.transientNotification.value = null;
      } else if (notification == depthController.transientNotification.value) {
        depthController.transientNotification.value = null;
      }
    }
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child:_selectedIndex == 0
          ? FloatingActionButton(
        backgroundColor: CColors.primaryColor,
        onPressed: () {
          Box<ParameterItem> targetBox;

          if (_selectedIndex == 0) {
            targetBox = parameterBox!;
          } else if (_selectedIndex == 1) {
            targetBox = parameterBox!;
          } else if (_selectedIndex == 2) {
            targetBox = depthParameterBox!;
          } else {
            return;
          }
          showDialog(
            context: context,
            builder: (_) => AddParameterDialog(
              wellActive: widget.wellActive,
              parameterBox: targetBox,
              controller: controller,
            ),
          );


        },
        child: const Icon(Icons.add),
      )
          : (_selectedIndex == 1 || _selectedIndex == 2)
          ? FloatingActionButton(
        backgroundColor: CColors.primaryColor,
        onPressed: () => setState(
                () => _isDashboardVisible = !_isDashboardVisible),
        child: Icon(_isDashboardVisible
            ? Icons.visibility_off
            : Icons.visibility),
      )
          : null,
    );
  }

  Future<void> _loadDepthConfig() async {
    final token = widget.wellActive.isApiToken;
    final cfg = await ChartDepthService.loadConfig(token);

    if(cfg.disabled) {
      _depthDialogFirstTime = false;
    }

    if(mounted) {
      setState(() {
        _depthConfig = cfg;
        _depthConfigLoaded = true;
      });
    }
  }

  
  Future<void> _initializeDataForCurrentTab() async {
    if (_selectedIndex == 0) {
      return;
    }

    bool needsInitialLoad = false;
    // --- MODIFIED: Removed check for depth chart (index 2) ---
    if (_selectedIndex == 1 && controller.historicalTimeData.isEmpty) {
      needsInitialLoad = true;
    }

    if (!needsInitialLoad && _selectedIndex == _lastInitializedTab) {
      if (_selectedIndex == 1) controller.updateDisplayedTimeChartData();
      _lastInitializedTab = _selectedIndex;
      return;
    }

    setState(() => _isSearching = true);

    // --- MODIFIED: Removed the logic block for initializing depth data ---
    // The responsibility is now fully within _onDepthTabSelected()

    if (_selectedIndex == 1 || (_multiMode == 'time' && _selectedIndex != 0)) {
      debugPrint("CHART_SCREEN: Initializing Time Chart Data. Current historicalTimeData length: ${controller.historicalTimeData.length}");
      await controller.initializeData(wellActive: widget.wellActive);
      debugPrint("CHART_SCREEN: After controller.initializeData. New historicalTimeData length: ${controller.historicalTimeData.length}, displayedData length: ${controller.displayedData.length}");
    }

    if (mounted) {
      setState(() {
        _isSearching = false;
        _lastInitializedTab = _selectedIndex;
      });
    }
  }

  void _handleTabChange(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
      _multiMode = null;
    });

    // --- THIS IS THE MAIN FIX ---
    // We now have a clear separation of concerns. The depth tab has its own
    // initialization flow, while other tabs use the general method.
    if (index == 2) {
      if (_depthConfigLoaded && !_depthConfig.disabled && _depthDialogFirstTime) {
        _onDepthTabSelected();
      } else if (depthController.depthData.isEmpty) {
        // Otherwise, if data is empty, just initialize it.
        _onDepthTabSelected();
      }
    } else {
      // For all other tabs, initialize data normally.
      _initializeDataForCurrentTab();
    }
  }

  Future<void> _onDepthTabSelected() async {
    if (!_depthConfigLoaded) return;


    if (!_depthConfig.disabled && _depthDialogFirstTime) {

      setState(() {
        _depthDialogFirstTime = false;
      });

      // Show the dialog FIRST.
      final result = await showDialog<DepthConfigResult>(
        barrierDismissible: false,
        context: context,
        builder: (_) => DepthConfigDialog(
          initialStart: _depthConfig.start,
          initialEnd: _depthConfig.end,
        ),
      );

      // Now, fetch data AFTER the dialog is closed.
      if (result == null) {
        // User dismissed the dialog. We can either do nothing or load with
        // default values. Let's load with defaults if data is empty.
        if (depthController.depthData.isEmpty) {
          setState(() => _isSearching = true);
          await depthController.initializeDepthData(wellActive: widget.wellActive);
          setState(() => _isSearching = false);
        }
      } else {
        // User provided a result. Save it and fetch with the new config.
        await ChartDepthService.saveRange(
            widget.wellActive.isApiToken, result.start, result.end);
        if (result.doNotShowAgain) {
          await ChartDepthService.disableDialog(widget.wellActive.isApiToken);
        }

        // Update local config state and clear old data before fetching.
        _depthConfig = DepthConfig(
            start: result.start,
            end: result.end,
            disabled: result.doNotShowAgain
        );

        depthController.depthData.clear();
        setState(() => _isSearching = true);
        await depthController.initializeDepthData(wellActive: widget.wellActive);
        setState(() => _isSearching = false);
      }
    } else {
      // This path is for when the dialog is disabled or has already been shown.
      // Fetch data directly.
      if (depthController.depthData.isEmpty) {
        setState(() => _isSearching = true);
        await depthController.initializeDepthData(wellActive: widget.wellActive);
        setState(() => _isSearching = false);
      } else {
        // If data already exists, just make sure it's displayed.
        depthController.updateDisplayedDepthChartData();
      }
    }
  }

  void _onFieldChanged(String name, dynamic value) {
    setState(() {
      switch (name) {
        case '_isDataLoaded':
          _isDataLoaded = value as bool;
          break;
        case '_isSearching':
          _isSearching = value as bool;
          break;
        case '_isDashboardVisible':
          _isDashboardVisible = value as bool;
          break;
        default:
          break;
      }
    });
  }
  
  void _showChartTypeMenu(int index) async {

    final mode = (index == 1) ? 'time' : 'depth';
    final overlay =
    Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final local =
    overlay.globalToLocal(_tapPosition!);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const barH = kBottomNavigationBarHeight;
    final position = RelativeRect.fromLTRB(
      local.dx,
      local.dy - 125,
      overlay.size.width - local.dx,
      barH + bottomInset,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(
            value: 'single',
            child: Text(
              'Single Track',
              style: TextStyle(color: CColors.primaryColor),
            )),
        PopupMenuItem(
            value: 'multi',
            child: Text(
              'Multi Tracks',
              style: TextStyle(color: CColors.primaryColor),
            )),
      ],
    );
    if (choice != null) {
      setState(() {
        if (choice == 'single') {
          _multiMode = null;
          _selectedIndex = index;
        } else {
          _multiMode = mode;
          _selectedIndex = index;
        }
      });
    }
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onTap: () => _handleTabChange(index),
        onLongPressStart: (details) {
          _tapPosition = details.globalPosition;
          _showChartTypeMenu(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, color: CColors.primaryColor),
            Container(
              height: 2,
              width: 16,
              color: _selectedIndex == index
                  ? CColors.primaryColor
                  : Colors.transparent,
            ),
          ],
        ),
      ),
      label: '',
    );
  }

  BottomNavigationBar _buildBottomNav() => BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: _handleTabChange,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    showSelectedLabels: false,
    showUnselectedLabels: false,
    items: [
      _buildNavItem(Icons.home, 0),
      _buildNavItem(Icons.show_chart, 1),
      _buildNavItem(Icons.show_chart_sharp, 2),
      _buildNavItem(Icons.chat_sharp, 3),
      _buildNavItem(Icons.notifications, 4),
      _buildNavItem(Icons.person_outline, 5)
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (parameterBox == null || depthParameterBox == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      HomeScreenWidget(
        controller: controller,
        depthController: depthController,
        parameterBox: parameterBox,
        depthParameterBox: depthParameterBox,
        currentWell: widget.wellActive,
      ),
      ChartTimePage(
          multiMode: _multiMode,
          trackTypes: parameterBox!.values.map((p) => p.trackType).toSet().toList(),
          controller: controller,
          multiCtrl1: _multiCtrl1,
          multiCtrl2: _multiCtrl2,
          timeCtrl: _timeCtrl,
          multiNotifier1: _multiNotifier1,
          multiNotifier2: _multiNotifier2,
          timeNotifier: _timeNotifier,
          parameterBox: parameterBox,
          isDashboardVisible: _isDashboardVisible,
          wellActive: widget.wellActive,
          onFieldChanged: _onFieldChanged),
      ChartDepthPage(
          multiMode: _multiMode,
          trackTypes: depthParameterBox!.values.map((p) => p.trackType).toSet().toList(),
          controller: depthController,
          multiCtrl1: _multiCtrl1,
          multiCtrl2: _multiCtrl2,
          depthCtrl: _depthCtrl,
          multiNotifier1: _multiNotifier1,
          multiNotifier2: _multiNotifier2,
          depthNotifier: _depthNotifier,
          parameterBox: depthParameterBox,
          isDashboardVisible: _isDashboardVisible,
          wellActive: widget.wellActive,
          onFieldChanged: _onFieldChanged),
      RemarksScreen(wellActive: widget.wellActive),
      NotificationSettingsScreen(wellActive: widget.wellActive),
      const UserSettingsScreen(),
    ];


    return Scaffold(
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(child:pages[_selectedIndex]),
                  ],
                ),
                if(!_isDataLoaded || _isSearching)
                  Positioned.fill(
                      child: Container(
                          color: Colors.white.withOpacity(0.8),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          )
                      )
                  )
              ],
            )
        )
    );
  }

}