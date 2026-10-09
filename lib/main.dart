import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  bool isFirstTime = prefs.getBool('is_first_time') ?? true;
  String? secretaryName = prefs.getString('secretary_name');
  bool? isMale = prefs.getBool('is_male');
  bool? isUserMale = prefs.getBool('is_user_male');

  runApp(SecretaryApp(
    isFirstTime: isFirstTime,
    savedName: secretaryName,
    savedIsMale: isMale,
    savedIsUserMale: isUserMale,
  ));
}

class SecretaryApp extends StatelessWidget {
  final bool isFirstTime;
  final String? savedName;
  final bool? savedIsMale;
  final bool? savedIsUserMale;

  const SecretaryApp({
    super.key,
    required this.isFirstTime,
    this.savedName,
    this.savedIsMale,
    this.savedIsUserMale,
  });

  @override
  Widget build(BuildContext context) {
    Widget homeScreen;

    if (isFirstTime) {
      homeScreen = const TermsAndPermissionsScreen();
    } else {
      homeScreen = MainDashboard(
        secretaryName: savedName ?? 'أحمد',
        isMale: savedIsMale ?? true,
        isUserMale: savedIsUserMale ?? true,
      );
    }

    return MaterialApp(
      title: 'السكرتير الذكي الفخم',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      locale: const Locale('ar', 'SA'),
      theme: ThemeData(
        primaryColor: const Color(0xFF1B2A4A),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: homeScreen,
    );
  }
}

// 1. شاشة الاتفاقية والأذونات
class TermsAndPermissionsScreen extends StatefulWidget {
  const TermsAndPermissionsScreen({super.key});

  @override
  State<TermsAndPermissionsScreen> createState() => _TermsAndPermissionsScreenState();
}

class _TermsAndPermissionsScreenState extends State<TermsAndPermissionsScreen> {
  bool _agreed = false;

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupSecretaryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اتفاقية الاستخدام والأذونات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B2A4A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.verified_user_sharp, size: 80, color: Color(0xFF1B2A4A)),
            const SizedBox(height: 15),
            const Text(
              'مرحباً بك في نظام السكرتير الشخصي الذكي',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'يتطلب تشغيل السكرتير الذكي الأذونات التالية للعمل في الخلفية والحساسات:',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text('• المايكروفون: للاستجابة عند الهز أو المناداة باسم السكرتير.', style: TextStyle(fontSize: 14, height: 1.6)),
                      SizedBox(height: 5),
                      Text('• التنبيهات والإشعارات: لإطلاق المنبه الصوتي والتذكير المسبق بالمناسبات.', style: TextStyle(fontSize: 14, height: 1.6)),
                      SizedBox(height: 5),
                      Text('• مستشعرات الحركة: للتعرف على هز الجهاز وتفعيل المساعد مباشرة.', style: TextStyle(fontSize: 14, height: 1.6)),
                      SizedBox(height: 15),
                      Text('جميع البيانات محفوظة بأمان محلياً على جهازك.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  activeColor: const Color(0xFF1B2A4A),
                  onChanged: (v) => setState(() => _agreed = v!),
                ),
                const Expanded(
                  child: Text('أوافق على الشروط والأذونات المطلوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2A4A),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _agreed ? _requestPermissions : null,
              child: const Text('متابعة وإعطاء الأذونات', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// 2. شاشة إعداد السكرتير والمستخدم
class SetupSecretaryScreen extends StatefulWidget {
  const SetupSecretaryScreen({super.key});

  @override
  State<SetupSecretaryScreen> createState() => _SetupSecretaryScreenState();
}

class _SetupSecretaryScreenState extends State<SetupSecretaryScreen> {
  String _gender = 'male';
  String _userGender = 'male';
  final TextEditingController _nameController = TextEditingController(text: 'أحمد');

  final List<String> _maleNames = ['أحمد', 'كريم', 'عمر', 'محمود', 'يوسف'];
  final List<String> _femaleNames = ['سارة', 'مريم', 'ندى', 'نور', 'ياسمين'];

  void _onGenderChanged(String newGender) {
    setState(() {
      _gender = newGender;
      if (_gender == 'male') {
        _nameController.text = _maleNames[0];
      } else {
        _nameController.text = _femaleNames[0];
      }
    });
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    await prefs.setString('secretary_name', _nameController.text);
    await prefs.setBool('is_male', _gender == 'male');
    await prefs.setBool('is_user_male', _userGender == 'male');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainDashboard(
            secretaryName: _nameController.text,
            isMale: _gender == 'male',
            isUserMale: _userGender == 'male',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentSuggestedNames = _gender == 'male' ? _maleNames : _femaleNames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد هويّة ونوع السكرتير'),
        backgroundColor: const Color(0xFF1B2A4A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _gender == 'male' ? const Color(0xFF1B2A4A) : Colors.pink.shade800,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC5A059), width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                ),
                child: Icon(
                  _gender == 'male' ? Icons.face : Icons.face_3,
                  size: 90,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _gender == 'male' ? 'صوت السكرتير (رجل)' : 'صوت السكرتيرة (سيدة)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onGenderChanged('male'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _gender == 'male' ? const Color(0xFF1B2A4A) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _gender == 'male' ? const Color(0xFFC5A059) : Colors.grey.shade400,
                            width: _gender == 'male' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.male, color: _gender == 'male' ? Colors.white : Colors.black87),
                            const SizedBox(width: 8),
                            Text('سكرتير (رجل)', style: TextStyle(fontWeight: FontWeight.bold, color: _gender == 'male' ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onGenderChanged('female'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _gender == 'female' ? Colors.pink.shade800 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _gender == 'female' ? const Color(0xFFC5A059) : Colors.grey.shade400,
                            width: _gender == 'female' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.female, color: _gender == 'female' ? Colors.white : Colors.black87),
                            const SizedBox(width: 8),
                            Text('سكرتيرة (سيدة)', style: TextStyle(fontWeight: FontWeight.bold, color: _gender == 'female' ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('نوع المستخدم (صاحب الهاتف):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('ذكر (يا فندم)'),
                      value: 'male',
                      groupValue: _userGender,
                      onChanged: (v) => setState(() => _userGender = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('أنثى (يا أستاذة)'),
                      value: 'female',
                      groupValue: _userGender,
                      onChanged: (v) => setState(() => _userGender = v!),
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 15),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('اختر اسماً أو اكتب اسماً مخصصاً:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: currentSuggestedNames.map((name) {
                  return ActionChip(
                    label: Text(name),
                    backgroundColor: _nameController.text == name ? const Color(0xFFC5A059) : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: _nameController.text == name ? Colors.black : Colors.black87,
                      fontWeight: _nameController.text == name ? FontWeight.bold : FontWeight.normal,
                    ),
                    onPressed: () {
                      setState(() {
                        _nameController.text = name;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم السكرتير',
                  prefixIcon: const Icon(Icons.badge, color: Color(0xFF1B2A4A)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2A4A),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveAndContinue,
                child: const Text('دخول لوحة التحكم', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 3. اللوحة الرئيسية مع ميزات التنبيه المستمر، الهز، والتذكير المسبق
class MainDashboard extends StatefulWidget {
  final String secretaryName;
  final bool isMale;
  final bool isUserMale;

  const MainDashboard({
    super.key,
    required this.secretaryName,
    required this.isMale,
    this.isUserMale = true,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _specialEvents = [];
  Map<String, String> _diaries = {};

  final List<Timer> _activeTimers = [];
  StreamSubscription? _accelerometerSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _configureVoiceAndGreet();
    _speech.initialize();
    _initShakeDetector();
  }

  // 📳 كاشف اهتزاز الجهاز (Shake Sensor)
  void _initShakeDetector() {
    _accelerometerSub = accelerometerEvents.listen((AccelerometerEvent event) {
      double gX = event.x / 9.81;
      double gY = event.y / 9.81;
      double gZ = event.z / 9.81;
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > 2.2) { // حد شدة الهز
        if (!_isListening) {
          _listenVoiceCommand();
        }
      }
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    String? tasksString = prefs.getString('saved_tasks');
    if (tasksString != null) {
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(json.decode(tasksString));
      });
    }

    String? eventsString = prefs.getString('saved_events');
    if (eventsString != null) {
      setState(() {
        _specialEvents = List<Map<String, dynamic>>.from(json.decode(eventsString));
      });
    } else {
      _specialEvents = [
        {'title': 'عيد ميلاد العائلة', 'detail': 'تذكر تجهيز الهدية', 'advanceReminder': 'قبلها بيوم'},
        {'title': 'ذكرى الزواج', 'detail': 'حجز المطعم', 'advanceReminder': 'قبلها بأسبوع'},
      ];
    }

    String? diariesString = prefs.getString('saved_diaries');
    if (diariesString != null) {
      setState(() {
        _diaries = Map<String, String>.from(json.decode(diariesString));
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_tasks', json.encode(_tasks));
    await prefs.setString('saved_events', json.encode(_specialEvents));
    await prefs.setString('saved_diaries', json.encode(_diaries));
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    for (var timer in _activeTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  // 🔊 إعداد نبرة وصوت السكرتير
  Future<void> _configureVoiceAndGreet() async {
    await _tts.setLanguage("ar-SA");

    try {
      var voices = await _tts.getVoices;
      if (voices != null && voices is List) {
        for (var voice in voices) {
          String name = voice["name"].toString().toLowerCase();
          String locale = voice["locale"].toString().toLowerCase();

          if (locale.contains("ar")) {
            if (widget.isMale) {
              if (name.contains("male") || name.contains("man") || name.contains("ar-sa-x-ard")) {
                await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
                break;
              }
            } else {
              if (name.contains("female") || name.contains("woman") || name.contains("ar-sa-x-arb")) {
                await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
                break;
              }
            }
          }
        }
      }
    } catch (_) {}

    if (widget.isMale) {
      await _tts.setPitch(0.40); // نبرة عميقة لصوت رجالي
      await _tts.setSpeechRate(0.38);
    } else {
      await _tts.setPitch(1.20);
      await _tts.setSpeechRate(0.48);
    }

    String userTitle = widget.isUserMale ? "يا فندم" : "يا أستاذة";
    String greetingText = widget.isMale
        ? "أهلاً بك $userTitle. أنا سكرتيرك ${widget.secretaryName}، هُز الهاتف في أي وقت لأكون في خدمتك."
        : "أهلاً بك $userTitle. أنا سكرتيرتك ${widget.secretaryName}، هُز الهاتف في أي وقت لأكون في خدمتك.";

    await _tts.speak(greetingText);
  }

  void _listenVoiceCommand() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: "ar_SA",
          onResult: (val) {
            String command = val.recognizedWords;
            if (val.finalResult) {
              setState(() => _isListening = false);
              _processSmartVoiceCommand(command);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // 🧠 معالجة الأوامر بالقاموس المرن الموسّع
  void _processSmartVoiceCommand(String rawCommand) async {
    String userTitle = widget.isUserMale ? "يا فندم" : "يا أستاذة";
    String cmd = rawCommand.toLowerCase();

    bool isCalledByName = cmd.contains(widget.secretaryName.toLowerCase()) || cmd.contains("يا سكرتير") || cmd.contains("يا سكرتيرة");

    // 1. التنقل بين الواجهات
    List<String> prayerKeywords = ["صلوات", "صلاة", "مواقيت", "اذان", "أذان"];
    List<String> diaryKeywords = ["يوميات", "مفكرة", "تدوين", "خواطر"];
    List<String> eventKeywords = ["مناسبات", "مناسبة", "عيد", "ذكرى"];

    if (prayerKeywords.any((k) => cmd.contains(k))) {
      setState(() => _currentIndex = 2);
      await _tts.speak("تم الانتقال لمواقيت الصلاة $userTitle.");
      return;
    } else if (diaryKeywords.any((k) => cmd.contains(k))) {
      setState(() => _currentIndex = 1);
      await _tts.speak("تم فتح قسم اليوميات $userTitle.");
      return;
    } else if (eventKeywords.any((k) => cmd.contains(k))) {
      setState(() => _currentIndex = 3);
      await _tts.speak("تم الانتقال للمناسبات السنوية $userTitle.");
      return;
    }

    // 2. القاموس الذكي للمنابهات والتذكير
    List<String> alarmKeywords = [
      "منبه", "فكرني", "تذكير", "سجل عندك", "ورايا", "ذكرني", "صحيني", "ظبط", "اضبط", "تحديد"
    ];

    bool isAlarm = alarmKeywords.any((keyword) => cmd.contains(keyword));

    if (isAlarm) {
      DateTime targetDate = DateTime.now();

      if (cmd.contains("بكره") || cmd.contains("غدا") || cmd.contains("غداً")) {
        targetDate = targetDate.add(const Duration(days: 1));
      } else if (cmd.contains("بعد بكره") || cmd.contains("بعد غد")) {
        targetDate = targetDate.add(const Duration(days: 2));
      }

      int hour = 5; // الساعة 5 افتراضياً
      Map<String, int> numberMap = {
        "واحدة": 1, "واحده": 1, "1": 1,
        "اتنين": 2, "2": 2, "تلاتة": 3, "3": 3,
        "اربعة": 4, "4": 4, "خمسة": 5, "خمسه": 5, "5": 5,
        "ستة": 6, "6": 6, "سبعة": 7, "7": 7, "تمانية": 8, "8": 8,
        "تسعة": 9, "9": 9, "عشرة": 10, "10": 10,
        "حدعشر": 11, "11": 11, "اتناشر": 12, "12": 12,
      };

      numberMap.forEach((key, val) {
        if (cmd.contains(key)) hour = val;
      });

      bool isPM = cmd.contains("مساء") || cmd.contains("بالليل") || cmd.contains("الظهر") || cmd.contains("العصر") || (hour >= 1 && hour <= 5);
      if (isPM && hour < 12) hour += 12;

      String cleanTitle = rawCommand;
      List<String> keywordsToStrip = [
        "اظبطلي", "منبه", "على", "الساعه", "الساعة", "فكرني", "تذكير", "سجل عندك", "اني", "ورايا", "عايز", "ذكرني", "صحيني", widget.secretaryName
      ];

      for (var word in keywordsToStrip) {
        cleanTitle = cleanTitle.replaceAll(RegExp(word, caseSensitive: false), "");
      }
      cleanTitle = cleanTitle.trim();

      if (cleanTitle.isEmpty) cleanTitle = "مهمة تذكيرية";

      DateTime scheduledDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, 0);

      String formattedDate = DateFormat('yyyy-MM-dd').format(targetDate);
      String formattedTime = DateFormat('hh:mm a', 'ar').format(scheduledDateTime);

      setState(() {
        _selectedDate = targetDate;
        _currentIndex = 0;
        _tasks.add({
          'date': formattedDate,
          'task': cleanTitle,
          'time': formattedTime,
          'alarm': true,
        });
      });

      _saveData();
      _scheduleContinuousAlarm(cleanTitle, scheduledDateTime);

      await _tts.speak("علم وتم التنفيذ $userTitle! تم تسجيل: $cleanTitle، في تمام الساعة ${hour > 12 ? hour - 12 : hour}.");
      return;
    }

    if (isCalledByName) {
      await _tts.speak("نعم $userTitle! أنا أسمعك، كيف يمكنني مساعدتك؟");
    } else {
      await _tts.speak("تم الاستماع لك $userTitle: $rawCommand.");
    }
  }

  // 🔔 نظام التنبيه المستمر (Continuous Loop until Stop)
  void _scheduleContinuousAlarm(String taskTitle, DateTime scheduledDateTime) {
    Duration difference = scheduledDateTime.difference(DateTime.now());
    if (difference.isNegative) return;

    Timer timer = Timer(difference, () async {
      _startAlarmLoop(taskTitle);
    });

    _activeTimers.add(timer);
  }

  void _startAlarmLoop(String taskTitle) {
    bool isStopped = false;
    String userTitle = widget.isUserMale ? "يا فندم" : "يا أستاذة";

    Timer.periodic(const Duration(seconds: 7), (loopTimer) async {
      if (isStopped) {
        loopTimer.cancel();
        return;
      }

      String speakAlert = widget.isMale
          ? "$userTitle، أنا سكرتيرك ${widget.secretaryName}. حان الآن موعد: $taskTitle!"
          : "$userTitle، أنا سكرتيرتك ${widget.secretaryName}. حان الآن موعد: $taskTitle!";

      await _tts.speak(speakAlert);
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1B2A4A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.alarm_on, color: Color(0xFFC5A059), size: 30),
              SizedBox(width: 10),
              Text('تنبيه هام ومباشر!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$userTitle، حان الآن موعد:\n"$taskTitle"',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '💡 في حال رد شخص آخر غيرك:\n"السكرتير يُعلمك بأن صاحب الجهاز طلب تذكيره بـ ($taskTitle) في هذا الوقت."',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC5A059)),
              onPressed: () {
                isStopped = true;
                _tts.stop();
                Navigator.pop(ctx);
              },
              child: const Text('خلاص (إيقاف التنبيه)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  // 🎁 إضافة مناسبة مع خيار التذكير المبكر (قبل يوم/أسبوع/شهر)
  void _addSpecialEventDialog() {
    TextEditingController titleCtrl = TextEditingController();
    TextEditingController detailCtrl = TextEditingController();
    String selectedAdvanceReminder = 'قبلها بيوم';

    final List<String> reminderOptions = [
      'في نفس اليوم',
      'قبلها بيوم',
      'قبلها بـ 3 أيام',
      'قبلها بأسبوع',
      'قبلها بـ 10 أيام',
      'قبلها بشهر'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('إضافة مناسبة خاصة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم المناسبة (عيد ميلاد/زواج)')),
              const SizedBox(height: 10),
              TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'التفاصيل أو اسم الشخص')),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedAdvanceReminder,
                decoration: const InputDecoration(labelText: 'موعد التذكير المسبق', border: OutlineInputBorder()),
                items: reminderOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                onChanged: (val) => setStateSB(() => selectedAdvanceReminder = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2A4A)),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  setState(() {
                    _specialEvents.add({
                      'title': titleCtrl.text,
                      'detail': detailCtrl.text.isEmpty ? 'مناسبة سنوية' : detailCtrl.text,
                      'advanceReminder': selectedAdvanceReminder,
                    });
                  });
                  _saveData();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ المناسبة', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _addNewTaskDialog() {
    TextEditingController taskCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool setAlarm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('إضافة موعد جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskCtrl,
                decoration: const InputDecoration(labelText: 'تفاصيل المهمة / الموعد'),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الوقت: ${selectedTime.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.access_time, color: Color(0xFFC5A059)),
                    label: const Text('تحديد الساعة', style: TextStyle(color: Color(0xFF1B2A4A))),
                    onPressed: () async {
                      TimeOfDay? t = await showTimePicker(context: context, initialTime: selectedTime);
                      if (t != null) setStateSB(() => selectedTime = t);
                    },
                  )
                ],
              ),
              CheckboxListTile(
                title: const Text('تفعيل التنبيه الصوتي المستمر'),
                value: setAlarm,
                activeColor: const Color(0xFF1B2A4A),
                onChanged: (v) => setStateSB(() => setAlarm = v!),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2A4A)),
              onPressed: () {
                if (taskCtrl.text.isNotEmpty) {
                  DateTime scheduledDateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  setState(() {
                    _tasks.add({
                      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                      'task': taskCtrl.text,
                      'time': selectedTime.format(context),
                      'alarm': setAlarm,
                    });
                  });

                  _saveData();

                  if (setAlarm) {
                    _scheduleContinuousAlarm(taskCtrl.text, scheduledDateTime);
                  }

                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ الموعد', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _openDiaryPage(DateTime date) {
    String formattedDateKey = DateFormat('yyyy-MM-dd').format(date);
    String dayName = DateFormat('EEEE', 'ar').format(date);
    String fullDateFormatted = DateFormat('dd MMMM yyyy', 'ar').format(date);

    TextEditingController diaryCtrl = TextEditingController(text: _diaries[formattedDateKey] ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B2A4A),
            foregroundColor: Colors.white,
            title: const Text('تدوين اليوميات'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFFC5A059), size: 28),
                onPressed: () {
                  setState(() {
                    _diaries[formattedDateKey] = diaryCtrl.text;
                  });
                  _saveData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ اليومية بنجاح!')),
                  );
                },
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(right: BorderSide(color: Color(0xFFC5A059), width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اليوم: $dayName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))),
                      const SizedBox(height: 4),
                      Text('التاريخ: $fullDateFormatted', style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TextField(
                    controller: diaryCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'اكتب يومياتك وأفكارك هنا بكل حرية...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildCalendarAndTasksTab(),
      _buildDiariesTab(),
      _buildPrayerTimesTab(),
      _buildSpecialEventsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A4A),
        foregroundColor: Colors.white,
        elevation: 3,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFC5A059),
              child: Icon(widget.isMale ? Icons.face : Icons.face_3, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السكرتير: ${widget.secretaryName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('هز الهاتف للتحدث مع السكرتير', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.redAccent : const Color(0xFFC5A059)),
            onPressed: _listenVoiceCommand,
          )
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addNewTaskDialog,
              backgroundColor: const Color(0xFF1B2A4A),
              icon: const Icon(Icons.add, color: Color(0xFFC5A059)),
              label: const Text('إضافة موعد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : (_currentIndex == 3
              ? FloatingActionButton.extended(
                  onPressed: _addSpecialEventDialog,
                  backgroundColor: const Color(0xFF1B2A4A),
                  icon: const Icon(Icons.card_giftcard, color: Color(0xFFC5A059)),
                  label: const Text('إضافة مناسبة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1B2A4A),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'التقويم والمهام'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'يومياتي'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_filled), label: 'مواقيت الصلاة'),
          BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'المناسبات'),
        ],
      ),
    );
  }

  Widget _buildCalendarAndTasksTab() {
    String formattedSelectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String currentTimeStr = DateFormat('hh:mm a').format(DateTime.now());
    var dayTasks = _tasks.where((t) => t['date'] == formattedSelectedDate).toList();
    String userTitle = widget.isUserMale ? "يا فندم" : "يا أستاذة";

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2A4A), Color(0xFF2C3E50)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC5A059), width: 2),
                  ),
                  child: Icon(widget.isMale ? Icons.face : Icons.face_3, size: 45, color: const Color(0xFFC5A059)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مرحباً بك $userTitle! 👋', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('الوقت الحالي: $currentTimeStr', style: const TextStyle(fontSize: 13, color: Color(0xFFC5A059), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('📳 هُز الهاتف في أي وقت أو نادِ باسم السكرتير للأوامر.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC5A059), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
            ),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('جدول أعمال اليوم:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))),
                Chip(
                  label: Text('${dayTasks.length} مواعيد', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF1B2A4A),
                ),
              ],
            ),
          ),
          dayTasks.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Icon(Icons.event_note, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('لا توجد مواعيد مسجلة لهذا اليوم', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayTasks.length,
                  itemBuilder: (ctx, i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(right: BorderSide(color: Color(0xFFC5A059), width: 5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.alarm, color: Color(0xFF1B2A4A)),
                      title: Text(dayTasks[i]['task'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text('الموعد: ${dayTasks[i]['time']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: dayTasks[i]['alarm']
                          ? const Icon(Icons.notifications_active, color: Colors.redAccent)
                          : const Icon(Icons.notifications_off, color: Colors.grey),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDiariesTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📖 مفكرة اليوميات الخاصة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 5),
              Text('اختر أي يوم من التقويم لفتح صفحة التدوين البيضاء.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              onDateChanged: (selectedDay) {
                _openDiaryPage(selectedDay);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPrayerTimesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B2A4A), Color(0xFF0F172A)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
          ),
          child: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.brightness_3, color: Color(0xFFC5A059), size: 22),
                  SizedBox(width: 8),
                  Text('التاريخ الهجري: 25 ربيع الآخر 1448 هـ', style: TextStyle(color: Color(0xFFC5A059), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Text('الصلاة القادمة: الظهر (11:45 ص)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _prayerCard('الفجر', '04:25 ص', Icons.wb_twilight, isNext: false),
        _prayerCard('الشروق', '05:52 ص', Icons.wb_sunny_outlined, isNext: false),
        _prayerCard('الظهر', '11:45 ص', Icons.wb_sunny, isNext: true),
        _prayerCard('العصر', '03:08 م', Icons.filter_drama, isNext: false),
        _prayerCard('المغرب', '05:38 م', Icons.nights_stay_outlined, isNext: false),
        _prayerCard('العشاء', '06:55 م', Icons.nights_stay, isNext: false),
      ],
    );
  }

  Widget _prayerCard(String title, String time, IconData icon, {required bool isNext}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFFFFF8EE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNext ? const Color(0xFFC5A059) : Colors.grey.shade300, width: isNext ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: ListTile(
        leading: Icon(icon, color: isNext ? const Color(0xFFC5A059) : const Color(0xFF1B2A4A)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isNext ? const Color(0xFF1B2A4A) : Colors.black87)),
        trailing: Text(time, style: TextStyle(color: isNext ? const Color(0xFFC5A059) : const Color(0xFF1B2A4A), fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSpecialEventsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('أقسام المناسبات والتنبيهات المسبقة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))),
        const SizedBox(height: 10),
        InkWell(
          onTap: _addSpecialEventDialog,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.cake, color: Colors.pink, size: 32),
              title: Text('أعياد الميلاد (اضغط للإضافة)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('تنبيهات مسبقة قبل الموعد بيوم أو أسبوع أو شهر'),
              trailing: Icon(Icons.add_circle, color: Color(0xFF1B2A4A)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('قائمة المناسبات المسجلة والخيار المسبق:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))),
        const SizedBox(height: 10),
        ..._specialEvents.map((e) => Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: ListTile(
                leading: const Icon(Icons.stars, color: Color(0xFFC5A059), size: 28),
                title: Text(e['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${e['detail']!} • التذكير المسبق: ${e['advanceReminder'] ?? "قبلها بيوم"}'),
              ),
            )),
      ],
    );
  }
}
