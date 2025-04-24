// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:get/get.dart';
// import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
//
// class DrillingChartScreenPair extends StatelessWidget {
//   final DrillingController controller = Get.put(DrillingController());
//   final PageController _pageController = PageController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pair'),
//       ),
//       body: Stack(
//         children: [
//
//           Obx(() {
//
//             final page1 = _buildTwoTrackPage(
//                 leftTitle: 'Mechanical Track',
//                 rightMapString: 'mud',
//                 leftMap: _mechanicalVariables,
//                 leftMapString: 'mechanical',
//                 rightTitle: 'Mud/Fluid Track',
//                 rightMap: _mudVariables
//             );
//
//             final page2 = _buildTwoTrackPage(
//                 leftTitle: 'Gas Track',
//                 rightMapString: 'temperature',
//                 leftMap: _gasVariables,
//                 rightTitle: 'Temperature Track',
//                 leftMapString: 'gas',
//                 rightMap: _tempVariables
//             );
//
//             return PageView(
//               controller: _pageController,
//               children: [page1, page2],
//             );
//           }),
//
//           Align(
//             alignment: Alignment.centerRight,
//             child: Padding(
//               padding: const EdgeInsets.only(right: 16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.fast_rewind),
//                     onPressed: controller.moveBackward,
//                     tooltip: 'Backward',
//                   ),
//                   const SizedBox(height: 8),
//                   IconButton(
//                     icon: const Icon(Icons.refresh),
//                     onPressed: controller.reset,
//                     tooltip: 'Refresh',
//                   ),
//                   const SizedBox(height: 8),
//                   IconButton(
//                     icon: const Icon(Icons.fast_forward),
//                     onPressed: controller.fastForward,
//                     tooltip: 'Forward',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTwoTrackPage({
//     required String leftTitle,
//     required String rightMapString,
//     required Map<String, num Function(DrillingData)> leftMap,
//     required String rightTitle,
//     required String leftMapString,
//     required Map<String, num Function(DrillingData)> rightMap,
//   }) {
//     TrackballBehavior _leftTrackball = TrackballBehavior(
//         enable: true,
//         tooltipSettings: const InteractiveTooltip(
//             enable: true,
//             textStyle: TextStyle(fontSize: 8)
//         ),
//         tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
//         activationMode: ActivationMode.singleTap
//     );
//     TrackballBehavior _rightTrackball = TrackballBehavior(
//         enable: true,
//         tooltipSettings: const InteractiveTooltip(
//             enable: true,
//             textStyle: TextStyle(fontSize: 8)
//         ),
//         tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
//         activationMode: ActivationMode.singleTap
//     );
//     Offset? _position;
//
//     return Row(
//       children: [
//
//         Expanded(
//           flex: 1,
//           child: _buildTrackChart(
//             title: leftTitle,
//             mapString: leftMapString,
//             variableMap: leftMap,
//             dateTimeAxis: DateTimeAxis(
//               isVisible: true,
//               isInversed: true,
//             ),
//
//             numericAxis: NumericAxis(
//               opposedPosition: true,
//             ),
//             trackballOwn: _leftTrackball,
//             trackballFriend: _rightTrackball,
//             position: _position,
//           ),
//         ),
//
//         Expanded(
//           flex: 1,
//           child: _buildTrackChart(
//             title: rightTitle,
//             mapString: rightMapString,
//             variableMap: rightMap,
//             dateTimeAxis: DateTimeAxis(
//               isVisible: true,
//               isInversed: true,
//               labelStyle: const TextStyle(fontSize: 0),
//               majorTickLines: const MajorTickLines(size: 0),
//               axisLine: const AxisLine(width: 1),
//               // majorGridLines: const MajorGridLines(width: 0),
//             ),
//             numericAxis: NumericAxis(
//               opposedPosition: true,
//             ),
//             trackballOwn: _rightTrackball,
//             trackballFriend: _leftTrackball,
//             position: _position,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTrackChart({
//     required String title,
//     required String mapString,
//     required Map<String, num Function(DrillingData)> variableMap,
//     required DateTimeAxis dateTimeAxis,
//     required NumericAxis numericAxis,
//     required TrackballBehavior trackballOwn,
//     required TrackballBehavior trackballFriend,
//     required Offset? position,
//   }) {
//     bool _isInteractive = false;
//
//     return Container(
//       padding: const EdgeInsets.all(8),
//       child: SfCartesianChart(
//         isTransposed: true, // rotate X=vertical, Y=horizontal
//         title: ChartTitle(
//           text: title,
//           textStyle: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         legend: Legend(isVisible: true),
//         plotAreaBorderWidth: 1,
//         plotAreaBorderColor: Colors.grey,
//
//         primaryXAxis: dateTimeAxis,
//         primaryYAxis: numericAxis,
//
//         onChartTouchInteractionDown: (ChartTouchInteractionArgs tap) {
//           _isInteractive = true;
//         },
//
//         onChartTouchInteractionUp: (ChartTouchInteractionArgs tap) {
//           _isInteractive = false;
//           trackballFriend.hide();
//         },
//
//         onTrackballPositionChanging: (TrackballArgs args) {
//           if(_isInteractive) {
//             debugPrint(controller.seriesControllers.values.length.toString());
//             position = controller.seriesControllers[mapString]!.pointToPixel(
//                 args.chartPointInfo.chartPoint!);
//             trackballFriend.show(position!.dx, position!.dy, 'pixel');
//           }
//         },
//
//         trackballBehavior: trackballOwn,
//
//         zoomPanBehavior: ZoomPanBehavior(
//         ),
//         series: _generateSeriesList(controller.displayedData.toList(), variableMap, mapString),
//       ),
//     );
//   }
//
//   List<CartesianSeries<dynamic, dynamic>> _generateSeriesList(
//       List<DrillingData> data,
//       Map<String, num Function(DrillingData)> variableMap,
//       String mapString
//       ) {
//     return variableMap.entries
//         .map<LineSeries<DrillingData, DateTime>>((entry) {
//       return LineSeries<DrillingData, DateTime>(
//         name: entry.key,
//         dataSource: data,
//         xValueMapper: (DrillingData d, _) => d.dateTime,
//         yValueMapper: (DrillingData d, _) => entry.value(d),
//         markerSettings: const MarkerSettings(isVisible: true),
//         onRendererCreated: (ChartSeriesController ctl) {
//           controller.storeSeriesController(mapString, ctl);
//         },
//       );
//     })
//         .toList();
//   }
//
//   Map<String, num Function(DrillingData)> get _mechanicalVariables => {
//     'BitDepth (m)': (d) => d.bitDepth,
//     'WOB (klb)': (d) => d.wob,
//     'Torque (klb.ft)': (d) => d.torque,
//     'RPM': (d) => d.rpm,
//     'Hkld (klb)': (d) => d.hkld,
//   };
//
//   Map<String, num Function(DrillingData)> get _mudVariables => {
//     'MudFlowIn (gpm)': (d) => d.mudFlowIn,
//     'MudFlowOutp': (d) => d.mudFlowOutp,
//     'MudCondIn (mmho)': (d) => d.mudCondIn,
//     'MudCondOut (mmho)': (d) => d.mudCondOut,
//     'SpPress (Psi)': (d) => d.spPress,
//     'TankVolTot (bbl)': (d) => d.tankVolTot,
//   };
//
//   Map<String, num Function(DrillingData)> get _gasVariables => {
//     'H2S_1 (ppm)': (d) => d.h2s_1,
//     'CO2_1 (%)': (d) => d.co2_1,
//     'Gas (%)': (d) => d.gas,
//   };
//
//   Map<String, num Function(DrillingData)> get _tempVariables => {
//     'MudTempIn (C)': (d) => d.mudTempIn,
//     'MudTempOut (C)': (d) => d.mudTempOut,
//   };
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // class DrillingChartScreenPair extends StatelessWidget {
// //   final DrillingController controller = Get.put(DrillingController());
// //   final PageController _pageController = PageController();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Swipe through Track Pairs (Vertical Time Axis)'),
// //       ),
// //       body: Stack(
// //         children: [
// //           // -- The "background" is a PageView of pairs of charts --
// //           Obx(() {
// //             final data = controller.displayedData.toList();
// //
// //             // Build two "pages," each containing a row with two charts.
// //             final page1 = _buildTwoTrackPage(
// //               leftTitle: 'Mechanical Track',
// //               leftSeries: _generateSeriesList(data, _mechanicalVariables),
// //               rightTitle: 'Mud/Fluid Track',
// //               rightSeries: _generateSeriesList(data, _mudVariables),
// //             );
// //
// //             final page2 = _buildTwoTrackPage(
// //               leftTitle: 'Gas Track',
// //               leftSeries: _generateSeriesList(data, _gasVariables),
// //               rightTitle: 'Temperature Track',
// //               rightSeries: _generateSeriesList(data, _tempVariables),
// //             );
// //
// //             return PageView(
// //               controller: _pageController,
// //               children: [page1, page2],
// //             );
// //           }),
// //
// //           // -- Floating buttons on right side, centered vertically --
// //           Align(
// //             alignment: Alignment.centerRight,
// //             child: Padding(
// //               padding: const EdgeInsets.only(right: 16),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   ElevatedButton(
// //                     onPressed: controller.moveBackward,
// //                     child: const Text('Backward'),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   ElevatedButton(
// //                     onPressed: controller.reset,
// //                     child: const Text('Reset'),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   ElevatedButton(
// //                     onPressed: controller.fastForward,
// //                     child: const Text('Forward'),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   /// Creates one "page" containing TWO charts side-by-side:
// //   ///  - Left chart: fully labeled time axis
// //   ///  - Right chart: time axis is present (for bounding box & gridlines),
// //   ///    but the time labels/ticks are hidden (so we only see numeric labels).
// //   Widget _buildTwoTrackPage({
// //     required String leftTitle,
// //     required List<CartesianSeries<dynamic, dynamic>> leftSeries,
// //     required String rightTitle,
// //     required List<CartesianSeries<dynamic, dynamic>> rightSeries,
// //   }) {
// //     return Row(
// //       children: [
// //         // -- LEFT CHART (Time axis visible) --
// //         Expanded(
// //           flex: 1,
// //           child: _buildTrackChart(
// //             title: leftTitle,
// //             series: leftSeries,
// //             // The vertical time axis is fully visible here
// //             dateTimeAxis: DateTimeAxis(
// //               isVisible: true,
// //               isInversed: true,       // earliest time at bottom
// //             ),
// //             // Numeric axis on the right side (opposed)
// //             numericAxis: NumericAxis(
// //               opposedPosition: true,
// //             ),
// //           ),
// //         ),
// //
// //         // -- RIGHT CHART (Hide time labels but keep boundary & numeric axis) --
// //         Expanded(
// //           flex: 1,
// //           child: _buildTrackChart(
// //             title: rightTitle,
// //             series: rightSeries,
// //             // We STILL define a DateTimeAxis, but hide the labels & ticks
// //             // so we keep the boundary & grid lines if desired
// //             dateTimeAxis: DateTimeAxis(
// //               isVisible: true,       // must be true to see boundary lines
// //               isInversed: true,
// //               labelStyle: const TextStyle(fontSize: 0),    // hide time text
// //               majorTickLines: const MajorTickLines(size: 0), // hide tick marks
// //               axisLine: const AxisLine(width: 1),          // keep axis line
// //               // If you want to hide vertical grid lines, do:
// //               // majorGridLines: const MajorGridLines(width: 0),
// //             ),
// //             // numeric axis on the left side (not opposed)
// //             numericAxis: NumericAxis(
// //               opposedPosition: true,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   /// Builds a single transposed chart with custom dateTimeAxis & numericAxis.
// //   Widget _buildTrackChart({
// //     required String title,
// //     required List<CartesianSeries<dynamic, dynamic>> series,
// //     required DateTimeAxis dateTimeAxis,
// //     required NumericAxis numericAxis,
// //   }) {
// //     return Container(
// //       padding: const EdgeInsets.all(8),
// //       child: SfCartesianChart(
// //         isTransposed: true, // rotate so X=vertical, Y=horizontal
// //         title: ChartTitle(
// //           text: title,
// //           textStyle: const TextStyle(fontWeight: FontWeight.bold),
// //         ),
// //         legend: Legend(isVisible: true),
// //         // Show a visible bounding box around the entire plot area
// //         plotAreaBorderWidth: 1,
// //         plotAreaBorderColor: Colors.grey,
// //
// //         // The vertical "time" axis (X) in transposed mode
// //         primaryXAxis: dateTimeAxis,
// //         // The horizontal "data" axis (Y) in transposed mode
// //         primaryYAxis: numericAxis,
// //
// //         trackballBehavior: TrackballBehavior(
// //           enable: true,
// //           tooltipSettings: const InteractiveTooltip(enable: true),
// //           activationMode: ActivationMode.singleTap,
// //         ),
// //         zoomPanBehavior: ZoomPanBehavior(
// //           enablePanning: true,
// //           enablePinching: true,
// //           enableDoubleTapZooming: true,
// //         ),
// //         series: series,
// //       ),
// //     );
// //   }
// //
// //   /// Generate the line series for a variable map
// //   List<CartesianSeries<dynamic, dynamic>> _generateSeriesList(
// //       List<DrillingData> data,
// //       Map<String, num Function(DrillingData)> variableMap,
// //       ) {
// //     return variableMap.entries
// //         .map<LineSeries<DrillingData, DateTime>>((entry) {
// //       return LineSeries<DrillingData, DateTime>(
// //         name: entry.key,
// //         dataSource: data,
// //         xValueMapper: (DrillingData d, _) => d.dateTime,
// //         yValueMapper: (DrillingData d, _) => entry.value(d),
// //         markerSettings: const MarkerSettings(isVisible: true),
// //       );
// //     })
// //         .cast<CartesianSeries<dynamic, dynamic>>()
// //         .toList();
// //   }
// //
// //   /// Group A: Mechanical
// //   Map<String, num Function(DrillingData)> get _mechanicalVariables => {
// //     'BitDepth (m)': (d) => d.bitDepth,
// //     'WOB (klb)': (d) => d.wob,
// //     'Torque (klb.ft)': (d) => d.torque,
// //     'RPM': (d) => d.rpm,
// //     'Hkld (klb)': (d) => d.hkld,
// //   };
// //
// //   /// Group B: Mud/Fluid
// //   Map<String, num Function(DrillingData)> get _mudVariables => {
// //     'MudFlowIn (gpm)': (d) => d.mudFlowIn,
// //     'MudFlowOutp': (d) => d.mudFlowOutp,
// //     'MudCondIn (mmho)': (d) => d.mudCondIn,
// //     'MudCondOut (mmho)': (d) => d.mudCondOut,
// //     'SpPress (Psi)': (d) => d.spPress,
// //     'TankVolTot (bbl)': (d) => d.tankVolTot,
// //   };
// //
// //   /// Group C: Gas
// //   Map<String, num Function(DrillingData)> get _gasVariables => {
// //     'H2S_1 (ppm)': (d) => d.h2s_1,
// //     'CO2_1 (%)': (d) => d.co2_1,
// //     'Gas (%)': (d) => d.gas,
// //   };
// //
// //   /// Group D: Temperature
// //   Map<String, num Function(DrillingData)> get _tempVariables => {
// //     'MudTempIn (C)': (d) => d.mudTempIn,
// //     'MudTempOut (C)': (d) => d.mudTempOut,
// //   };
// // }