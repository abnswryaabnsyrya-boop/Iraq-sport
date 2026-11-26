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
  String bannerText = "جاري التحميل...";
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
      bannerText = "جاري جلب مباريات اليوم...";
    });

    try {
      final now = DateTime.now();
      final d =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      final uri = Uri.parse(
        "https://site.api.espn.com/apis/site/v2/sports/soccer/all/scoreboard?dates=$d",
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        final events = jsonData["events"];

        if (events != null && events.isNotEmpty) {
          final temp = [];
          for (final ev in events) {
            final comps = ev["competitions"];
            if (comps == null || comps.isEmpty) continue;
            final comp = comps[0];
            final teams = comp["competitors"];
            if (teams == null || teams.length < 2) continue;

            final t1 = teams[0];
            final t2 = teams[1];
            final name1 = (t1["team"]?["shortDisplayName"] ??
                    t1["team"]?["displayName"] ??
                    "فريق 1")
                .toString();
            final name2 = (t2["team"]?["shortDisplayName"] ??
                    t2["team"]?["displayName"] ??
                    "فريق 2")
                .toString();

            final state = (comp["status"]?["type"]?["state"] ?? "").toString();
            final detail =
                (comp["status"]?["type"]?["shortDetail"] ?? "اليوم").toString();
            final s1 = t1["score"]?.toString() ?? "";
            final s2 = t2["score"]?.toString() ?? "";
            final score = (state == "pre" || s1.isEmpty || s2.isEmpty)
                ? "VS"
                : "$s1 - $s2";

            final league = (ev["league"]?["name"] ??
                    jsonData["leagues"]?[0]?["name"] ??
                    "كرة القدم")
                .toString();

            temp.add({
              "league": league,
              "team1": name1,
              "team2": name2,
              "time": detail,
              "score": score,
              "channel": "ESPN / مباشر",
            });
          }

          if (temp.isNotEmpty) {
            setState(() {
              matches = temp;
              isLive = true;
              bannerText = "بيانات مباشرة (${temp.length} مباراة اليوم)";
              isLoading = false;
            });
            return;
          }
        }

        setState(() {
          matches = fallbackMatches;
          isLive = false;
          bannerText = "لا توجد مباريات مباشرة لليوم — عرض احتياطي";
          isLoading = false;
        });
      } else {
        setState(() {
          matches = fallbackMatches;
          isLive = false;
          bannerText = "استجابة السيرفر ${res.statusCode} — عرض احتياطي";
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        matches = fallbackMatches;
        isLive = false;
        bannerText = "تعذر الاتصال المباشر — عرض احتياطي";
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
          IconButton(
            onPressed: loadMatches,
            icon: const Icon(Icons.refresh),
          ),
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
                      bannerText,
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
                            Text(
                              "${item["score"]}\n${item["time"]}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
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
