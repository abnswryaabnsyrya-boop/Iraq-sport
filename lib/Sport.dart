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
  List> matches = [];

  @override
  void initState() {
    super.initState();
    fetchTodayMatches();
  }

  Future<void> fetchTodayMatches() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final now = DateTime.now();
    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final url = Uri.parse(
      "https://www.thesportsdb.com/api/v1/json/3/eventsday.php?d=$dateStr&s=Soccer",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data["events"];

        if (events == null || events is! List || events.isEmpty) {
          setState(() {
            matches = [];
            isLoading = false;
          });
          return;
        }

        final parsed = events.map>((e) {
          final home = (e["strHomeTeam"] ?? "فريق 1").toString();
          final away = (e["strAwayTeam"] ?? "فريق 2").toString();
          final league = (e["strLeague"] ?? "بطولة").toString();
          final time = (e["strTime"] ?? "").toString();
          final shortTime = time.length >= 5 ? time.substring(0, 5) : time;

          final homeScore = e["intHomeScore"]?.toString();
          final awayScore = e["intAwayScore"]?.toString();
          final statusRaw = (e["strStatus"] ?? "").toString();

          final hasScore = homeScore != null &&
              awayScore != null &&
              homeScore != "null" &&
              awayScore != "null";

          final scoreText = hasScore ? "$homeScore - $awayScore" : "VS";
          final isLive = statusRaw.toLowerCase().contains("live") ||
              statusRaw.contains("1H") ||
              statusRaw.contains("2H");

          String statusLabel = "لم تبدأ";
          if (isLive) {
            statusLabel = "جارية";
          } else if (statusRaw.toLowerCase().contains("match finished") ||
              statusRaw == "FT") {
            statusLabel = "انتهت";
          } else if (hasScore) {
            statusLabel = "انتهت";
          }

          return {
            "league": league,
            "team1": home,
            "team2": away,
            "time": shortTime.isEmpty ? statusLabel : shortTime,
            "status": statusLabel,
            "score": scoreText,
            "channel": (e["strTVStation"] ?? "غير محددة").toString().isEmpty
                ? "غير محددة"
                : (e["strTVStation"] ?? "غير محددة").toString(),
          };
        });

        setState(() {
          matches = parsed;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "تعذر جلب البيانات (${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = "تحقق من اتصال الإنترنت ثم أعد المحاولة";
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
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: fetchTodayMatches,
                        child: const Text("إعادة المحاولة"),
                      ),
                    ],
                  ),
                )
              : matches.isEmpty
                  ? const Center(
                      child: Text("لا توجد مباريات متاحة اليوم في المصدر"),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        final isLive = match["status"] == "جارية";

                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isLive ? Colors.green : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Text(
                                  match["league"]!,
                                  style: const TextStyle(
                                      color: Colors.amber, fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        match["team1"]!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLive
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            match["score"]!,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isLive
                                                  ? Colors.greenAccent
                                                  : Colors.white,
                                            ),
                                          ),
                                          Text(
                                            match["time"]!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isLive
                                                  ? Colors.greenAccent
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        match["team2"]!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white12, height: 20),
                                Text(
                                  "القناة الناقلة: ${match["channel"]}",
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
