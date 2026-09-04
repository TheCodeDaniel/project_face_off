/// Which set of players the leaderboard ranks. Global is the default and
/// only scope the master prompt originally specified; Friends was added on
/// request so a player can see how they stack up against people they
/// actually know rather than only strangers.
///
/// A `regional` scope was considered and deliberately left out — there's no
/// per-user region/country field anywhere in the data model yet, and
/// fabricating one just to back a filter option isn't worth it until real
/// user location data exists for another reason first.
enum LeaderboardScope { global, friends }
