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
  bool isLive = false;
  String banner = "جاري التحميل...";
  List matches = [];

  final List fallbackMatches = [
    {
      "league": "دوري نجوم العراق (احتياطي)",
      "team1": "الزوراء",
      "team2": "الشرطة",
      "time": "19:30",
      "score": "1 - 1",
      "channel": "العراقية الرياضية",
    },
    {
      "league": "الدوري الإنجليزي الممتاز (احتياطي)",
      "team1": "أرسنال",
      "team2": "ليفربول",
      "time": "21:00",
      "score": "VS",
      "channel": "beIN Sports 1",
    },
  ];

  @override
  void initState() {
    super.initState();
    loadMatches();
  }

  Future<void> loadMatches() async {
    setState(() {
      isLoading = true;
      banner = "جاري الاتصال...";
    });

    try {
      final url = Uri.parse(
        "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4328",
      );
      final res = await http.get(url).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        throw "HTTP ${res.statusCode}";
      }

      final decoded = jsonDecode(res.body);
      final events = decoded["events"];
      if (events == null || events.isEmpty) {
        throw "لا توجد مباريات قادمة";
      }

      final temp = [];
      for (final ev in events) {
        temp.add({
          "league": (ev["strLeague"] ?? "الدوري الإنجليزي").toString(),
          "team1": (ev["strHomeTeam"] ?? "فريق 1").toString(),
          "team2": (ev["strAwayTeam"] ?? "فريق 2").toString(),
          "time": "${ev["dateEvent"] ?? ""} ${ev["strTime"] ?? ""}".trim(),
          "score": "VS",
          "channel": (ev["strTVStation"] ?? "غير محددة").toString(),
        });
      }

      setState(() {
        matches = temp;
        isLive = true;
        banner = "مباشر من API (${temp.length} مباراة)";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        matches = fallbackMatches;
        isLive = false;
        banner = "احتياطي — السبب: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مباريات اليوم"),
        actions: [
          IconButton(onPressed: loadMatches, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: matches.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isLive
                          ? Colors.green.withOpacity(0.15)
                          : Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isLive
                            ? Colors.green.withOpacity(0.5)
                            : Colors.amber.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      banner,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLive ? Colors.greenAccent : Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final item = matches[index - 1];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          "${item["league"]}",
                          style: const TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${item["team1"]}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${item["score"]}\n${item["time"]}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${item["team2"]}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "المصدر: ${item["channel"]}",
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
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
