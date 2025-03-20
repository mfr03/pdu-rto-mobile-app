import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/common/components/circle.dart';
import 'package:pdu_mobile_rto_app/common/components/colored_text.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
import 'package:pdu_mobile_rto_app/utils/theme/text_theme.dart';
import 'package:pdu_mobile_rto_app/utils/theme/theme.dart';
import '../../model/ParameterItem.dart';

class ParameterDashboard extends StatefulWidget {
  final int parameterAmount;
  final int activeIndex;
  final List<ParameterItem> parameters;
  final ValueChanged<int>? onCardTap;

  const ParameterDashboard({
    Key? key,
    required this.parameterAmount,
    required this.activeIndex,
    required this.parameters,
    this.onCardTap,
  }) : super(key: key);

  @override
  _ParameterDashboardState createState() => _ParameterDashboardState();
}

class _ParameterDashboardState extends State<ParameterDashboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showPlaceholderDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Placeholder Dialog'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                for (int i = 1; i <= widget.parameterAmount; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onCardTap != null) {
                          widget.onCardTap!(i);
                        }
                      },
                      child: Container(
                        height: CSizes.parameterDashboardNumberCardSize,
                        margin: EdgeInsets.only(right: 2),
                        decoration: i == widget.activeIndex
                            ? CAppTheme.standardBoxDecorationPrimaryColor
                            : CAppTheme.standardBoxDecorationSecondaryColor,
                        child: Center(
                          child: Text(
                            i.toString(),
                            maxLines: 1,
                            style: CTextTheme.parameterDashboardNumber,
                          ),
                        ),
                      ),
                    ),
                  ),

                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPlaceholderDialog('Add Tracks'),
                    child: Container(
                      height: CSizes.parameterDashboardNumberCardSize,
                      decoration: CAppTheme.standardBoxDecorationSecondaryColor,
                      child: Center(
                        child: Text(
                          '+',
                          maxLines: 1,
                          style: CTextTheme.parameterDashboardNumber,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                decoration: CAppTheme.elevatedContainer,
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 200,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          for (int i = 0; i < widget.parameters.length; i++) ...[
                            Padding(
                              padding: CAppTheme.parameterDashboardPadding,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Circle(
                                        widget.parameters[i].color,
                                        CSizes.parameterDashboardCircleSize,
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ColoredText(
                                            text: widget.parameters[i].name,
                                            textColor: widget.parameters[i].color,
                                            textSize: CSizes.parameterDashboardNumberTextSize + 1,
                                            isBold: true,
                                          ),
                                          ColoredText(
                                            text: widget.parameters[i].value,
                                            textColor: widget.parameters[i].color,
                                            textSize: CSizes.parameterDashboardNumberTextSize + 1,
                                            isBold: true,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Settings icon, clickable
                                  GestureDetector(
                                    onTap: () => _showPlaceholderDialog('Parameter Settings'),
                                    child: const Icon(
                                      Icons.settings,
                                      color: CColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < widget.parameters.length - 1)
                              const Divider(
                                color: Color(0xFFF2F2F2),
                                thickness: 1,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
