class OpportunityGroup {
  const OpportunityGroup({required this.count, required this.memberIds});

  final int count;
  final List<String> memberIds;
}

class PortfolioSummary {
  const PortfolioSummary({
    required this.allListings,
    required this.underOnboarding,
    required this.toRentIn,
    required this.toLeaseOut,
  });

  final int allListings;
  final int underOnboarding;
  final OpportunityGroup toRentIn;
  final OpportunityGroup toLeaseOut;
}
