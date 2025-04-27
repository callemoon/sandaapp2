import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

SharedPreferences ?prefs;
XFile? file = XFile('assets/katt.jpg');

FileImage myImage = FileImage(File('assets/katt.jpg'));

TextStyle mainFont = GoogleFonts.exo2(fontSize: 54, fontWeight: FontWeight.w300);
TextStyle subFont = GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w500);
TextStyle dateFont = GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w500);

List<String> requestStrings =
[
  'https://api.thingspeak.com/channels/631325/fields/1.json?api_key=IA9TGDTR2351DC1I',  // sovrum sanda
  'https://api.thingspeak.com/channels/2011583/fields/1.json?api_key=EL96SBAO527BKNP3', // övervåning sanda
  'https://api.thingspeak.com/channels/2014046/fields/1.json?api_key=68ODS47UMTXTWR9K', // kök sanda
  'https://api.thingspeak.com/channels/2013865/fields/1.json?api_key=PLWLFP0HG4TE9BNZ', // ute sanda
  'https://api.thingspeak.com/channels/2019519/fields/1.json?api_key=3HZ51EFUGWRX9DBQ', // ute uppsala
  'https://api.thingspeak.com/channels/2832057/fields/1.json?api_key=SYH9X8X6V0F23933',  // sovrum uppsala
  'https://api.thingspeak.com/channels/2937216/fields/1.json?api_key=AZM8HHSG7WQ6DT49'  // fukt
];

List<Color> colorList =
[
  Colors.transparent,
  Colors.grey[300]!,
  Colors.blue[100]!,
  Colors.red[200]!,
];

List<String> captions =
[
  'sovrum sanda',
  'övervåning sanda',
  'kök sanda',
  'ute sanda',
  'ute uppsala',
  'sovrum uppsala',
  'fuktighet'
];

List<Color> tileColors =
[
  Colors.red,
  Colors.green,
  Colors.blueGrey,
  Colors.grey,
  Colors.white,
  Colors.yellow,
  Colors.lightBlue
];

double tileWidth = 175;
double tileHeight = 175;
double rowSpacing = 10;
double columnSpacing = 10;
double radius = 8.0;

int? tileColor = 0;
bool? showTime = false;
Color tileColorColor = Colors.grey;
bool? useRoundCorners = false;
bool? gradient = false;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperaturer',
      home: const MyHomePage(title: 'Mitt hem'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double hum1 = 0.0;

  static const int temperatures = 7;

  List<double> tempArray = List.filled(temperatures, 0.0);
  List<String> timeArray = List.filled(temperatures, '');

  Timer? periodicTimer;
  Timer? secondTimer;

  double tick = 0.0;

  void GetData() async
  {
    requestStrings.asMap().forEach((index, requestString) async {
      http.Response result = await http.get(Uri.parse(requestString + '&results=5'));
      dynamic map = jsonDecode(result.body);
      setState(() {
        for(int i = 4; i >= 0 ; i--) {
          if (map['feeds'][i]['field1'] != null) {
            tempArray[index] = double.parse(map['feeds'][i]['field1']);
            String time_tmp = map['feeds'][i]['created_at'];
            List<String> list = time_tmp.split("T");
            timeArray[index] = list[0] + " " + list[1].substring(0, 8);
            break;
          }
        }
      });
    });

    /*
    // Hum
    result = await http.get(Uri.parse('https://api.thingspeak.com/channels/2014046/fields/2.json?api_key=68ODS47UMTXTWR9K&results=1'));
    map = jsonDecode(result.body);
    setState(() {
      if(map['feeds'][0]['field2'] != null) {
        hum1 = double.parse(map['feeds'][0]['field2']);
      }
    });
     */
  }

  @override
  void initState () {
    super.initState();

    GetPrefs();
    GetData();
  }

  void GetPrefs () async {
    prefs = await SharedPreferences.getInstance();

    String? filename = prefs!.getString("filename");
    int? updateInterval = prefs!.getInt("update-interval");

    if(updateInterval == null || updateInterval! < 30)
    {
      updateInterval = 30;
    }

    if(filename != null)
    {
      myImage = FileImage(File(filename));
    }

    periodicTimer = Timer.periodic(
        Duration(seconds: updateInterval!),
            (timer)
        {GetData();
        tick=0;}
    );

    secondTimer = Timer.periodic(
        Duration(seconds: 1),
            (timer)
        {setState(() {
          tick+=1/updateInterval!;
        });
          }
    );

    tileColor = prefs!.getInt("color");
    if(tileColor == null)
      tileColorColor = Colors.grey;
    else
      tileColorColor = colorList[tileColor!];

    showTime = prefs!.getBool("time");
    if(showTime == null)
    {
        showTime = false;
    }

    useRoundCorners = prefs!.getBool("round-corners");
    if(useRoundCorners == null)
      useRoundCorners = false;

    gradient = prefs!.getBool("gradient");
    if(gradient == null)
      gradient = false;
  }

  Container createTile(String text, int index, Color tileColor, IconData tileIcon)
  {
    String dateLocal = "";

    if(timeArray[index] != '') {
      var dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timeArray[index], true);
      dateLocal = DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime.toLocal());
    }

    return Container(
        width: tileWidth,
        height: tileHeight,
        //color: tileColor,
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: useRoundCorners!?BorderRadius.circular(radius):BorderRadius.zero,
        ),
        child: Column( mainAxisAlignment: MainAxisAlignment.center,
            children: [ Text(style: mainFont, tempArray[index].toStringAsFixed(1) + '\u02da'),
              Text(style: subFont, text),
              IconButton(
                  onPressed: () {
                  },
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    tileIcon,
                    size: 44.0,
                    color: Colors.black,
                  )
              ),
              showTime!?Text(style: dateFont, dateLocal.toString()):Text(""),
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Align(
            alignment: Alignment.center,
            child: Container(        decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  gradient!?Colors.grey:Colors.white,
                  Colors.white,
                ],
              ),
            ), child: SafeArea(child: ListView(
              padding: EdgeInsets.all(15),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Diagrams()),
                          );
                        }, icon: Icon(Icons.auto_graph)),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            myImage = myImage;
                          });
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AboutDialog(
                                  applicationIcon: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Image(
                                          image:
                                          AssetImage('assets/katt.jpg'))),
                                  applicationName: 'Sandaapp',
                                  applicationVersion: '1.1.0',
                                  applicationLegalese: '©2023-2025 Calle',
                                );
                              });
                        },
                        icon: Icon(Icons.info_outline)),
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Settings()),
                          );
                        }, icon: Icon(Icons.settings_outlined)),

                  ],
                ),
                Container(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      createTile(captions[0], 0, tileColor != 0 ? tileColorColor: tileColors[0], Icons.bed),
                      Container(width: columnSpacing),
                      createTile(captions[1], 1, tileColor != 0 ? tileColorColor: tileColors[1], Icons.arrow_upward),
                    ]),
                Container(height: rowSpacing),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /*
                      Container(
                        width: tileWidth,
                        height: tileHeight,
                        color: Colors.red,
                        child: Column( mainAxisAlignment: MainAxisAlignment.center,
                            children: [ Text(style: GoogleFonts.titilliumWeb(fontSize: 48,
                                fontWeight: FontWeight.w300), tempArray[2].toStringAsFixed(1) + '\u02da'),
                              Text(style: GoogleFonts.titilliumWeb(fontSize: 14,
                                  fontWeight: FontWeight.w300), hum1.toStringAsFixed(1) + '%RH'),
                              Text(style: TextStyle(fontSize: 14), captions[2]),
                              IconButton(
                                  onPressed: () {},
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.kitchen,
                                    size: 44.0,
                                    color: Colors.black,
                                  )
                              ),
                              Container(height: 20),
                            ])),
                       */
                      createTile(captions[2], 2, tileColor != 0 ? tileColorColor: tileColors[2], Icons.kitchen),
                      Container(width: columnSpacing),
                      createTile(captions[3], 3, tileColor != 0 ? tileColorColor: tileColors[3], Icons.park_rounded)
                ]),
                Container(height: rowSpacing),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      createTile(captions[5], 5, tileColor != 0 ? tileColorColor: tileColors[5], Icons.bed),
                      Container(width: columnSpacing),
                      createTile(captions[4], 4, tileColor != 0 ? tileColorColor: tileColors[4], Icons.holiday_village)
                    ]),
                Container(height: rowSpacing),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      createTile(captions[6], 6, tileColor != 0 ? tileColorColor: tileColors[6], Icons.holiday_village),
                      Container(width: columnSpacing),
                      ClipRRect(
                        borderRadius: useRoundCorners!?BorderRadius.circular(radius):BorderRadius.zero,
                        child: Image(width: tileWidth, height: tileHeight, image: myImage),
                      )

                    ]),
              ],
            )))
        ));
  }
}

class Diagrams extends StatefulWidget {
  const Diagrams({super.key});

  @override
  State<Diagrams> createState() => _MyDiagrams();
}

class _MyDiagrams extends State<Diagrams> {

  static const int diagrams = 6;
  int timespan = 24;

  List<List<LineChartBarData>> listOfLists = List.generate(diagrams, (_) => [LineChartBarData(spots: [])]);

  String filterString = "";

  void GetData() async
  {
    if(timespan == 24) {
      filterString = '&minutes=1440&average=60&round=1&offset=1';
    }

    if(timespan == 180) {
      filterString = '&days=180&average=daily&round=1';
    }

    if(timespan == 14) {
      filterString = '&days=14&average=daily&round=1';
    }

    if(timespan == 60) {
      filterString = '&minutes=60&round=1&offset=1';
    }

    List<List<FlSpot>> spotList = List.generate(diagrams, (_) => []);

    for(int i = 0; i < diagrams; i++)
    {
        http.Response result = await http.get(Uri.parse(requestStrings[i] + filterString));
        dynamic map = jsonDecode(result.body);

        for(int j = 0; j < map['feeds'].length; j++)
        {
          if(map['feeds'][j]['field1'] != null)
          {
            double a = double.parse(map['feeds'][j]['field1']);
            spotList[i].add(FlSpot(j.toDouble(), a));
          }
        }
    }

    setState(() {
      for (int i = 0; i < diagrams; i++) {
        listOfLists[i] = [LineChartBarData(dotData: const FlDotData(show: false), spots: spotList[i])];
      }
    });
  }

  @override
  void initState () {
    super.initState();
    GetData();
  }

  Column createDiagram(List<LineChartBarData> data, String text, double min, double max)
  {
    return Column(
      children: [
        Container(height: 10),
        Divider(height: 1, indent: 20, endIndent: 20,),
        Container(
          padding: const EdgeInsets.all(10),
          height: 250,
          child: LineChart(
            LineChartData(minY: min, maxY: max, backgroundColor: Colors.white10,
            borderData: FlBorderData(show: false), lineBarsData: data),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(text)]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Diagram'),
        ),
        body: ListView(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                backgroundColor: timespan == 180 ? MaterialStateProperty.all<Color>(Colors.grey):MaterialStateProperty.all<Color>(Colors.white),
                ),
                onPressed: (){setState(() {
              timespan = 180; GetData();
            });} , child: Text("sista halvår")),
            TextButton(style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
              backgroundColor: timespan == 14 ? MaterialStateProperty.all<Color>(Colors.grey):MaterialStateProperty.all<Color>(Colors.white),
            ),
                onPressed: (){setState(() {
                  timespan = 14; GetData();
                });} , child: Text("sista 14 dagar")),
            TextButton(style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
              backgroundColor: timespan == 24 ? MaterialStateProperty.all<Color>(Colors.grey):MaterialStateProperty.all<Color>(Colors.white),
            ),onPressed: (){setState(() {
              timespan = 24; GetData();
            });}, child: Text("sista 24 tim")),
            TextButton(style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
              backgroundColor: timespan == 60 ? MaterialStateProperty.all<Color>(Colors.grey):MaterialStateProperty.all<Color>(Colors.white),
            ),onPressed: (){setState(() {
              timespan = 60; GetData();
            });}, child: Text("sista 60 min")),
            ]),

          createDiagram(listOfLists[0]!, captions[0], 5 , 25),
          createDiagram(listOfLists[1]!, captions[1], 5 , 25),
          createDiagram(listOfLists[2]!, captions[2], 5 , 25),
          createDiagram(listOfLists[3]!, captions[3], -25 , 25),
          createDiagram(listOfLists[4]!, captions[4], -25 , 25),
          createDiagram(listOfLists[5]!, captions[5], 5 , 25),
        ]));}
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _MySettings();
}

class _MySettings extends State<Settings> {

  final ImagePicker _picker = ImagePicker();

  int? timer = prefs!.getInt("update-interval");
  int? language = prefs!.getInt("language");
  int? unit = prefs!.getInt("unit");

  Dialog buildRefreshDialog(BuildContext context)
  {
    return Dialog(
        child:
        SizedBox(width: 200, height: 300, child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            //Container(height:10),
            Text("Uppdateringsintervall", style:TextStyle(fontSize: 20)),
            //Container(height: 10, width: 100),
            StatefulBuilder(builder: (context, setState) {
              return Column(children: [
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("30s"),
                  value: 30,
                  groupValue: timer,
                  onChanged: (int? value) {
                    prefs!.setInt("update-interval", value!);
                    setState(() {
                      timer = value;
                    });
                  },
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("1 min"),
                  value: 60,
                  groupValue: timer,
                  onChanged: (int? value){
                    prefs!.setInt("update-interval", value!);
                    setState(() {
                      timer = value;
                    });
                  },
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("2 min"),
                  value: 120,
                  groupValue: timer,
                  onChanged: (int? value){
                    prefs!.setInt("update-interval", value!);
                    setState(() {
                      timer = value;
                    });
                  },
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("5 min"),
                  value: 300,
                  groupValue: timer,
                  onChanged: (int? value){
                    prefs!.setInt("update-interval", value!);
                    setState(() {
                      timer = value;
                    });
                  },
                )]);
            }),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true), // passing true
              child: Text('Stäng'),
            ),
          ],
        )
        ));
  }

  Dialog buildColorDialog(BuildContext context)
  {
    return Dialog(
        child:
        SizedBox(width: 200, height: 400, child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            //Container(height:10),
            Text("Brickfärg", style:TextStyle(fontSize: 20)),
            //Container(height: 10, width: 100),
            StatefulBuilder(builder: (context, setState) {
              return Column(children: [
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("Färgexplosion"),
                  value: 0,
                  groupValue: tileColor,
                  onChanged: (int? value){
                    prefs!.setInt("color", value!);
                    setState(() {
                      tileColor = value;
                    });
                  },
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("Grå"),
                  value: 1,
                  groupValue: tileColor,
                  onChanged: (int? value) {
                    prefs!.setInt("color", value!);
                    setState(() {
                      tileColor = value;
                      tileColorColor = colorList[tileColor!];
                    });
                  },
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("Blå"),
                  value: 2,
                  groupValue: tileColor,
                  onChanged: (int? value) {
                    prefs!.setInt("color", value!);
                    setState(() {
                      tileColor = value;
                      tileColorColor = colorList[tileColor!];
                    });
                  },
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                  visualDensity: VisualDensity.compact,
                  title: Text("Röd"),
                  value: 3,
                  groupValue: tileColor,
                  onChanged: (int? value) {
                    prefs!.setInt("color", value!);
                    setState(() {
                      tileColor = value;
                      tileColorColor = colorList[tileColor!];
                    });
                  },
                ),
              ]);
            }),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true), // passing true
              child: Text('Stäng'),
            ),
          ],
        )
        ));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Inställningar'),
        ),
        body: ListView(
          padding: EdgeInsets.all(10),
          children: [

          Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ), child:

          Column(children: [

            Row(children: [Icon(Icons.update, size:32), TextButton(onPressed:(){
              showDialog(context: context, builder: (BuildContext context){
                return buildRefreshDialog(context);
              });
            }, child: Text('Uppdateringsintervall')), ]),
            Divider(height: 5, thickness: 1,),
            Row(
              children: [
                Icon(Icons.timer, size: 32),
                Text("Visa senaste uppdateringtid"),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Transform.scale(
                      scale: 0.8, // Adjust this value to change the size of the Switch
                      child: Switch(
                        value: showTime!,
                        onChanged: (bool value) {
                          setState(() {
                            showTime = value;
                            prefs!.setBool("time", value);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ])),
            Container(height: 10),
            Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ), child:
            Column(children: [
            Row(children: [
              Icon(Icons.pets, size:32),
              TextButton(onPressed:
                  () async {file = await _picker.pickImage(source: ImageSource.gallery);
              var dir = await getApplicationDocumentsDirectory();
              File file2 = File(file!.path);
              await file2.copy('${dir.path}/${file!.name}');
              myImage = FileImage(File('${dir.path}/${file!.name}'));
              await prefs!.setString("filename", '${dir.path}/${file!.name}');
              }, child: Text('Välj katt'))]),
              Divider(height: 5, thickness: 1,),
            Row(children: [
              Icon(Icons.palette, size:32),
              TextButton(onPressed:(){
                showDialog(context: context, builder: (BuildContext context){
                  return buildColorDialog(context);
                });
              }, child: Text('Brickfärg'))]),
              Divider(height: 5, thickness: 1,),
            Row(
              children: [
                Icon(Icons.rounded_corner, size: 32),
                Text("Runda hörn"),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Transform.scale(
                      scale: 0.8, // Adjust this value to resize the Switch
                      child: Switch(
                        value: useRoundCorners!,
                        onChanged: (bool value) {
                          setState(() {
                            useRoundCorners = value;
                            prefs!.setBool("round-corners", value);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
              Divider(height: 5, thickness: 1,),
            Row(
              children: [
                Icon(Icons.gradient, size: 32),
                Text("Gradient"),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Transform.scale(
                      scale: 0.8, // Adjust this value to resize the Switch
                      child: Switch(
                        value: gradient!,
                        onChanged: (bool value) {
                          setState(() {
                            gradient = value;
                            prefs!.setBool("gradient", value);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            )]))
          ],
        )
    );
  }
}

