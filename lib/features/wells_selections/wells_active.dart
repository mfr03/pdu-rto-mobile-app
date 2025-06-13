// codes/lib/features/wells_selections/wells_active.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/screen/chart_drilling_screen.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
import 'package:pdu_mobile_rto_app/utils/well_utils.dart'; // Ensure this import is present

class WellsActiveScreen extends StatefulWidget {
  const WellsActiveScreen({super.key});

  @override
  State<WellsActiveScreen> createState() => _WellsActiveScreenState();
}

class _WellsActiveScreenState extends State<WellsActiveScreen> {
  late Future<List<WellActive>> _futureWells;
  final PduApi _api = GetIt.I<PduApi>();

  @override
  void initState() {
    super.initState();
    _futureWells = _api.fetchActiveWells();
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: CColors.primaryColor),
          SizedBox(height: 20),
          Text('Loading Wells...', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 15),
            Text(
              "Error Loading Wells",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor),
              onPressed: () {
                setState(() {
                  _futureWells = _api.fetchActiveWells();
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWellCard(BuildContext context, WellActive well) {
    // Determine if the well is completed using the updated utility function
    final bool isCompleted = isWellCompleted(wellActive: well);
    final NavigatorState navigator = Navigator.of(context);

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
        onTap: () async {
          final box = await HiveService.openSavedWells();
          WellActive wellToUse = box.get(well.isApiToken) ?? well;
          if (box.get(well.isApiToken) == null) {
            await box.put(well.isApiToken, well);
          }
          navigator.push(
            MaterialPageRoute(
              builder: (_) => DrillingChartScreen(wellActive: wellToUse),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isCompleted ? Colors.grey[400] : CColors.primaryColor.withOpacity(0.15),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.water_drop_outlined,
                  color: isCompleted ? Colors.white : CColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      well.wellName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CColors.tertiaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Company: ${well.companyName}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Updated to display "Status: " and use well.wellStatus
                    Text(
                      "Status: ${well.wellStatus}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: isCompleted ? Colors.orangeAccent.withOpacity(0.8) : Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 3)
                    ),
                    child: Text(
                      isCompleted ? "Completed" : "Active",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FutureBuilder<List<WellActive>>(
          future: _futureWells,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            }
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final wells = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: wells.length,
                      itemBuilder: (context, index) {
                        return _buildWellCard(context, wells[index]);
                      },
                    ),
                  ),
                ],
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.layers_clear_outlined, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "No Active Wells Found",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "There are currently no active wells to display. Please check back later or try refreshing.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Refresh', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor),
                      onPressed: () {
                        setState(() {
                          _futureWells = _api.fetchActiveWells();
                        });
                      },
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}