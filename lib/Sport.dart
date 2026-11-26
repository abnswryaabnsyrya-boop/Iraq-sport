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
  String? errorMessage;
  List matches = [];

  final List fallbackMatches = [
    {
      "league": "دوري نجوم العراق",
      "team1": "الزوراء",
      "team2": "الشرطة",
      "time": "19:30",
      "score": "1 - 1",
      "channel": "العراقية الرياضية",
    },
    {
      "league": "الدوري الإنجليزي الممتاز",
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
      errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final date =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final url = Uri.parse(
        "https://www.thesportsdb.com/api/v1/json/3/eventsday.php?d=$date&s=Soccer",
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final events = decoded["events"];
        if (events is List && events.isNotEmpty) {
          setState(() {
            matches = events.map((e) {
              final h = e["intHomeScore"]?.toString();
              final a = e["intAwayScore"]?.toString();
              final hasScore = h != null && a != null && h != "null" && a != "null";
              final t = (e["strTime"] ?? "").toString();
              return {
                "league": (e["strLeague"] ?? "بطولة").toString(),
                "team1": (e["strHomeTeam"] ?? "فريق 1").toString(),
                "team2": (e["strAwayTeam"] ?? "فريق 2").toString(),
                "time": t.length >= 5 ? t.substring(0, 5) : "اليوم",
                "score": hasScore ? "$h - $a" : "VS",
                "channel": (e["strTVStation"] ?? "غير محددة").toString(),
              };
            }).toList();
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        matches = fallbackMatches;
        errorMessage = "تم عرض قائمة احتياطية";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        matches = fallbackMatches;
        errorMessage = "تعذر الاتصال المباشر، تم عرض قائمة احتياطية";
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
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final item = matches[index];
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
