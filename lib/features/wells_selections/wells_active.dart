import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/screen/chart_drilling_screen.dart';

class WellsActiveScreen extends StatefulWidget {
  const WellsActiveScreen({super.key});

  @override
  State<WellsActiveScreen> createState() => _WellsActiveScreenState();
}

class _WellsActiveScreenState extends State<WellsActiveScreen> {
  late Future<List<WellActive>> _futureWells;

  @override
  void initState() {
    super.initState();
    // Kick off the network call
    final PduApi api = GetIt.I<PduApi>();
    _futureWells = api.fetchActiveWells();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<WellActive>>(
        future: _futureWells,
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Show a loading spinner until data arrives
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("here");
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            final wells = snapshot.data!;
            return ListView.builder(
              itemCount: wells.length,
              itemBuilder: (context, index) {
                final well = wells[index];
                final NavigatorState navigator = Navigator.of(context);

                return ListTile(
                  title: Text(well.wellName),
                  subtitle: Text("Company: ${well.companyName}"),
                  onTap: ()  async {

                    final box = await HiveService.openSavedWells();
                    final saved = box.get(well.isApiToken);

                    final toUse = saved ?? well;

                    if(saved == null) {
                      await box.put(well.isApiToken, toUse);
                    }

                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => DrillingChartScreen(wellActive: toUse),
                      )
                    );

                  },
                );
              },
            );
          }

          // If no data, show an empty container or a message
          return const Center(child: Text("No Wells Found"));
        },
      ),
    );
  }
}
