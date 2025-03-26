import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/chart_drilling_data.dart';
import '../../../utils/constants/colors.dart';
import '../components/widget/single_chart_page.dart';
import '../components/widget/single_depth_chart_page.dart';
import '../model/parameter_item.dart';
import 'package:hive_ce/hive.dart';
import 'package:get_it/get_it.dart';

class DrillingChartScreen extends StatefulWidget {
  const DrillingChartScreen({Key? key}) : super(key: key);

  @override
  State<DrillingChartScreen> createState() => _DrillingChartScreenState();
}

class _DrillingChartScreenState extends State<DrillingChartScreen> {
  final DrillingController controller = GetIt.instance<DrillingController>();
  Box<ParameterItem>? parameterBox;
  List<ParameterItem> mechanicalParams = [];
  List<ParameterItem> mudParams = [];
  List<ParameterItem> gasParams = [];
  List<ParameterItem> tempParams = [];
  bool _isDataLoaded = false;
  StreamSubscription<BoxEvent>? _parameterBoxSubscription;
  bool _isDashboardVisible = true;

  Object _timeChartPagesKey = Object();
  Object _depthChartPagesKey = Object();

  // Navigation state
  int _selectedIndex = 0;
  late final ValueNotifier<int> _timePageNotifier;
  late final ValueNotifier<int> _depthPageNotifier;

  // Controllers
  final PageController _timePageController = PageController();
  final PageController _depthPageController = PageController();

  @override
  void initState() {
    super.initState();
    _timePageNotifier = ValueNotifier(0);
    _depthPageNotifier = ValueNotifier(0);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeHiveData();
      _setupPageListeners();
    });
  }

  @override
  void dispose() {
    _parameterBoxSubscription?.cancel();
    super.dispose();
  }

  List<Widget> get _timeChartPages {
    return [
      _buildChartPage('Mechanical Track', 'mechanical', _mechanicalVariables),
      _buildChartPage('Mud/Fluid Track', 'mud', _mudVariables),
      _buildChartPage('Gas Track', 'gas', _gasVariables),
      _buildChartPage('Temperature Track', 'temperature', _tempVariables),
    ];
  }

  List<Widget> get _depthChartPages {
    return [
      _buildDepthChartPage('Depth-based Mechanical', _mechanicalVariables),
      _buildDepthChartPage('Depth-based Mud/Fluid', _mudVariables),
      _buildDepthChartPage('Depth-based Gas', _gasVariables),
      _buildDepthChartPage('Depth-based Temperature', _tempVariables),
    ];
  }

  Widget _buildChartPage(String title, String trackType,
      Map<String, num Function(DrillingData)> variables) {
    final colorMap = {
      for (var param in parameterBox!.values.where((p) => p.trackType == trackType))
        param.name: param.color
    };

    return SingleChartPage(
      key: ValueKey('$trackType-$_timeChartPagesKey'),
      title: title,
      mapString: trackType,
      variableMap: variables,
      controller: controller,
      colorMap: colorMap,
    );
  }

  Widget _buildDepthChartPage(String title,
      Map<String, num Function(DrillingData)> variables) {
    final colorMap = {
      for (var param in parameterBox!.values.where((p) => p.trackType == title.split(' ').last.toLowerCase()))
        param.name: param.color
    };

    return SingleDepthChartPage(
      key: ValueKey('${title.split(' ').last}-$_depthChartPagesKey'),
      title: title,
      variableMap: variables,
      controller: controller,
      colorMap: colorMap,
    );
  }

  void _setupPageListeners() {
    _timePageController.addListener(() {
      final newIndex = (_timePageController.page ?? 0).round();
      _timePageNotifier.value = newIndex;
    });

    _depthPageController.addListener(() {
      final newIndex = (_depthPageController.page ?? 0).round();
      _depthPageNotifier.value = newIndex;
    });
  }

  Widget _buildChartAndParameterDashboard() {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: _isDashboardVisible
                ? MediaQuery.of(context).size.height * 0.55
                : MediaQuery.of(context).size.height - 120,
            child: Stack(
              children: [
                PageView(controller: _timePageController, children: _timeChartPages),
                _buildControlButtons(_timePageController, controller),
              ],
            ),
          ),
          if (_isDashboardVisible)
            ValueListenableBuilder<int>(
              valueListenable: _timePageNotifier,
              builder: (context, pageIndex, _) {
                return ParameterDashboard(
                  parameterAmount: _timeChartPages.length,
                  activeIndex: pageIndex + 1,
                  parameters: _buildDashboardParams(pageIndex),
                  parameterBox: parameterBox!,
                  onCardTap: (tappedIndex) => _handlePageTap(tappedIndex, _timePageController),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDepthChartAndParameterDashboard() {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: _isDashboardVisible
                ? MediaQuery.of(context).size.height * 0.55
                : MediaQuery.of(context).size.height - 120,
            child: Stack(
              children: [
                PageView(controller: _depthPageController, children: _depthChartPages),
                _buildControlButtons(_depthPageController, controller),
              ],
            ),
          ),
          if (_isDashboardVisible)
            ValueListenableBuilder<int>(
              valueListenable: _depthPageNotifier,
              builder: (context, pageIndex, _) {
                return ParameterDashboard(
                  parameterAmount: _depthChartPages.length,
                  activeIndex: pageIndex + 1,
                  parameters: _buildDashboardParams(pageIndex),
                  parameterBox: parameterBox!,
                  onCardTap: (tappedIndex) => _handlePageTap(tappedIndex, _depthPageController),
                );
              },
            ),
        ],
      ),
    );
  }

  List<ParameterItem> _buildDashboardParams(int pageIndex) {
    if (controller.displayedData.isEmpty) return [];

    final trackType = _getTrackType(pageIndex);
    final variableMap = _getVariableMap(pageIndex);
    final lastData = controller.displayedData.last;

    return parameterBox!.values
        .where((p) => p.trackType == trackType)
        .map((param) => param.copyWith(
      value: variableMap[param.name]!(lastData).toStringAsFixed(1),
      updatedAt: DateTime.now(),
      color: param.color
    ))
        .toList();
  }

  String _getTrackType(int pageIndex) => ['mechanical', 'mud', 'gas', 'temperature'][pageIndex];

  Widget _buildControlButtons(PageController controller, DrillingController drillingController) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              color: CColors.primaryColor,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.fast_rewind),
              onPressed: () => setState(() => drillingController.moveBackward()),
              color: CColors.primaryColor,
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: drillingController.reset,
              color: CColors.primaryColor,
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.fast_forward),
              onPressed: () => setState(() => drillingController.fastForward()),
              color: CColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePageTap(int tappedIndex, PageController controller) =>
      controller.jumpToPage(tappedIndex - 1);

  void _onNavBarTapped(int index) => setState(() => _selectedIndex = index);

  // Variable mappings
  Map<String, num Function(DrillingData)> get _mechanicalVariables =>
      _createVariableMap('mechanical', _staticMechanicalVariables);

  Map<String, num Function(DrillingData)> get _mudVariables =>
      _createVariableMap('mud', _staticMudVariables);

  Map<String, num Function(DrillingData)> get _gasVariables =>
      _createVariableMap('gas', _staticGasVariables);

  Map<String, num Function(DrillingData)> get _tempVariables =>
      _createVariableMap('temperature', _staticTempVariables);

  Map<String, num Function(DrillingData)> _createVariableMap(
      String trackType, Map<String, num Function(DrillingData)> staticMap) {
    return {
      for (var param in parameterBox!.values.where((p) => p.trackType == trackType))
        if (staticMap.containsKey(param.name))
          param.name: staticMap[param.name]!,
    };
  }

  Map<String, num Function(DrillingData)> _getVariableMap(int pageIndex) {
    final List<Map<String, num Function(DrillingData)>> maps = [
      _mechanicalVariables,
      _mudVariables,
      _gasVariables,
      _tempVariables
    ];
    return maps[pageIndex];
  }

  // Static variable definitions
  static final Map<String, num Function(DrillingData)> _staticMechanicalVariables = {
    'BitDepth (m)': (d) => d.bitDepth,
    'WOB (klb)': (d) => d.wob,
    'Torque (klb.ft)': (d) => d.torque,
    'RPM': (d) => d.rpm,
    'Hkld (klb)': (d) => d.hkld,
  };

  static final Map<String, num Function(DrillingData)> _staticMudVariables = {
    'MudFlowIn (gpm)': (d) => d.mudFlowIn,
    'MudFlowOutp (gpm)': (d) => d.mudFlowOutp,
    'MudCondIn (mmho)': (d) => d.mudCondIn,
    'MudCondOut (mmho)': (d) => d.mudCondOut,
    'SpPress (Psi)': (d) => d.spPress,
    'TankVolTot (bbl)': (d) => d.tankVolTot,
  };

  static final Map<String, num Function(DrillingData)> _staticGasVariables = {
    'H2S_1 (ppm)': (d) => d.h2s_1,
    'CO2_1 (%)': (d) => d.co2_1,
    'Gas (%)': (d) => d.gas,
  };

  static final Map<String, num Function(DrillingData)> _staticTempVariables = {
    'MudTempIn (C)': (d) => d.mudTempIn,
    'MudTempOut (C)': (d) => d.mudTempOut,
  };
  BottomNavigationBar _buildBottomNav() => BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: _onNavBarTapped,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    showSelectedLabels: false,
    showUnselectedLabels: false,
    items: [
      _buildNavItem(Icons.show_chart, 0),
      _buildNavItem(Icons.show_chart_sharp, 1),
      _buildNavItem(Icons.chat_sharp, 2),
      _buildNavItem(Icons.notifications, 3),
    ],
  );

  BottomNavigationBarItem _buildNavItem(IconData icon, int index) => BottomNavigationBarItem(
    icon: Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, color: CColors.primaryColor),
        Container(
          height: 2,
          width: 16,
          color: _selectedIndex == index ? CColors.primaryColor : Colors.transparent,
        ),
      ],
    ),
    label: '',
  );

  Future<void> _initializeHiveData() async {
    try {
      parameterBox = await HiveService.openParameterBox();
      _parameterBoxSubscription = parameterBox!.watch().listen((_) {
        _updateParameterLists();
        setState(() {
          // Reset chart page keys to force recreation
          _timeChartPagesKey = Object();
          _depthChartPagesKey = Object();
        });
      });
      setState(() => _isDataLoaded = true);
    } catch (e) {
      debugPrint("Hive error: $e");
    }
  }

  void _updateParameterLists() {
    mechanicalParams = parameterBox!.values.where((p) => p.trackType == 'mechanical').toList();

    debugPrint('Mechanical Parameters: ${mechanicalParams.map((p) => p.name).toList()}');

    mudParams = parameterBox!.values.where((p) => p.trackType == 'mud').toList();
    gasParams = parameterBox!.values.where((p) => p.trackType == 'gas').toList();
    tempParams = parameterBox!.values.where((p) => p.trackType == 'temperature').toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing drilling data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: [
        _buildChartAndParameterDashboard(),
        _buildDepthChartAndParameterDashboard(),
        const Center(child: Text('Placeholder 3')),
        const Center(child: Text('Placeholder 4')),
      ][_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CColors.primaryColor,
        onPressed: () => setState(() => _isDashboardVisible = !_isDashboardVisible),
        child: Icon(
          _isDashboardVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.white,
        ),
      ),
    );
  }
}