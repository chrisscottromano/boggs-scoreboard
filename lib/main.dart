import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const ScoreboardApp());

class ScoreboardApp extends StatelessWidget {
  const ScoreboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Scoreboard',
      home: ScoreboardPage(),
    );
  }
}

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  _ScoreboardPageState createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  List<Team> teams = [];
  // bool resettingScores = false;
  bool isLoading = true;
  double _progress = 0.0;
  bool _isResetting = false;
  Timer? _timer;
  // static const int _resetDuration = 5; // 5 seconds

  void _startResetCountdown() {
    if (_isResetting) return; // Prevent multiple countdowns

    setState(() {
      _isResetting = true;
      _progress = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.1;
      });

      if (_progress >= 1.0) {
        timer.cancel();
        resetScores();
      }
    });
  }

  void _cancelReset() {
    if (_isResetting) {
      _timer?.cancel();
      setState(() {
        _isResetting = false;
        _progress = 0.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchScoresFromServer();
  }

  Future<void> _fetchScoresFromServer() async {
    setState(() => isLoading = true);
    var url = Uri.parse(
        'https://wadeboggs-scoreboard-2024-e1e2b578fc7d.herokuapp.com/scores');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          teams = data.map((team) => Team.fromJson(team)).toList();
          isLoading = false;
        });
      } else {
        // Handle server error
      }
    } catch (e) {
      // Handle network error
    }
  }

  void updateScore(Team team, Player player, int delta) {
    setState(() {
      player.score += delta;
      team.totalScore += delta;
    });
    _sendScoresToServer();
  }

  void editTeamName(Team team, String name) {
    setState(() {
      team.name = name;
    });
    _sendScoresToServer();
  }

  void editPlayerName(Player player, String name) {
    setState(() {
      player.name = name;
    });
    _sendScoresToServer();
  }

  void resetScores() {
    setState(() {
      for (var team in teams) {
        team.totalScore = 0;
        for (var player in team.players) {
          player.score = 0;
        }
      }
    });
    _sendScoresToServer();
  }

  void addPlayer(Team team) {
    setState(() {
      team.players.add(Player(name: 'Player ${team.players.length + 1}'));
    });
    _sendScoresToServer();
  }

  void deletePlayer(Team team, Player player) {
    setState(() {
      team.players.remove(player);
      team.totalScore -= player.score;
    });
    _sendScoresToServer();
  }

  Future<void> _sendScoresToServer() async {
    var url = Uri.parse(
        'https://wadeboggs-scoreboard-2024-e1e2b578fc7d.herokuapp.com/scores');
    await http.post(
      url,
      body: json.encode(teams.map((t) => t.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialText,
      Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome, Commissioner Selig')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(0.0),
              child: ListView.builder(
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  Team team = teams[index];
                  return Card(
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Row(
                            children: [
                              Text(team.name),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(
                                  context,
                                  'Edit Team Name',
                                  team.name,
                                  (name) => editTeamName(team, name),
                                ),
                              ),
                              // Text('🍺 ${team.totalScore}'),
                            ],
                          )),
                          Text('🍺 ${team.totalScore}'),
                          // const SizedBox(
                          //   width: 100.0,
                          // ),
                          // IconButton(
                          //   icon: const Icon(Icons.edit),
                          //   onPressed: () => _showEditDialog(
                          //     context,
                          //     'Edit Team Name',
                          //     team.name,
                          //     (name) => editTeamName(team, name),
                          //   ),
                          // ),
                          // const SizedBox(
                          //   width: 5.0,
                          // ),
                        ],
                      ),
                      children: [
                        ...team.players.map((player) {
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                    child: Row(
                                  children: [
                                    SizedBox(
                                      height: 15.0,
                                      width: 15.0,
                                      child: IconButton(
                                        padding: const EdgeInsets.all(0.0),
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 15.0,
                                        ),
                                        onPressed: () =>
                                            deletePlayer(team, player),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(player.name),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20.0,),
                                      onPressed: () => _showEditDialog(
                                        context,
                                        'Edit Player Name',
                                        player.name,
                                        (name) => editPlayerName(player, name),
                                      ),
                                    ),
                                  ],
                                )),
                                Text('🍺 ${player.score}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => updateScore(team, player, 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () =>
                                      updateScore(team, player, -1),
                                ),
                                // IconButton(
                                //   icon: const Icon(Icons.edit),
                                //   onPressed: () => _showEditDialog(
                                //     context,
                                //     'Edit Player Name',
                                //     player.name,
                                //     (name) => editPlayerName(player, name),
                                //   ),
                                // ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          title: TextButton(
                            onPressed: () => addPlayer(team),
                            child: const Text('Add Player'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: GestureDetector(
        onLongPress: _startResetCountdown,
        onLongPressUp: _cancelReset,
        child: FloatingActionButton.extended(
          onPressed: () {},
          label: const Text('Hold 5s to reset scores'),
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class Team {
  String name;
  int totalScore;
  List<Player> players;

  Team({required this.name, this.totalScore = 0, required this.players});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'],
      totalScore: json['totalScore'],
      players: (json['players'] as List)
          .map((player) => Player.fromJson(player))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalScore': totalScore,
      'players': players.map((p) => p.toJson()).toList(),
    };
  }
}

class Player {
  String name;
  int score;

  Player({required this.name, this.score = 0});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
    };
  }
}
