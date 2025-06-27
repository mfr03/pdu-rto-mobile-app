import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/common/components/circle.dart';
import 'package:pdu_mobile_rto_app/common/components/colored_text.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/constants/sizes.dart';
import 'package:pdu_mobile_rto_app/utils/theme/text_theme.dart';
import 'package:pdu_mobile_rto_app/utils/theme/theme.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:flutter/foundation.dart';

import '../dialog/edit_parameter_dialog.dart';

class ParameterDashboard extends StatefulWidget {
  final int parameterAmount;
  final int activeIndex;
  final List<ParameterItem> parameters;
  final ValueChanged<int>? onCardTap;
  final Box<ParameterItem> parameterBox;

  const ParameterDashboard({
    Key? key,
    required this.parameterAmount,
    required this.activeIndex,
    required this.parameters,
    required this.parameterBox,
    this.onCardTap,
  }) : super(key: key);

  @override
  _ParameterDashboardState createState() => _ParameterDashboardState();
}

class _ParameterDashboardState extends State<ParameterDashboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ParameterDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // whenever the incoming parameter list changes, scroll back to top
    if (!listEquals(oldWidget.parameters, widget.parameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _showEditDialog(ParameterItem parameter) {
    showDialog(
      context: context,
      builder: (context) => EditParameterDialog(
        parameter: parameter,
        parameterBox: widget.parameterBox,
        onSaved: () {
          // Force parent rebuild after save
          if (mounted) {
            setState(() {
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                    onTap: () {
                      if (widget.onCardTap != null) {
                        widget.onCardTap!(widget.parameterAmount + 1);
                      }
                    },
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

            Expanded(child:
              Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  decoration: isDarkMode ?
                  CAppTheme.elevatedContainer : CAppTheme.elevatedContainer,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 200,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:  widget.parameters.length,
                        itemBuilder: (context, index) {
                          final param = widget.parameters[index];
                          return Column(
                            key: ValueKey(param.name + param.color.toString()),
                            children: [
                              Padding(
                                padding: CAppTheme.parameterDashboardPadding,
                                child: Row(
                                  children: [
                                    Circle(param.color, CSizes.parameterDashboardCircleSize),
                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ColoredText(
                                            text: param.name,
                                            textColor: param.color,
                                            textSize: CSizes.parameterDashboardNumberTextSize + 1,
                                            isBold: true,
                                          ),
                                          ColoredText(
                                            text: param.value,
                                            textColor: param.color,
                                            textSize: CSizes.parameterDashboardNumberTextSize + 1,
                                            isBold: true,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3) Settings button stays at the end
                                    IconButton(
                                      icon: const Icon(Icons.settings, color: CColors.primaryColor),
                                      onPressed: () => _showEditDialog(param),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}