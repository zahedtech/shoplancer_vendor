import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/helper/date_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTimePickerWidget extends StatefulWidget {
  final String title;
  final String? time;
  final Function(String?) onTimeChanged;
  const CustomTimePickerWidget({super.key, required this.title, required this.time, required this.onTimeChanged});

  @override
  State<CustomTimePickerWidget> createState() => _CustomTimePickerWidgetState();
}

class _CustomTimePickerWidgetState extends State<CustomTimePickerWidget> {
  String? _myTime;
  int? _selectedHour;
  int? _selectedMinute;
  String? _selectedPeriod;

  final List<int> _hours = List.generate(12, (index) => index + 1);
  final List<int> _minutes = List.generate(60, (index) => index);
  final List<String> _periods = ['am', 'pm'];

  @override
  void initState() {
    super.initState();
    _parseTime();
  }

  @override
  void didUpdateWidget(covariant CustomTimePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.time != oldWidget.time) {
      _parseTime();
    }
  }

  void _parseTime() {
    _myTime = widget.time;
    int hour24 = 9;
    int min = 0;
    if (_myTime != null && _myTime!.contains(':')) {
      List<String> parts = _myTime!.split(':');
      hour24 = int.tryParse(parts[0]) ?? 9;
      min = int.tryParse(parts[1]) ?? 0;
    }
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    _selectedHour = hour12;
    _selectedMinute = min;
    _selectedPeriod = hour24 >= 12 ? 'pm' : 'am';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      InkWell(
        onTap: () async {
          showDialog(
            context: context,
            builder: (context) {
              int tempHour = _selectedHour ?? 9;
              int tempMinute = _selectedMinute ?? 0;
              String tempPeriod = _selectedPeriod ?? 'am';
              return AlertDialog(
                title: Text(widget.title, style: robotoBold),
                content: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Hour Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.5), width: 0.5),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: tempHour,
                              items: _hours.map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString().padLeft(2, '0'), style: robotoMedium),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setStateDialog(() {
                                    tempHour = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const Text(':', style: robotoBold),
                        // Minute Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.5), width: 0.5),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: tempMinute,
                              items: _minutes.map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString().padLeft(2, '0'), style: robotoMedium),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setStateDialog(() {
                                    tempMinute = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        // Period Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.5), width: 0.5),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: tempPeriod,
                              items: _periods.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.tr, style: robotoMedium),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setStateDialog(() {
                                    tempPeriod = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedHour = tempHour;
                        _selectedMinute = tempMinute;
                        _selectedPeriod = tempPeriod;

                        int hour24 = tempHour;
                        if (tempPeriod == 'pm' && tempHour < 12) hour24 += 12;
                        if (tempPeriod == 'am' && tempHour == 12) hour24 = 0;

                        _myTime = '${hour24.toString().padLeft(2, '0')}:${tempMinute.toString().padLeft(2, '0')}';
                      });
                      widget.onTimeChanged(_myTime);
                      Navigator.pop(context);
                    },
                    child: Text('ok'.tr, style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
                  ),
                ],
              );
            },
          );
        },
        child: Stack(clipBehavior: Clip.none, children: [

          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: Theme.of(context).disabledColor, width: 0.5),
            ),
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeSmall),
            child: Row(children: [

              Expanded(child: Text(
                _myTime != null ? DateConverterHelper.convertStringTimeToTime(_myTime!) : ' - -  : - - ${'min'.tr}', style: robotoRegular.copyWith(color: _myTime != null ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeDefault),
              )),

              Icon(Icons.access_time_filled, size: 20, color: Theme.of(context).primaryColor),

            ]),
          ),

          Positioned(
            left: 10, top: -15,
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              padding: const EdgeInsets.all(5),
              child: Text(widget.title, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
            ),
          ),

        ]),
      ),

    ]);
  }
}