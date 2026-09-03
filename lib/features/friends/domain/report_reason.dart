/// Predefined reasons (master prompt Section 9) — reporting requires picking
/// one, not just free text, so submissions stay quick and categorizable for
/// later moderation review.
enum ReportReason {
  inappropriateUsername('Inappropriate username'),
  harassment('Harassment'),
  cheating('Cheating'),
  other('Other');

  const ReportReason(this.label);

  final String label;
}
