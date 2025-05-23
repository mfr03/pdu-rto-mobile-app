import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart'; // Import Controller
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/features/notification/components/dialog/set_threshold_dialog.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';

class HomeSensorView extends StatefulWidget {
  final DrillingController controller;
  final Box<ParameterItem>? timeParameterBox;
  final Box<ParameterItem>? depthParameterBox;
  final bool isWellLive;
  final String currentWellApiToken;

  const HomeSensorView({
    Key? key,
    required this.controller,
    required this.timeParameterBox,
    required this.depthParameterBox,
    required this.isWellLive,
    required this.currentWellApiToken
  }) : super(key: key);

  @override
  _HomeSensorViewState createState() => _HomeSensorViewState();
}

class _HomeSensorViewState extends State<HomeSensorView> {
  int _selectedTabIndex = 0; // 0 for Time, 1 for Depth

  Widget _buildTabButton(String title, int index, BuildContext context) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded( // Make buttons take equal width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? CColors.primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : CColors.primaryColor.withOpacity(0.7),
          elevation: isSelected ? 2 : 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ).copyWith(
            side: WidgetStateProperty.all(
                isSelected ? BorderSide.none : BorderSide(color: CColors.primaryColor.withOpacity(0.3))
            )
        ),
        onPressed: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      height: 120, // Give placeholder some height
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusIndicator(dynamic currentLatestData) {
    if (currentLatestData == null || currentLatestData.dateTime == null) {
      return const SizedBox.shrink();
    }

    final DateTime dataTime = currentLatestData.dateTime;

    String formattedTime = DateFormat('HH:mm:ss').format(dataTime.toLocal()); // Format to local time

    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // Add some space above
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Justify right
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: widget.isWellLive ? Colors.greenAccent[700] : Colors.redAccent[700],
                shape: BoxShape.circle,
                boxShadow: [ // Optional: add a little glow
                  BoxShadow(
                    color: widget.isWellLive ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
                    blurRadius: 3.0,
                    spreadRadius: 1.0,
                  )
                ]
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.isWellLive ? "Live" : "Historical",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.isWellLive ? Colors.green[800] : Colors.red[800],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );

  }

  void _showSetThresholdDialog(BuildContext context, ParameterItem paramItem, String currentWellApiToken) {
    showDialog(context: context, builder: (_) => SetThresholdDialog(
      parameterItem: paramItem,
      wellApiToken: currentWellApiToken
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white, // Ensure card background is white
        child: Padding( // Add padding inside Material for better visual separation
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton("Time Data", 0, context),
                  const SizedBox(width: 10), // Spacing between buttons
                  _buildTabButton("Depth Data", 1, context),
                ],
              ),
              const SizedBox(height: 16), // Spacing after tabs

              // Obx to listen to controller updates for dynamic data
              Obx(() {
                final dynamic currentLatestData;
                final Box<ParameterItem>? currentParamBox;
                String noDataMessage = 'No sensor data available.';

                if (_selectedTabIndex == 0) { // Time Data
                  currentLatestData = widget.controller.latestLiveTimeDataPoint.value;

                  currentParamBox = widget.timeParameterBox;
                  noDataMessage = 'No time-based sensor data available or parameters not configured.';
                } else { // Depth Data
                  currentLatestData = widget.controller.displayedDataDepth.isNotEmpty
                      ? widget.controller.displayedDataDepth.last
                      : null;
                  currentParamBox = widget.depthParameterBox;
                  noDataMessage = 'No depth-based sensor data available or parameters not configured.';
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLiveStatusIndicator(currentLatestData),
                    const SizedBox(height: 8),
                    if (currentLatestData == null || currentParamBox == null || currentParamBox.isEmpty)
                      _buildPlaceholder(noDataMessage)
                    else ... [
                      Builder(
                        builder: (context) {
                          final List<ParameterItem> visibleParameters = currentParamBox!.values
                              .where((p) => p.isVisible)
                              .toList();

                          if (visibleParameters.isEmpty) {
                            return _buildPlaceholder(_selectedTabIndex == 0
                                ? 'No visible time parameters.'
                                : 'No visible depth parameters.');
                          }

                          return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visibleParameters.length,
                              itemBuilder: (_, i) {
                                final paramItem = visibleParameters[i];
                                final num value = currentLatestData.value(paramItem.jsonKey);
                                final String unit = paramItem.unit ?? '';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.settings, color: CColors.primaryColor),
                                  title: Text(
                                    paramItem.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                    trailing: Text(
                                      '${value.toStringAsFixed(2)}$unit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: paramItem.color,
                                      ),
                                    ),
                                  onTap: () {
                                    if(widget.currentWellApiToken != null && paramItem != null) {
                                      _showSetThresholdDialog(context, paramItem, widget.currentWellApiToken);
                                    }
                                  },
                                );
                              },
                              );
                        }
                      )]
                    ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}