import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/model/depth_config.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/model/depth_config_result.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/depth_config_dialog.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/page/chart_depth_page.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/page/chart_time_page.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/notification/screen/notification_settings_screen.dart';
import 'package:pdu_mobile_rto_app/features/profiles/screen/user_settings_screen.dart';
import '../../../data/services/pdu_api/model/well_active.dart';
import '../../../utils/constants/colors.dart';
import '../components/widget/dialog/add_parameter_dialog.dart';
import '../../home/screen/home_screen_widget.dart';
import '../model/parameter_item.dart';
import 'package:hive_ce/hive.dart';
import 'package:get_it/get_it.dart';

class DrillingChartScreen extends StatefulWidget {
  final WellActive wellActive;
  const DrillingChartScreen({Key? key, required this.wellActive})
      : super(key: key);

  @override
  State<DrillingChartScreen> createState() => _DrillingChartScreenState();
}

class _DrillingChartScreenState extends State<DrillingChartScreen> {
  // Core data & Hive box
  final DrillingController controller = GetIt.instance<DrillingController>();
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

  Timer? _realtimeHomeTimer;
  bool _isWellConsideredLive = true;

  late DepthConfig _depthConfig;
  bool _depthConfigLoaded = false;
  bool _depthDialogFirstTime = true;

  @override
  void initState() {
    super.initState();
    final wellEndDate = DateTime.parse(widget.wellActive.endDate);
    final now = DateTime.now();

    if(wellEndDate != null && wellEndDate.isBefore(now)) {
      _isWellConsideredLive = false;
    } else {
      _isWellConsideredLive = true;
    }


    _loadDepthConfig();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      setState(() => _isSearching = true);

      // TODO(a null safety net if boxes arent opening properly)
      parameterBox = await HiveService.openParameterBox();
      _paramSub = parameterBox!.watch().listen((_) => setState(() {}));

      depthParameterBox = await HiveService.openDepthParameterBox();
      _depthParameterSub = depthParameterBox!.watch().listen((_) => setState(() {}));


      _setupPageListeners();

      setState(() => _isDataLoaded = true);

      if(_isWellConsideredLive) {
        await controller.initializeLiveTimeData(wellActive: widget.wellActive);

        _startRealtimeHomeUpdates();
      } else {
        await controller.initializeHistoricalTimeDataForHome(wellActive: widget.wellActive);
      }

      // This call should not depend on _depthConfig.disabled here.
      // The _onDepthTabSelected handles showing the dialog based on _depthConfig.disabled
      // and _depthDialogFirstTime in the build method.
      // So, if depth data is needed regardless of dialog state, it should be initialized.
      // For now, retaining original logic as it was, assuming _depthConfig.disabled implies
      // that the dialog is not to be shown and data is always initialized if disabled.
      if (_depthConfigLoaded && _depthConfig.disabled) {
        await controller.initializeDepthData(wellActive: widget.wellActive);
      }

      await controller.setActiveWellForNotifications(widget.wellActive);

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

    // The _startRealtimeHomeUpdates is called twice, remove one.
    // _startRealtimeHomeUpdates();
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
    _realtimeHomeTimer?.cancel();
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

  void _startRealtimeHomeUpdates() {
    _realtimeHomeTimer?.cancel();
    _realtimeHomeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_isWellConsideredLive) {
        timer.cancel();
        return;
      }

      bool isTimeChartActiveAndAtLiveEdge = false;
      if(_selectedIndex == 1) {
        if(controller.historicalTimeData.isNotEmpty) {
          int currentlyVisibleEndIndex = controller.timeChartCurrentIndex.value + controller.displayedDataPoints;
          if(currentlyVisibleEndIndex >= controller.historicalTimeData.length) {
            isTimeChartActiveAndAtLiveEdge = true;
          }
        } else {
          isTimeChartActiveAndAtLiveEdge = true;
        }
      }

      controller.fetchAndUpdateLatestLiveTimeData(
          wellActive: widget.wellActive,
          shouldAutoScrollTimeChart: isTimeChartActiveAndAtLiveEdge
      );
    });
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
    if (_selectedIndex == 1 && controller.historicalTimeData.isEmpty) {
      needsInitialLoad = true;
    } else if (_selectedIndex == 2 && controller.depthData.isEmpty) {
      needsInitialLoad = true;
    }

    if (!needsInitialLoad && _selectedIndex == _lastInitializedTab) {
      if (_selectedIndex == 1) controller.updateDisplayedTimeChartData();
      if (_selectedIndex == 2) controller.updateDisplayedDepthChartData();
      _lastInitializedTab = _selectedIndex;
      return;
    }

    setState(() => _isSearching = true);

    if (_selectedIndex == 2 || (_multiMode == 'depth' && _selectedIndex != 0)) {
      debugPrint("Initializing depth data for chart tab.");
      await controller.initializeDepthData(wellActive: widget.wellActive);
    } else if (_selectedIndex == 1 || (_multiMode == 'time' && _selectedIndex != 0)) {
      print("CHART_SCREEN: Initializing Time Chart Data. Current historicalTimeData length: ${controller.historicalTimeData.length}");
      await controller.initializeData(wellActive: widget.wellActive); // This is your historical loader
      print("CHART_SCREEN: After controller.initializeData. New historicalTimeData length: ${controller.historicalTimeData.length}, displayedData length: ${controller.displayedData.length}");
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
    _initializeDataForCurrentTab();
  }

  // Corrected _onDepthTabSelected function
  Future<void> _onDepthTabSelected() async {
    if (!_depthConfigLoaded) return;

    // Condition to show the dialog
    if (!_depthConfig.disabled && _depthDialogFirstTime) {
      final result = await showDialog<DepthConfigResult>(
        context: context,
        builder: (_) => DepthConfigDialog(
          initialStart: _depthConfig.start,
          initialEnd: _depthConfig.end,
        ),
      );

      if (result == null) {
        // User dismissed dialog without saving or explicit action.
        _depthDialogFirstTime = false; // <<< Moved this line here
        if (controller.depthData.isEmpty) {
          setState(() => _isSearching = true);
          await controller.initializeDepthData(wellActive: widget.wellActive);
          setState(() => _isSearching = false);
        } else {
          controller.updateDisplayedDepthChartData();
        }
      } else {
        // User interacted with dialog and provided a result.
        await ChartDepthService.saveRange(
            widget.wellActive.isApiToken, result.start, result.end);
        if (result.doNotShowAgain) {
          await ChartDepthService.disableDialog(widget.wellActive.isApiToken);
          _depthConfig =
              DepthConfig(start: result.start, end: result.end, disabled: true);
        } else {
          _depthConfig =
              DepthConfig(start: result.start, end: result.end, disabled: false);
        }

        _depthDialogFirstTime = false; // <<< Moved this line here
        controller.depthData.clear();
        setState(() => _isSearching = true);
        await controller.initializeDepthData(wellActive: widget.wellActive);
        setState(() => _isSearching = false);
      }
    } else {
      // This path is taken if the dialog was previously disabled, or it's not the first time
      // and not disabled. Just initialize/update data normally.
      if (controller.depthData.isEmpty) {
        setState(() => _isSearching = true);
        await controller.initializeDepthData(wellActive: widget.wellActive);
        setState(() => _isSearching = false);
      } else {
        controller.updateDisplayedDepthChartData();
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
    overlay.globalToLocal(_tapPosition!); // now guaranteed non-null
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const barH = kBottomNavigationBarHeight;
    // anchor menu just above nav bar:
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
        // remove onTapDown entirely
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _multiMode = null;
          });
        },
        // use onLongPressStart to grab the position reliably
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
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // your five pages
    final pages = [
      HomeScreenWidget(
        controller: controller,
        parameterBox: parameterBox,
        depthParameterBox: depthParameterBox,
        isWellLive: _isWellConsideredLive,
        currentWellApiToken: widget.wellActive.isApiToken,
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
          controller: controller,
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
      const Center(child: Text('Placeholder 3')),
      NotificationSettingsScreen(wellActive: widget.wellActive),
      const UserSettingsScreen(),
    ];


    if(_selectedIndex == 2 && _depthConfigLoaded && !_depthConfig.disabled && _depthDialogFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onDepthTabSelected();
      });
    }

    return Scaffold(
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 16),
        child:_selectedIndex == 0
            ? FloatingActionButton(
          backgroundColor: CColors.primaryColor,
          onPressed: () {
            Box<ParameterItem> targetBox;

            if (_selectedIndex == 0) { // Home - Time
              targetBox = parameterBox!;
            } else if (_selectedIndex == 1) { // Time Chart
              targetBox = parameterBox!;
            } else if (_selectedIndex == 2) { // Depth Chart
              targetBox = depthParameterBox!;
            } else {
              return; // Or handle error
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: pages[_selectedIndex]),
              ],
            ),

            if (!_isDataLoaded || _isSearching)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}