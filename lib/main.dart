import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing App',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Drawing App'),
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
  List<LinePoints> lines = <LinePoints>[];
  List<LinePoints> undoLines = <LinePoints>[];
  List<Offset> nowPoints = <Offset>[];
  Color nowColor = Colors.red;
  double nowStrokeWidth = 5.0;
  bool canUndo = false;
  bool canRedo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          SizedBox(
            width: 50,
            child: TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: canUndo ? Colors.white : Colors.grey,
                backgroundColor: Colors.blue,
                shape: const CircleBorder(side: BorderSide(style: BorderStyle.none)),
              ),
              onPressed: (){
                if (!canUndo){return;}
                if (nowPoints.isNotEmpty) {
                  setState(() {
                    undoLines.add(LinePoints(List<Offset>.from(nowPoints),nowColor,nowStrokeWidth));
                    nowPoints.clear();
                  });
                } else {
                  setState(() {
                    LinePoints line = lines.last;
                    undoLines.add(line);
                    lines.removeLast();
                  });
                }
                if (lines.length <= 1){canUndo = false;}
                canRedo = true;
              },
              child: const Icon(Icons.undo),
            ),
          ),
          SizedBox(
            width: 50,
            child: TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: canRedo ? Colors.white : Colors.grey,
                backgroundColor: Colors.blue,
                shape: const CircleBorder(side: BorderSide(style: BorderStyle.none)),
              ),
              onPressed: (){
                setState(() {
                  canUndo = true;
                  lines.add(undoLines.last);
                  undoLines.removeLast();
                  if (undoLines.isEmpty) {canRedo = false;}

                });
              },
              child: const Icon(Icons.redo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 50,
              child: TextButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: lines.isNotEmpty ? Colors.white : Colors.grey,
                  backgroundColor: Colors.blue,
                  shape: const CircleBorder(side: BorderSide(style: BorderStyle.none)),
                ),
                onPressed: (){
                  setState(() {
                    lines.clear();
                    nowPoints.clear();
                    undoLines.clear();
                    canUndo = false;
                    canRedo = false;
                  });
                },
                child: const Icon(Icons.refresh),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onPanDown: (DragDownDetails details){
            setState(() {
              LinePoints p = LinePoints(List<Offset>.from(nowPoints),nowColor,nowStrokeWidth);
              lines.add(p);
              nowPoints.clear();
              nowPoints.add(details.localPosition);
            });
        },
        onPanUpdate: (DragUpdateDetails details){
          // 二本指対策
          // margin より離れた点は無視する
          const margin = 20.0;
          if (nowPoints.isEmpty) {
            setState(() {
              nowPoints.add(details.localPosition);
            });
            return;
          }
          if ((nowPoints.last.dx - details.localPosition.dx > margin || details.localPosition.dx - nowPoints.last.dx > margin) &&
              (nowPoints.last.dy - details.localPosition.dy > margin || details.localPosition.dy - nowPoints.last.dy > margin)){return;}
          setState(() {
            nowPoints.add(details.localPosition);
          });
        },
        onPanEnd: (DragEndDetails details) {
          // Undoできると通知
          setState(() {
            canUndo = true;
          });
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: CustomPaint(
            painter: PaintCanvas(lines,nowPoints,nowColor,nowStrokeWidth),
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        closeManually: true,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.refresh),
            label: 'Clear',
            backgroundColor: Colors.red,
            onTap: () {
              lines.clear();
              nowPoints.clear();
              canUndo = false;
            },
          ),
        ],
      ),
    );
  }
}

class PaintCanvas extends CustomPainter {
  final List<LinePoints> lines;
  final List<Offset> nowPoints;
  final Color nowColor;
  final double nowStrokeWidth;

  const PaintCanvas(this.lines, this.nowPoints, this.nowColor, this.nowStrokeWidth);

  @override
  void paint(Canvas canvas,Size size) {
    Paint paint = Paint()
      ..isAntiAlias = true
      ..color = nowColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = nowStrokeWidth;
    for (int i = 1; i < nowPoints.length; i++) {
      Offset point1 = nowPoints[i - 1];
      Offset point2 = nowPoints[i];
      canvas.drawLine(point1, point2, paint);
    }
    if (lines.isNotEmpty){
      for (int i = 1; i < lines.length; i ++) {
        Paint paint = Paint()
          ..color = lines[i].lineColor
          ..strokeWidth = lines[i].strokeWidth;
        for (int j = 1; j < lines[i].points.length; j++) {
          Offset point1 = lines[i].points[j - 1];
          Offset point2 = lines[i].points[j];
          canvas.drawLine(point1, point2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }}

class LinePoints {
  final List<Offset> points;
  final Color lineColor;
  final double strokeWidth;
  LinePoints(this.points,this.lineColor, this.strokeWidth);
}
