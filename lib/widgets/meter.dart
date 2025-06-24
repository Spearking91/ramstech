import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class Meter extends StatefulWidget {
  const Meter({super.key, required this.value, required this.index});

  final double value;
  final double index;

  @override
  State<Meter> createState() => _MeterState();
}

class _MeterState extends State<Meter> {
  double pm25 = 0.0;
  num aqi = 0;
  void updateAQI(double value) {
    setState(() {
      pm25 = value;
      aqi = calculateAQI(pm25).round(); // Round the AQI to whole number
    });
  }

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      enableLoadingAnimation: true,
      animationDuration: 4500,
      axes: <RadialAxis>[
        RadialAxis(
            startAngle: 140,
            endAngle: 40,
            minimum: 0,
            maximum: 500,
            radiusFactor: 1,
            majorTickStyle: MajorTickStyle(
              length: 12,
              thickness: 2,
              color: Colors.amber,
            ),
            minorTickStyle: MinorTickStyle(
              length: 6,
              thickness: 1,
              color: Colors.cyan,
            ),
            axisLineStyle: AxisLineStyle(
              thickness: 15,
              gradient: SweepGradient(
                colors: [
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red
                ],
                stops: [0.25, 0.5, 0.75, 1],
              ),
            ),
            axisLabelStyle: GaugeTextStyle(
              color: Colors.white,
            ),
            pointers: <GaugePointer>[
              MarkerPointer(
                color: Colors.white,
                value: widget.value,
                enableAnimation: true,
                animationType: AnimationType.easeOutBack,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Column(
                  children: [
                    Text(
                      '${widget.value} ug/m3',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      getAirQualityDescription(aqi.toInt()),
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                positionFactor: 1,
                angle: 90,
              ),
              GaugeAnnotation(
                widget: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: RichText(
                        text: TextSpan(
                      text: 'Air Quality Index: $aqi AQI',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    )),
                  ),
                ),
                positionFactor: 0.7,
                angle: 90,
              )
            ]),
      ],
    );
  }

  Color getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.pink;
  }

  String getAirQualityDescription(int aqi) {
    if (aqi <= 50) {
      return 'Excellent';
    } else if (aqi <= 100) {
      return 'Moderate';
    } else if (aqi <= 150) {
      return 'Unhealthy for sensitive groups';
    } else if (aqi <= 200) {
      return 'Unhealthy';
    } else if (aqi <= 300) {
      return 'Very Unhealthy';
    } else {
      return 'Hazardous';
    }
  }
}

num calculateAQI(double pm25) {
  List<Map<String, double>> breakpoints = [
    {'low': 0, 'high': 12.0, 'lowAQI': 0, 'highAQI': 50},
    {'low': 12.1, 'high': 35.4, 'lowAQI': 51, 'highAQI': 100},
    {'low': 35.5, 'high': 55.4, 'lowAQI': 101, 'highAQI': 150},
    {'low': 55.5, 'high': 150.4, 'lowAQI': 151, 'highAQI': 200},
    {'low': 150.5, 'high': 250.4, 'lowAQI': 201, 'highAQI': 300},
    {'low': 250.5, 'high': 500.4, 'lowAQI': 301, 'highAQI': 500},
  ];

  for (var range in breakpoints) {
    if (pm25 >= range['low']! && pm25 <= range['high']!) {
      return ((pm25 - range['low']!) / (range['high']! - range['low']!)) *
              (range['highAQI']! - range['lowAQI']!) +
          range['lowAQI']!.round();
    }
  }

  return 0;
}
