import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/chart_drilling_data.dart';
import '../../../utils/constants/colors.dart';
import '../components/widget/single_chart_page.dart';
import '../components/widget/single_depth_chart_page.dart';
import '../model/ParameterItem.dart';
import 'package:get_it/get_it.dart';

class DrillingChartScreen extends StatefulWidget {
  const DrillingChartScreen({Key? key}) : super(key: key);

  @override
  State<DrillingChartScreen> createState() => _DrillingChartScreenState();
}

class _DrillingChartScreenState extends State<DrillingChartScreen> {
  final DrillingController controller = GetIt.instance<DrillingController>();

  // For the bottom nav
  int _selectedIndex = 0;

  // --- TIME-BASED CHART STUFF ---
  final PageController _timePageController = PageController();
  int _timePageViewIndex = 0;
  late final List<Widget> _timeChartPages;

  // --- DEPTH-BASED CHART STUFF ---
  final PageController _depthPageController = PageController();
  int _depthPageViewIndex = 0;
  late final List<Widget> _depthChartPages;

  @override
  void initState() {
    super.initState();

    // Listen to the time-based PageView
    _timePageController.addListener(() {
      final page = _timePageController.page ?? 0.0;
      final newIndex = page.round();
      if (newIndex != _timePageViewIndex) {
        setState(() => _timePageViewIndex = newIndex);
      }
    });

    // Listen to the depth-based PageView
    _depthPageController.addListener(() {
      final page = _depthPageController.page ?? 0.0;
      final newIndex = page.round();
      if (newIndex != _depthPageViewIndex) {
        setState(() => _depthPageViewIndex = newIndex);
      }
    });

    // Build the list of time-based chart pages
    _timeChartPages = [
      SingleChartPage(
        title: 'Mechanical Track',
        mapString: 'mechanical',
        variableMap: _mechanicalVariables,
        controller: controller,
      ),
      SingleChartPage(
        title: 'Mud/Fluid Track',
        mapString: 'mud',
        variableMap: _mudVariables,
        controller: controller,
      ),
      SingleChartPage(
        title: 'Gas Track',
        mapString: 'gas',
        variableMap: _gasVariables,
        controller: controller,
      ),
      SingleChartPage(
        title: 'Temperature Track',
        mapString: 'temperature',
        variableMap: _tempVariables,
        controller: controller,
      ),
    ];

    // Build the list of depth-based chart pages
    _depthChartPages = [
      SingleDepthChartPage(
        title: 'Depth-based Mechanical',
        variableMap: _mechanicalVariables,
        controller: controller,
      ),
      SingleDepthChartPage(
        title: 'Depth-based Mud/Fluid',
        variableMap: _mudVariables,
        controller: controller,
      ),
      SingleDepthChartPage(
        title: 'Depth-based Gas',
        variableMap: _gasVariables,
        controller: controller,
      ),
      SingleDepthChartPage(
        title: 'Depth-based Temperature',
        variableMap: _tempVariables,
        controller: controller,
      ),
    ];
  }

  Widget _buildChartAndParameterDashboard() {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Stack(
              children: [
                PageView(
                  controller: _timePageController,
                  children: _timeChartPages,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          color: CColors.primaryColor,
                          onPressed: () {
                            // track settings
                          },
                          tooltip: 'Track Settings',
                        ),
                        IconButton(
                          icon: const Icon(Icons.fast_rewind),
                          onPressed: controller.moveBackward,
                          tooltip: 'Backward',
                          color: CColors.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: controller.reset,
                          tooltip: 'Refresh',
                          color: CColors.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.fast_forward),
                          onPressed: controller.fastForward,
                          tooltip: 'Forward',
                          color: CColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            return ParameterDashboard(
              parameterAmount: _timeChartPages.length,
              activeIndex: _timePageViewIndex + 1,
              parameters: _buildDashboardParamsForTime(_timePageViewIndex),
              onCardTap: (int tappedIndex) {
                _timePageController.jumpToPage(tappedIndex - 1);
              },
            );
          }),
        ],
      ),
    );
  }

  List<ParameterItem> _buildDashboardParamsForTime(int pageIndex) {
    if (controller.displayedData.isEmpty) {
      return [const ParameterItem(name: 'No data', value: '-', color: Colors.grey)];
    }
    final lastData = controller.displayedData.last;

    Map<String, num Function(DrillingData)> selectedMap;
    Map<String, Color> colorMap;

    switch (pageIndex) {
      case 0:
        selectedMap = _mechanicalVariables;
        colorMap = _mechanicalColors;
        break;
      case 1:
        selectedMap = _mudVariables;
        colorMap = _mudColors;
        break;
      case 2:
        selectedMap = _gasVariables;
        colorMap = _gasColors;
        break;
      case 3:
        selectedMap = _tempVariables;
        colorMap = _tempColors;
        break;
      default:
        return [];
    }

    return selectedMap.entries.map<ParameterItem>((entry) {
      final rawValue = entry.value(lastData);
      final valueString = rawValue.toStringAsFixed(1);
      final varColor = colorMap[entry.key] ?? Colors.blue;
      return ParameterItem(name: entry.key, value: valueString, color: varColor);
    }).toList();
  }

  Widget _buildDepthChartAndParameterDashboard() {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Stack(
              children: [
                PageView(
                  controller: _depthPageController,
                  children: _depthChartPages,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          color: CColors.primaryColor,
                          onPressed: () {
                            // track settings
                          },
                          tooltip: 'Track Settings',
                        ),
                        IconButton(
                          icon: const Icon(Icons.fast_rewind),
                          onPressed: controller.moveBackward,
                          tooltip: 'Backward',
                          color: CColors.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: controller.reset,
                          tooltip: 'Refresh',
                          color: CColors.primaryColor
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.fast_forward),
                          onPressed: controller.fastForward,
                          tooltip: 'Forward',
                          color: CColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            return ParameterDashboard(
              parameterAmount: _depthChartPages.length,
              activeIndex: _depthPageViewIndex + 1,
              parameters: _buildDashboardParamsForDepth(_depthPageViewIndex),
              onCardTap: (int tappedIndex) {
                _depthPageController.jumpToPage(tappedIndex - 1);
              },
            );
          }),
        ],
      ),
    );
  }

  List<ParameterItem> _buildDashboardParamsForDepth(int pageIndex) {
    if (controller.displayedData.isEmpty) {
      return [const ParameterItem(name: 'No data', value: '-', color: Colors.grey)];
    }
    final lastData = controller.displayedData.last;

    Map<String, num Function(DrillingData)> selectedMap;
    Map<String, Color> colorMap;

    switch (pageIndex) {
      case 0:
        selectedMap = _mechanicalVariables;
        colorMap = _mechanicalColors;
        break;
      case 1:
        selectedMap = _mudVariables;
        colorMap = _mudColors;
        break;
      case 2:
        selectedMap = _gasVariables;
        colorMap = _gasColors;
        break;
      case 3:
        selectedMap = _tempVariables;
        colorMap = _tempColors;
        break;
      default:
        return [];
    }

    return selectedMap.entries.map<ParameterItem>((entry) {
      final rawValue = entry.value(lastData);
      final valueString = rawValue.toStringAsFixed(1);
      final varColor = colorMap[entry.key] ?? Colors.blue;
      return ParameterItem(name: entry.key, value: valueString, color: varColor);
    }).toList();
  }

  // For bottom nav
  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Example color maps for each track type
  Map<String, Color> get _mechanicalColors => {
    'BitDepth (m)': Colors.green,
    'WOB (klb)': Colors.purple,
    'Torque (klb.ft)': Colors.blue,
    'RPM': Colors.red,
    'Hkld (klb)': Colors.teal,
  };

  Map<String, Color> get _mudColors => {
    'MudFlowIn (gpm)': Colors.red,
    'MudFlowOutp (gpm)': Colors.blue,
    'MudCondIn (mmho)': Colors.green,
    'MudCondOut (mmho)': Colors.purple,
    'SpPress (Psi)': Colors.orange,
    'TankVolTot (bbl)': Colors.brown,
  };

  Map<String, Color> get _gasColors => {
    'H2S_1 (ppm)': Colors.deepOrange,
    'CO2_1 (%)': Colors.green,
    'Gas (%)': Colors.red,
  };

  Map<String, Color> get _tempColors => {
    'MudTempIn (C)': Colors.blue,
    'MudTempOut (C)': Colors.red,
  };

  // Example variable maps for each track
  Map<String, num Function(DrillingData)> get _mechanicalVariables => {
    'BitDepth (m)': (d) => d.bitDepth,
    'WOB (klb)': (d) => d.wob,
    'Torque (klb.ft)': (d) => d.torque,
    'RPM': (d) => d.rpm,
    'Hkld (klb)': (d) => d.hkld,
  };

  Map<String, num Function(DrillingData)> get _mudVariables => {
    'MudFlowIn (gpm)': (d) => d.mudFlowIn,
    'MudFlowOutp (gpm)': (d) => d.mudFlowOutp,
    'MudCondIn (mmho)': (d) => d.mudCondIn,
    'MudCondOut (mmho)': (d) => d.mudCondOut,
    'SpPress (Psi)': (d) => d.spPress,
    'TankVolTot (bbl)': (d) => d.tankVolTot,
  };

  Map<String, num Function(DrillingData)> get _gasVariables => {
    'H2S_1 (ppm)': (d) => d.h2s_1,
    'CO2_1 (%)': (d) => d.co2_1,
    'Gas (%)': (d) => d.gas,
  };

  Map<String, num Function(DrillingData)> get _tempVariables => {
    'MudTempIn (C)': (d) => d.mudTempIn,
    'MudTempOut (C)': (d) => d.mudTempOut,
  };

  @override
  Widget build(BuildContext context) {
    // Each item here is a different "tab" or screen
    final screens = [
      _buildChartAndParameterDashboard(),     // Time-based
      _buildDepthChartAndParameterDashboard(),// Depth-based
      const Center(child: Text('Placeholder 3')),
      const Center(child: Text('Placeholder 4')),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.show_chart, 0),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.show_chart_sharp, 1),
            label: 'Depth',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.chat_sharp, 2),
            label: 'Screen3',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.notifications, 3),
            label: 'Screen4',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isActive = (index == _selectedIndex);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(
          icon,
          color: CColors.primaryColor,
        ),
        Container(
          height: 2,
          width: 16,
          color: isActive ? CColors.primaryColor : Colors.transparent,
        ),
      ],
    );
  }
}