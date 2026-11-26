import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SportApp extends StatelessWidget {
  const SportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          centerTitle: true,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MatchesScreen(),
      ),
    );
  }
}

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool isLoading = true;
  String? statusNote;
  List> matches = [];

  final List> _fallbackMatches = [
    {
      "league": "دوري نجوم العراق",
      "team1": "الزوراء",
      "team2": "الشرطة",
      "time": "19:30",
      "status": "جارية",
      "score": "1 - 1",
      "channel": "العراقية الرياضية",
    },
    {
      "league": "الدوري الإنجليزي الممتاز",
      "team1": "أرسنال",
      "team2": "ليفربول",
      "time": "21:00",
      "status": "لم تبدأ",
      "score": "VS",
      "channel": "beIN Sports 1",
    },
    {
      "league": "الدوري الإسباني",
      "team1": "ريال مدريد",
      "team2": "برشلونة",
      "time": "23:00",
      "status": "انتهت",
      "score": "2 - 1",
      "channel": "beIN Sports 1",
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchTodayMatches();
  }

  Future<void> fetchTodayMatches() async {
    setState(() {
      isLoading = true;
      statusNote = null;
    });

    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "https://www.thesportsdb.com/api/v1/json/3/eventsday.php?d=$dateStr&s=Soccer",
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final events = data is Map ? data["events"] : null;

        if (events is List && events.isNotEmpty) {
          final list = >[];
          for (final item in events) {
            if (item is Map) {
              final hScore = item["intHomeScore"]?.toString();
              final aScore = item["intAwayScore"]?.toString();
              final hasScore = hScore != null &&
                  aScore != null &&
                  hScore != "null" &&
                  aScore != "null";
              final rawTime = (item["strTime"] ?? "").toString();
              final shortTime =
                  rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime;
              final tv = (item["strTVStation"] ?? "").toString().trim();

              list.add({
                "league": (item["strLeague"] ?? "بطولة").toString(),
                "team1": (item["strHomeTeam"] ?? "فريق 1").toString(),
                "team2": (item["strAwayTeam"] ?? "فريق 2").toString(),
                "time": shortTime.isEmpty ? "اليوم" : shortTime,
                "status": hasScore ? "انتهت" : "لم تبدأ",
                "score": hasScore ? "$hScore - $aScore" : "VS",
                "channel": (tv.isEmpty || tv == "null") ? "غير محددة" : tv,
              });
            }
          }

          if (list.isNotEmpty) {
            setState(() {
              matches = list;
              isLoading = false;
            });
            return;
          }
        }
      }

      setState(() {
        matches = _fallbackMatches;
        statusNote = "عرض قائمة احتياطية (لا توجد مباريات مباشرة حالياً)";
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        matches = _fallbackMatches;
        statusNote = "تعذر الوصول للمصدر المباشر، تم عرض قائمة احتياطية";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "مباريات اليوم - عالمية ومحلية",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: fetchTodayMatches,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: matches.length + (statusNote != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (statusNote != null && index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusNote!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  );
                }

                final m = matches[statusNote != null ? index - 1 : index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          m["league"]!,
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m["team1"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    m["score"]!,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    m["time"]!,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                m["team2"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 20),
                        Text(
                          "القناة الناقلة: ${m["channel"]}",
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
