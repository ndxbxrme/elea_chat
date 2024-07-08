import 'package:flutter/material.dart';

import '../constants.dart';

class EleaCountyPicker extends StatefulWidget {
  final String? labelText;
  final String? labelSubtext;
  final String? initialValue;
  final bool? obscureText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldSetter<String>? onChanged;
  const EleaCountyPicker({
    super.key,
    this.labelText,
    this.labelSubtext,
    this.initialValue,
    this.onSaved,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EleaCountyPickerState createState() => _EleaCountyPickerState();
}

class _EleaCountyPickerState extends State<EleaCountyPicker> {
  bool isInputValid = false;
  String? _selectedCounty;
  final List<String> _ukCounties = [
    'Bedfordshire',
    'Berkshire',
    'Bristol',
    'Buckinghamshire',
    'Cambridgeshire',
    'Cheshire',
    'City of London',
    'Cornwall',
    'County Durham',
    'Cumbria',
    'Derbyshire',
    'Devon',
    'Dorset',
    'East Riding of Yorkshire',
    'East Sussex',
    'Essex',
    'Gloucestershire',
    'Greater London',
    'Greater Manchester',
    'Hampshire',
    'Herefordshire',
    'Hertfordshire',
    'Isle of Wight',
    'Kent',
    'Lancashire',
    'Leicestershire',
    'Lincolnshire',
    'Merseyside',
    'Norfolk',
    'North Yorkshire',
    'Northamptonshire',
    'Northumberland',
    'Nottinghamshire',
    'Oxfordshire',
    'Rutland',
    'Shropshire',
    'Somerset',
    'South Yorkshire',
    'Staffordshire',
    'Suffolk',
    'Surrey',
    'Tyne and Wear',
    'Warwickshire',
    'West Midlands',
    'West Sussex',
    'West Yorkshire',
    'Wiltshire',
    'Worcestershire',
  ];

  @override
  void initState() {
    super.initState();
    // Ensure initial value is part of the list or set it to null
    if (_ukCounties.contains(widget.initialValue)) {
      _selectedCounty = widget.initialValue;
    } else {
      _selectedCounty = null; // Or you can set it to the first item in the list
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isInputValid =
        widget.initialValue != null && widget.initialValue!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(widget.labelText!,
                style: Theme.of(context).textTheme.labelLarge),
          ),
        if (widget.labelSubtext != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(widget.labelSubtext!,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.left),
          ),
        if (widget.labelText != null || widget.labelSubtext != null)
          const SizedBox(height: 6.0),
        Container(
          height: 50,
          decoration: Constants.circularBorderBoxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCounty,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCounty = newValue;
                      });
                      widget.onChanged!(_selectedCounty);
                    },
                    items: _ukCounties
                        .map<DropdownMenuItem<String>>((String county) {
                      return DropdownMenuItem<String>(
                        value: county,
                        child: Text(county),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Visibility(
                visible: isInputValid,
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
