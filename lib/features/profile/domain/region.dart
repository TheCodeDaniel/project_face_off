/// A coarse geographic region for the leaderboard's Regional scope — country
/// granularity, not city/state, which is plenty for "who's best near me" at
/// this app's scale. Kept as a small curated enum rather than a free-text
/// field so the leaderboard can group by it cheaply, matching the informal
/// geographic spread already implied by this app's own seeded demo names.
enum Region { unitedStates, unitedKingdom, nigeria, ghana, southAfrica }

extension RegionLabel on Region {
  String get label => switch (this) {
    Region.unitedStates => 'United States',
    Region.unitedKingdom => 'United Kingdom',
    Region.nigeria => 'Nigeria',
    Region.ghana => 'Ghana',
    Region.southAfrica => 'South Africa',
  };
}
