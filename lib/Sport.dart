import 'package:flutter/material.dart';

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

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  final List matches = const [
    {
      "league": "تصفيات كأس العالم",
      "team1": "العراق",
      "team2": "الأردن",
      "time": "21:15",
      "status": "لم تبدأ",
      "score": "VS",
      "channel": "beIN Sports 1"
    },
    {
      "league": "دوري نجوم العراق",
      "team1": "الزوراء",
      "team2": "القوة الجوية",
      "time": "مباشر - د 68",
      "status": "جارية",
      "score": "2 - 1",
      "channel": "الرياضية العراقية"
    },
    {
      "league": "دوري أبطال أوروبا",
      "team1": "ريال مدريد",
      "team2": "بايرن ميونخ",
      "time": "انتهت",
      "status": "انتهت",
      "score": "3 - 2",
      "channel": "beIN Sports 2"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "كورة العراق - مباريات اليوم",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView.builder(
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
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          match["team1"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
                                color:
                                    isLive ? Colors.greenAccent : Colors.white,
                              ),
                            ),
                            Text(
                              match["time"]!,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isLive ? Colors.greenAccent : Colors.grey,
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
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  Text(
                    "القناة الناقلة: ${match["channel"]}",
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
