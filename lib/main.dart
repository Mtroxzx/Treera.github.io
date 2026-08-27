import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const SpeedtestApp());

class SpeedtestApp extends StatelessWidget {
  const SpeedtestApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Speedtest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xff0b1220),
          fontFamily: 'Arial',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4ed9ed), brightness: Brightness.dark),
        ),
        home: const SpeedtestPage(),
      );
}

class SpeedtestPage extends StatefulWidget {
  const SpeedtestPage({super.key});
  @override
  State<SpeedtestPage> createState() => _SpeedtestPageState();
}

class _SpeedtestPageState extends State<SpeedtestPage> {
  static final downloadUri = Uri.parse('https://speed.cloudflare.com/__down?bytes=12000000');
  static final uploadUri = Uri.parse('https://speed.cloudflare.com/__up');
  String mode = 'download', phase = 'พร้อมเริ่มการทดสอบ', helper = 'การทดสอบใช้ข้อมูลอินเทอร์เน็ตเล็กน้อย';
  String network = 'พร้อมทดสอบ', connection = 'ยังไม่ได้ทดสอบ';
  double speed = 0, maximum = 0;
  double? downloadResult, uploadResult;
  bool running = false, expired = false;
  http.Client? client;
  Timer? timer;

  @override
  void dispose() { timer?.cancel(); client?.close(); super.dispose(); }

  void setMode(String value) {
    if (running) return;
    setState(() { mode = value; speed = 0; phase = 'พร้อมเริ่มการทดสอบ'; });
  }

  void updateSpeed(int bytes, DateTime started) {
    final seconds = DateTime.now().difference(started).inMicroseconds / 1000000;
    final value = seconds > 0 ? bytes * 8 / seconds / 1000000 : 0.0;
    if (mounted) setState(() { speed = value; if (value > maximum) maximum = value; });
  }

  Future<void> measureDownload(DateTime deadline) async {
    final started = DateTime.now();
    var bytes = 0;
    while (DateTime.now().isBefore(deadline)) {
      final response = await client!.send(http.Request('GET', downloadUri));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception();
      await for (final chunk in response.stream) {
        bytes += chunk.length;
        updateSpeed(bytes, started);
        if (!DateTime.now().isBefore(deadline)) break;
      }
    }
  }

  Future<void> measureUpload(DateTime deadline) async {
    final started = DateTime.now();
    final data = List<int>.filled(6000000, 0);
    var bytes = 0;
    while (DateTime.now().isBefore(deadline)) {
      final response = await client!.post(uploadUri, body: data);
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception();
      bytes += data.length;
      updateSpeed(bytes, started);
    }
  }

  Future<void> startTest() async {
    if (running) { expired = false; client?.close(); return; }
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    setState(() {
      running = true; maximum = 0; speed = 0; expired = false;
      network = 'กำลังทดสอบ'; connection = 'กำลังทำงาน'; helper = 'ตัวเลขกำลังอัปเดตแบบเรียลไทม์'; phase = 'เหลือเวลา 15 วิ';
    });
    client = http.Client();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => phase = 'เหลือเวลา ${(deadline.difference(DateTime.now()).inSeconds + 1).clamp(0, 15)} วิ');
      if (!DateTime.now().isBefore(deadline)) { expired = true; client?.close(); }
    });
    try {
      if (mode == 'download') await measureDownload(deadline); else await measureUpload(deadline);
      finishSuccess();
    } catch (error) {
      if (expired) finishSuccess(); else if (error is http.ClientException || error is StateError) finishStopped(); else finishError();
    } finally {
      timer?.cancel(); timer = null; client?.close(); client = null;
      if (mounted) setState(() => running = false);
    }
  }

  void finishSuccess() {
    if (!mounted) return;
    setState(() {
      speed = maximum;
      if (mode == 'download') downloadResult = maximum; else uploadResult = maximum;
      phase = 'ครบ 15 วิ · ค่าสูงสุด'; connection = 'เชื่อมต่อปกติ'; network = 'ทดสอบเสร็จ'; helper = 'แสดงความเร็วสูงสุดจากการทดสอบ 15 วินาที';
    });
  }
  void finishStopped() => setState(() { phase = 'หยุดการทดสอบ'; helper = 'การทดสอบถูกหยุดแล้ว'; connection = 'หยุดแล้ว'; network = 'พร้อมทดสอบ'; });
  void finishError() => setState(() { phase = 'ทดสอบไม่สำเร็จ'; helper = 'ตรวจสอบอินเทอร์เน็ต แล้วลองใหม่อีกครั้ง'; connection = 'เชื่อมต่อไม่สำเร็จ'; network = 'พร้อมทดสอบ'; });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(body: Container(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.1, colors: [Color(0xff1c3554), Color(0xff0b1220)])),
      child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(width < 420 ? 16 : 20, 18, width < 420 ? 16 : 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.bolt, color: Color(0xff4ed9ed), size: 30), SizedBox(width: 8), Text('Speedtest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]), Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xff62dfa8), shape: BoxShape.circle)), const SizedBox(width: 7), Text(network, style: const TextStyle(color: Color(0xff9baabd), fontSize: 12))])]),
          const SizedBox(height: 38), const Text('เช็กความเร็ว\nอินเทอร์เน็ต', style: TextStyle(fontSize: 42, height: 1.1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10), const Text('เลือกประเภทการวัด แล้วเริ่มทดสอบการเชื่อมต่อของคุณ', style: TextStyle(color: Color(0xff9baabd), fontSize: 14)), const SizedBox(height: 28),
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xff0f1929), border: Border.all(color: const Color(0xff2b3b53)), borderRadius: BorderRadius.circular(13)), child: Row(children: [_modeButton('download', 'ดาวน์โหลด'), _modeButton('upload', 'อัปโหลด')])),
          const SizedBox(height: 34), Center(child: SizedBox(width: width < 420 ? 270 : 310, height: width < 420 ? 270 : 310, child: CustomPaint(painter: MeterPainter(progress: maximum > 0 ? .58 : 0), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(mode == 'download' ? 'ความเร็วดาวน์โหลด' : 'ความเร็วอัปโหลด', style: const TextStyle(color: Color(0xff9baabd), fontSize: 13)), Text(speed.toStringAsFixed(1), style: const TextStyle(color: Color(0xff4ed9ed), fontFamily: 'Georgia', fontSize: 66, height: 1)), const Text('Mbps', style: TextStyle(fontSize: 18)), const SizedBox(height: 6), Text(phase, style: const TextStyle(color: Color(0xff9baabd), fontSize: 12))]))))),
          const SizedBox(height: 28), ElevatedButton(onPressed: startTest, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: const Color(0xff4ed9ed), foregroundColor: const Color(0xff06121c), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(running ? 'Stop' : 'Start', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          const SizedBox(height: 12), Center(child: Text(helper, style: const TextStyle(color: Color(0xff9baabd), fontSize: 12))), const SizedBox(height: 28),
          Row(children: [_result('ดาวน์โหลด', downloadResult), const SizedBox(width: 10), _result('อัปโหลด', uploadResult)]), const SizedBox(height: 14), Row(children: [_detail('เซิร์ฟเวอร์', 'Cloudflare Speed Test'), const SizedBox(width: 12), _detail('สถานะ', connection)]), const SizedBox(height: 36),
          const Center(child: Text('ผลลัพธ์เป็นค่าประมาณ อาจเปลี่ยนตามสัญญาณและเซิร์ฟเวอร์', style: TextStyle(color: Color(0xff64758b), fontSize: 11))),
        ]),
      ))))),
    );
  }

  Widget _modeButton(String value, String label) => Expanded(child: TextButton(onPressed: () => setMode(value), style: TextButton.styleFrom(minimumSize: const Size.fromHeight(47), backgroundColor: mode == value ? const Color(0xff4ed9ed) : Colors.transparent, foregroundColor: mode == value ? const Color(0xff07121b) : const Color(0xff9baabd), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))));
  Widget _result(String label, double? value) => Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xff111b2b), border: Border.all(color: const Color(0xff2b3b53)), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xff9baabd), fontSize: 11)), const SizedBox(height: 4), Text('${value?.toStringAsFixed(1) ?? '—'} Mbps', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))])));
  Widget _detail(String label, String value) => Expanded(child: Text.rich(TextSpan(text: '$label\n', style: const TextStyle(color: Color(0xff9baabd), fontSize: 11), children: [TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 13))])));
}

class MeterPainter extends CustomPainter {
  const MeterPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.width / 2 - 8;
    final background = Paint()..style = PaintingStyle.stroke..strokeWidth = 18..color = const Color(0xff253b59);
    final foreground = Paint()..style = PaintingStyle.stroke..strokeWidth = 18..strokeCap = StrokeCap.round..shader = const LinearGradient(colors: [Color(0xff4ed9ed), Color(0xff4387ff)]).createShader(Offset.zero & size);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, 2 * 3.14159, false, background);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14159 / 2, 2 * 3.14159 * (progress == 0 ? .58 : progress), false, foreground);
    canvas.drawCircle(center, radius - 13, Paint()..color = const Color(0xff0b1220));
  }
  @override
  bool shouldRepaint(MeterPainter oldDelegate) => oldDelegate.progress != progress;
}
