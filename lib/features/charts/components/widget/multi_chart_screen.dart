import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/single_chart_page.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/single_depth_chart_page.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import '../../../../utils/constants/colors.dart';
import '../../model/parameter_item.dart';

class MultiChartScreen extends StatefulWidget {
  final DrillingController controller;
  final Box<ParameterItem> parameterBox;
  final WellActive wellActive;   // ← new
  final String mode;
  // 'time' or 'depth'

  const MultiChartScreen({
    Key? key,
    required this.controller,
    required this.parameterBox,
    required this.wellActive,    // ← new
    required this.mode,
  }) : super(key: key);

  @override
  _MultiChartScreenState createState() => _MultiChartScreenState();
}

class _MultiChartScreenState extends State<MultiChartScreen> {
  late final PageController _ctrl1 = PageController();
  late final PageController _ctrl2 = PageController();
  late final ValueNotifier<int> _not1 = ValueNotifier(0);
  late final ValueNotifier<int> _not2 = ValueNotifier(0);
  bool _dashVisible = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl1.addListener(() => _not1.value = (_ctrl1.page ?? 0).round());
    _ctrl2.addListener(() => _not2.value = (_ctrl2.page ?? 0).round());
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _not1.dispose();
    _not2.dispose();
    super.dispose();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  final List<String> _firstTwo = ['mechanical', 'mud'];
  final List<String> _lastTwo  = ['gas', 'temperature'];


  List<ParameterItem> _dashboardItems(String track, int pageIdx) {
    final data = widget.controller.displayedData;
    if (data.isEmpty) return [];
    final last = data.last;
    return widget.parameterBox.values
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
            // (you can wire this up later)
            IconButton(
              icon: const Icon(Icons.settings),
              color: CColors.primaryColor,
              onPressed: () {},
            ),

            // ← Move Backwards
            IconButton(
              icon: const Icon(Icons.fast_rewind),
              color: CColors.primaryColor,
              onPressed: _isLoading
                  ? null
                  : () async {
                setState(() => _isLoading = true);
                await widget.controller.moveBackward(
                  wellActive: widget.wellActive,
                );
                setState(() => _isLoading = false);
              },
            ),
            const SizedBox(height: 8),

            // ← Reset
            IconButton(
              icon: const Icon(Icons.refresh),
              color: CColors.primaryColor,
              onPressed: _isLoading
                  ? null
                  : () {
                widget.controller.reset();
                setState(() {}); // force rebuild
              },
            ),
            const SizedBox(height: 8),

            // ← Move Forward
            IconButton(
              icon: const Icon(Icons.fast_forward),
              color: CColors.primaryColor,
              onPressed: _isLoading
                  ? null
                  : () async {
                setState(() => _isLoading = true);
                await widget.controller.fastForward(
                  wellActive: widget.wellActive,
                );
                setState(() => _isLoading = false);
              },
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    // ── Otherwise, your existing layout ────────────────────────
    final firstTracks  = ['mechanical', 'mud'];
    final secondTracks = ['gas', 'temperature'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_capitalize(widget.mode)} Multi‑Chart'),
        backgroundColor: CColors.primaryColor,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_dashVisible ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _dashVisible = !_dashVisible),
      ),
      body: Stack(
        children: [
          // ── Your existing SafeArea / Row of charts ───────────────────
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: _buildMultiChartSection(
                    tracks: _firstTwo,
                    pageController: _ctrl1,
                    pageNotifier: _not1,
                    hideToolbar: true,
                    hideXAxis: false,
                  ),
                ),
                Expanded(
                  child: _buildMultiChartSection(
                    tracks: _lastTwo,
                    pageController: _ctrl2,
                    pageNotifier: _not2,
                    hideToolbar: false,
                    hideXAxis: true,
                  ),
                ),
              ],
            ),
          ),

          // ── Loading overlay ─────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// Updated helper with two new flags
  Widget _buildMultiChartSection({
    required List<String> tracks,
    required PageController pageController,
    required ValueNotifier<int> pageNotifier,
    bool hideToolbar = false,
    bool hideXAxis    = false,
  }) {
    final pages = tracks.map((t) {
      // build your varMap & colorMap as before…
      final varMap = <String, num Function(DrillingData)>{
        for (var p in widget.parameterBox.values.where((p) => p.trackType == t))
          p.name: (DrillingData d) => d.value(p.jsonKey),
      };
      final colorMap = {
        for (var p in widget.parameterBox.values.where((p) => p.trackType == t))
          p.name: p.color,
      };

      // pass showXAxisLabel = !hideXAxis
      if (widget.mode == 'time') {
        return SingleChartPage(
          key: ValueKey('multi-$t'),
          title: _capitalize(t),
          mapString: t,
          variableMap: varMap,
          controller: widget.controller,
          colorMap: colorMap,
          showXAxisLabel: !hideXAxis,   // ← USE FLAG
        );
      } else {
        return SingleDepthChartPage(
          key: ValueKey('multi-depth-$t'),
          title: _capitalize(t),
          trackType: t,
          variableMap: varMap,
          controller: widget.controller,
          colorMap: colorMap,
        );
      }
    }).toList();

    return Column(
      children: [
        // chart area
        Expanded(
          flex: _dashVisible ? 6 : 9,
          child: Stack(
            children: [
              PageView(controller: pageController, children: pages),
              if (!hideToolbar)               // ← CONDITIONAL OVERLAY
                _buildControlButtons(pageController),
            ],
          ),
        ),

        // dashboard area
        if (_dashVisible)
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
                  parameterBox: widget.parameterBox,
                  onCardTap: (i) => pageController.jumpToPage(i - 1),
                );
              },
            ),
          ),
      ],
    );
  }
}