import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/remark_item.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart'; // Ensure this import is present

class RemarksScreen extends StatefulWidget {
  final WellActive wellActive;

  const
  RemarksScreen({Key? key, required this.wellActive}) : super(key: key);

  @override
  State<RemarksScreen> createState() => _RemarksScreenState();
}

class _RemarksScreenState extends State<RemarksScreen> {
  late Future<List<RemarkItem>> _futureRemarks;
  final PduApi _pduApi = Get.find<PduApi>();

  @override
  void initState() {
    super.initState();
    _fetchRemarks();
  }

  void _fetchRemarks() {
    // Define the 15-minute time window for the remarks API.
    // We'll fetch remarks from 15 minutes ago up to the current time.
    final DateTime now = DateTime.now();
    final DateTime fifteenMinutesAgo = now.subtract(const Duration(minutes: 15));

    final String timeEndFormatted = CFormatter.formatDateTime(now);
    final String timeStartFormatted = CFormatter.formatDateTime(fifteenMinutesAgo);

    setState(() {
      _futureRemarks = _pduApi.fetchRemarksData(
        token: widget.wellActive.isApiToken,
        timeStart: timeStartFormatted,
        timeEnd: timeEndFormatted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Remarks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: CColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<RemarkItem>>(
        future: _futureRemarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CColors.primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading remarks: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Retry', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor),
                      onPressed: _fetchRemarks,
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notes, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No remarks found for ${widget.wellActive.wellName} in the last 15 minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Refresh', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor),
                      onPressed: _fetchRemarks,
                    ),
                  ],
                ),
              ),
            );
          } else {
            final remarks = snapshot.data!;
            remarks.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Newest first

            return ListView.builder(
              padding: const EdgeInsets.all(CSizes.standardBorderRadiusSize),
              itemCount: remarks.length,
              itemBuilder: (context, index) {
                final remark = remarks[index];
                // Example condition for alert styling: if the remark text contains "STUCK" (case-insensitive)
                final isAlert = remark.commText.toUpperCase().contains('STUCK');

                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CSizes.standardBorderRadiusSize / 2),
                  ),
                  color: isAlert ? CColors.primaryColor : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAlert ? Icons.warning_amber_outlined : Icons.info_outline,
                              color: isAlert ? Colors.white : CColors.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                remark.commText,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isAlert ? Colors.white : CColors.tertiaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${remark.date} ${remark.time}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isAlert ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}