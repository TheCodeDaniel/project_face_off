/// Coarse device-capability bucket (Blueprint Section 6: "a lightweight
/// device-capability check at first launch ... buckets the device into a
/// performance tier; visual effects ... scale down automatically on lower
/// tiers rather than being all-or-nothing"). Consumers gate the *decorative*
/// (not functional) part of an effect on this — a low-tier device still
/// gets the shimmer card and the glassy nav bar, just without the animated
/// sweep / blur layered on top.
enum DeviceTier { low, mid, high }
