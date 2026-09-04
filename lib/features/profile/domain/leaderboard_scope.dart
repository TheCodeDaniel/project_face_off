import 'region.dart';

/// Which set of players the leaderboard ranks: everyone (Global), players in
/// the local player's own [Region] (Regional), or just people they've
/// actually added (Friends).
enum LeaderboardScope { global, regional, friends }
