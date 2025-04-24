import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/screen/chart_drilling_screen.dart';

class WellsActiveScreen extends StatefulWidget {
  const WellsActiveScreen({Key? key}) : super(key: key);

  @override
  State<WellsActiveScreen> createState() => _WellsActiveScreenState();
}

class _WellsActiveScreenState extends State<WellsActiveScreen> {
  late Future<List<WellActive>> _futureWells;

  @override
  void initState() {
    super.initState();
    // Kick off the network call
    _futureWells = PduApi.fetchActiveWells();
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

          // If the snapshot has data, build the list
          if (snapshot.hasData) {
            final wells = snapshot.data!;
            return ListView.builder(
              itemCount: wells.length,
              itemBuilder: (context, index) {
                final well = wells[index];
                return ListTile(
                  title: Text(well.wellName),
                  subtitle: Text("Company: ${well.companyName}"),
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DrillingChartScreen(
                        wellActive: well,
                      )
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
