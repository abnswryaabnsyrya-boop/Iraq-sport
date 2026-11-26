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
  String statusBanner = "جاري التحميل...";
  bool isLiveSource = false;
  List> matches = [];

  final List> _fallbackMatches = [
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
      statusBanner = "جاري جلب المباريات المباشرة...";
    });

    try {
      final now = DateTime.now();
      final yyyymmdd =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

      final url = Uri.parse(
        "https://site.api.espn.com/apis/site/v2/sports/soccer/all/scoreboard?dates=$yyyymmdd",
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final events = decoded is Map ? decoded["events"] : null;

        if (events is List && events.isNotEmpty) {
          final parsed = >[];

          for (final ev in events) {
            if (ev is! Map) continue;
            final competitions = ev["competitions"];
            if (competitions is! List || competitions.isEmpty) continue;
            final comp = competitions.first;
            if (comp is! Map) continue;

            final competitors = comp["competitors"];
            if (competitors is! List || competitors.length < 2) continue;

            Map? homeTeam;
            Map? awayTeam;
            for (final c in competitors) {
              if (c is Map) {
                if (c["homeAway"] == "home") homeTeam = c;
                if (c["homeAway"] == "away") awayTeam = c;
              }
            }
            homeTeam ??= competitors[0] as Map;
            awayTeam ??= competitors[1] as Map;

            final homeName =
                (homeTeam["team"]?["shortDisplayName"] ??
                        homeTeam["team"]?["displayName"] ??
                        "فريق 1")
                    .toString();
            final awayName =
                (awayTeam["team"]?["shortDisplayName"] ??
                        awayTeam["team"]?["displayName"] ??
                        "فريق 2")
                    .toString();

            final homeScore = homeTeam["score"]?.toString();
            final awayScore = awayTeam["score"]?.toString();
            final statusObj = comp["status"] is Map ? comp["status"] : {};
            final state = (statusObj["type"]?["state"] ?? "").toString();
            final detail =
                (statusObj["type"]?["shortDetail"] ?? "اليوم").toString();

            final scoreText = (state == "pre" || homeScore == null || awayScore == null)
                ? "VS"
                : "$homeScore - $awayScore";

            final leagueName =
                (ev["league"]?["name"] ??
                        decoded["leagues"]?[0]?["name"] ??
                        "بطولة كرة قدم")
                    .toString();

            final broadcasts = comp["broadcasts"];
            String channel = "غير محددة";
            if (broadcasts is List && broadcasts.isNotEmpty) {
              final names = broadcasts
                  .map((b) => b is Map ? (b["names"] is List && b["names"].isNotEmpty ? b["names"][0].toString() : "") : "")
                  .where((s) => s.toString().isNotEmpty)
                  .toList();
              if (names.isNotEmpty) channel = names.join(" / ");
            }

            parsed.add({
              "league": leagueName,
              "team1": homeName,
              "team2": awayName,
              "time": detail,
              "score": scoreText,
              "channel": channel,
            });
          }

          if (parsed.isNotEmpty) {
            setState(() {
              matches = parsed;
              isLiveSource = true;
              statusBanner = "بيانات مباشرة (${parsed.length} مباراة اليوم)";
              isLoading = false;
            });
            return;
          }
        }

        setState(() {
          matches = _fallbackMatches;
          isLiveSource = false;
          statusBanner = "المصدر المباشر رجّع 0 مباريات لليوم — عرض احتياطي";
          isLoading = false;
        });
      } else {
        setState(() {
          matches = _fallbackMatches;
          isLiveSource = false;
          statusBanner =
              "رمز استجابة السيرفر ${response.statusCode} — عرض احتياطي";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        matches = _fallbackMatches;
        isLiveSource = false;
        statusBanner = "تعذر الاتصال المباشر — عرض احتياطي";
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
                      color: isLiveSource
                          ? Colors.green.withOpacity(0.15)
                          : Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isLiveSource
                            ? Colors.green.withOpacity(0.5)
                            : Colors.amber.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      statusBanner,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isLiveSource ? Colors.greenAccent : Colors.amber,
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
                          "القناة: ${item["channel"]}",
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
