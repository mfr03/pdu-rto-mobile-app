import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';




class HomeBannerCard extends StatelessWidget {

  final double bannerH;
  final double bitDepth;

  const HomeBannerCard({super.key, required this.bannerH, required this.bitDepth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: bannerH,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.95,
              child: Image.asset(
                'assets/images/image_home.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/images/bit_depth.svg', height: 64),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bit Depth',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bitDepth.toStringAsFixed(2)} m',
                      style: const TextStyle(
                        color: CColors.primaryColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}