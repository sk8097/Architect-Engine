class DesignModule {
  final int id;
  final String icon;
  final String key;
  final String status; // 'available', 'progress', 'planned'
  final bool isFullCard;

  const DesignModule({
    required this.id,
    required this.icon,
    required this.key,
    required this.status,
    this.isFullCard = false,
  });
}

class ProfessionalModule {
  final int id;
  final String icon;
  final String key;
  final String status;
  final String fullDescription;
  final List<String> uses;
  final String screenDesign;

  const ProfessionalModule({
    required this.id,
    required this.icon,
    required this.key,
    required this.status,
    required this.fullDescription,
    required this.uses,
    required this.screenDesign,
  });
}
