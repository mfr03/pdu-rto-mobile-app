import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import '../../../data/services/pdu_api/model/drilling_data.dart';
import '../../../data/services/pdu_api/model/well_active.dart';
import '../../../utils/constants/colors.dart';
import '../components/widget/add_parameter_dialog.dart';
import '../components/widget/home_screen_widget.dart';
import '../components/widget/single_chart_page.dart';
import '../components/widget/single_depth_chart_page.dart';
import '../model/parameter_item.dart';
import 'package:hive_ce/hive.dart';
import 'package:get_it/get_it.dart';

extension DrillingDataExtension on DrillingData {
  num value(String key) {
    final val = rawData[key];
    return val == null ? 0.0 : double.tryParse(val.toString()) ?? 0.0;
  }
}

class DrillingChartScreen extends StatefulWidget {
  final WellActive wellActive;
  const DrillingChartScreen({Key? key, required this.wellActive})
      : super(key: key);

  @override
  State<DrillingChartScreen> createState() => _DrillingChartScreenState();
}

class _DrillingChartScreenState extends State<DrillingChartScreen> {
  // Core data & Hive box
  final DrillingController controller =
  GetIt.instance<DrillingController>();
  Box<ParameterItem>? parameterBox;
  StreamSubscription<BoxEvent>? _paramSub;

  // Loading & UI state
  bool _isDataLoaded = false;
  bool _isSearching = false;
  bool _isDashboardVisible = true;

  // Bottom nav
  int _selectedIndex = 0;
  String? _multiMode; // 'time', 'depth', or null

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

  @override
  void initState() {
    super.initState();
    // Load Hive & data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      parameterBox = await HiveService.openParameterBox();
      _paramSub = parameterBox!.watch().listen((_) => setState(() {}));
      setState(() => _isDataLoaded = true);
      setState(() => _isSearching = true);
      await controller.initializeData(wellActive: widget.wellActive);
      setState(() => _isSearching = false);
      _setupPageListeners();
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

  /// Capitalize helper
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Single chart pages
  List<Widget> get _timeChartPages => ['mechanical', 'mud', 'gas', 'temperature']
      .map((t) => SingleChartPage(
    key: ValueKey('time-$t'),
    title: '${_capitalize(t)} Track',
    mapString: t,
    variableMap: _variableMap(t),
    controller: controller,
    colorMap: {
      for (var p in parameterBox!.values.where((p) => p.trackType == t))
        p.name: p.color
    },
  ))
      .toList();

  List<Widget> get _depthChartPages =>
      ['mechanical', 'mud', 'gas', 'temperature']
          .map((t) => SingleDepthChartPage(
        key: ValueKey('depth-$t'),
        title: '${_capitalize(t)} Depth Track',
        trackType: t,
        variableMap: _variableMap(t),
        controller: controller,
        colorMap: {
          for (var p
          in parameterBox!.values.where((p) => p.trackType == t))
            p.name: p.color
        },
      ))
          .toList();

  Map<String, num Function(DrillingData)> _variableMap(String trackType) {
    return {
      for (var p in parameterBox!.values
          .where((p) => p.trackType == trackType))
        p.name: (d) => d.value(p.jsonKey),
    };
  }

  List<ParameterItem> _buildDashboardParams(int pageIndex) {
    final data = controller.displayedData;
    if (data.isEmpty) return [];
    final last = data.last;
    const tracks = ['mechanical', 'mud', 'gas', 'temperature'];
    final track = tracks[pageIndex];
    return parameterBox!.values
        .where((p) => p.trackType == track)
        .map((p) {
      final raw = last.rawData[p.jsonKey]?.toString() ?? '0';
      final v = double.tryParse(raw) ?? 0.0;
      return p.copyWith(
        value: v.toStringAsFixed(1),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  List<ParameterItem> _dashboardItems(String track, int pageIdx) {
    final data = controller.displayedData;
    if (data.isEmpty) return [];
    final last = data.last;
    return parameterBox!.values
        .where((p) => p.trackType == track)
        .map((p) {
      final raw = last.rawData[p.jsonKey]?.toString() ?? '0';
      final v = double.tryParse(raw) ?? 0.0;
      return p.copyWith(
        value: v.toStringAsFixed(1),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  Widget _buildControlButtons(PageController ctrl) {
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
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.fast_rewind),
              color: CColors.primaryColor,
              onPressed: _isSearching
                  ? null
                  : () async {
                setState(() => _isSearching = true);
                await controller.moveBackward(
                    wellActive: widget.wellActive);
                setState(() => _isSearching = false);
              },
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: CColors.primaryColor,
              onPressed: _isSearching
                  ? null
                  : () {
                controller.reset();
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.fast_forward),
              color: CColors.primaryColor,
              onPressed: _isSearching
                  ? null
                  : () async {
                setState(() => _isSearching = true);
                await controller.fastForward(
                    wellActive: widget.wellActive);
                setState(() => _isSearching = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiChartSection({
    required List<String> tracks,
    required PageController pageController,
    required ValueNotifier<int> pageNotifier,
    required String mode, // 'time' or 'depth'
    bool hideToolbar = false,
    bool hideXAxis = false,
  }) {
    // Build each page as before
    final pages = tracks.map((t) {
      final varMap = <String, num Function(DrillingData)>{
      for (var p in parameterBox!.values.where((p) => p.trackType == t))
      p.name: (d) => d.value(p.jsonKey),
      };
      final colorMap = {
      for (var p in parameterBox!.values.where((p) => p.trackType == t))
      p.name: p.color,
      };
      if (mode == 'time') {
      return SingleChartPage(
      key: ValueKey('multi-$mode-$t'),
      title: _capitalize(t),
      mapString: t,
      variableMap: varMap,
      controller: controller,
      colorMap: colorMap,
      showXAxisLabel: !hideXAxis,
      );
      } else {
      return SingleDepthChartPage(
      key: ValueKey('multi-$mode-$t'),
      title: _capitalize(t),
      trackType: t,
      variableMap: varMap,
      controller: controller,
      colorMap: colorMap,
      );
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Expanded(
          flex: _isDashboardVisible ? 6 : 9,
          child: Stack(
            children: [
              PageView(controller: pageController, children: pages),
              if (!hideToolbar) _buildControlButtons(pageController),
            ],
          ),
        ),

        if (_isDashboardVisible)
          Expanded(
            flex: 4,
            child: ValueListenableBuilder<int>(
              valueListenable: pageNotifier,
              builder: (_, idx, __) {
                final track = tracks[idx % tracks.length];
                return ParameterDashboard(
                  parameterAmount: pages.length,
                  activeIndex: idx + 1,
                  parameters: _dashboardItems(track, idx),
                  parameterBox: parameterBox!,
                  onCardTap: (i) {
                    final newPage = i - 1;
                    pageController.jumpToPage(newPage);
                    pageNotifier.value = newPage;
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTimeTab() {
    if (_multiMode == 'time') {
      return Row(
        children: [
          Expanded(
            child: _buildMultiChartSection(
              tracks: ['mechanical', 'mud'],
              pageController: _multiCtrl1,
              pageNotifier: _multiNotifier1,
              mode: 'time',
              hideToolbar: true,
              hideXAxis: false,
            ),
          ),
          Expanded(
            child: _buildMultiChartSection(
              tracks: ['gas', 'temperature'],
              pageController: _multiCtrl2,
              pageNotifier: _multiNotifier2,
              mode: 'time',
              hideToolbar: false,
              hideXAxis: true,
            ),
          ),
        ],
      );
    } else {
      return SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: _isDashboardVisible ? 6 : 9,
              child: Stack(
                children: [
                  PageView(
                    controller: _timeCtrl,
                    children: _timeChartPages,
                  ),
                  _buildControlButtons(_timeCtrl),
                ],
              ),
            ),
            if (_isDashboardVisible)
              Expanded(
                flex: 4,
                child: ValueListenableBuilder<int>(
                  valueListenable: _timeNotifier,
                  builder: (_, idx, __) => ParameterDashboard(
                    parameterAmount: _timeChartPages.length,
                    activeIndex: _timeNotifier.value + 1,
                    parameters: _buildDashboardParams(_timeNotifier.value),
                    parameterBox: parameterBox!,
                    onCardTap: (i) {
                      final newPage = i - 1;
                      _timeCtrl.jumpToPage(newPage);
                      _timeNotifier.value = newPage;
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildDepthTab() {
    if (_multiMode == 'depth') {
      return Row(
        children: [
          Expanded(
            child: _buildMultiChartSection(
              tracks: ['mechanical', 'mud'],
              pageController: _multiCtrl1,
              pageNotifier: _multiNotifier1,
              mode: 'depth',
              hideToolbar: true,
              hideXAxis: false,
            ),
          ),
          Expanded(
            child: _buildMultiChartSection(
              tracks: ['gas', 'temperature'],
              pageController: _multiCtrl2,
              pageNotifier: _multiNotifier2,
              mode: 'depth',
              hideToolbar: false,
              hideXAxis: true,
            ),
          ),
        ],
      );
    } else {
      return SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: _isDashboardVisible ? 6 : 9,
              child: Stack(
                children: [
                  PageView(
                    controller: _depthCtrl,
                    children: _depthChartPages,
                  ),
                  _buildControlButtons(_depthCtrl),
                ],
              ),
            ),
            if (_isDashboardVisible)
              Expanded(
                flex: 4,
                child: ValueListenableBuilder<int>(
                  valueListenable: _depthNotifier,
                  builder: (_, idx, __) => ParameterDashboard(
                    parameterAmount: _depthChartPages.length,
                    activeIndex: _depthNotifier.value + 1,
                    parameters: _buildDashboardParams(_depthNotifier.value),
                    parameterBox: parameterBox!,
                    onCardTap: (i) {
                      final newPage = i - 1;
                      _depthCtrl.jumpToPage(newPage);
                      _depthNotifier.value = newPage;
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  /// Show inline pop‑up on long‑press
  void _showChartTypeMenu(int index) async {
    // record navIndex → mode
    final mode = (index == 1) ? 'time' : 'depth';
    // convert tap to overlay coords
    final overlay =
    Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final local = overlay.globalToLocal(_tapPosition!);
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
        PopupMenuItem(value: 'single', child: Text('Single Chart')),
        PopupMenuItem(value: 'multi', child: Text('Multi‑Chart')),
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

  /// Bottom‑nav item builder with inline menu
  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onTapDown: (details) {
          _tapPosition = details.globalPosition;
        },
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _multiMode = null;
          });
        },
        onLongPress: (index == 1 || index == 2)
            ? () => _showChartTypeMenu(index)
            : null,
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
    onTap: (i) => setState(() {
      _selectedIndex = i;
      _multiMode = null;
    }),
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
    ],
  );

  @override
  Widget build(BuildContext context) {
    // your five pages
    final pages = [
      HomeScreenWidget(controller: controller, parameterBox: parameterBox!),
      _buildTimeTab(),
      _buildDepthTab(),
      const Center(child: Text('Placeholder 3')),
      const Center(child: Text('Placeholder 4')),
    ];

    return Scaffold(
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        backgroundColor: CColors.primaryColor,
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddParameterDialog(
            wellActive: widget.wellActive,
            parameterBox: parameterBox!,
            controller: controller,
          ),
        ),
        child: const Icon(Icons.add),
      )
          : (_selectedIndex == 1 || _selectedIndex == 2)
          ? FloatingActionButton(
        backgroundColor: CColors.primaryColor,
        onPressed: () =>
            setState(() => _isDashboardVisible = !_isDashboardVisible),
        child: Icon(_isDashboardVisible
            ? Icons.visibility_off
            : Icons.visibility),
      )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // ◀ your normal content
            Column(
              children: [
                Expanded(child: pages[_selectedIndex]),
              ],
            ),

            // ◀ loading overlay
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