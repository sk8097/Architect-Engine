class TutorialItem {
  final String icon;
  final String title;
  final String subtitle;
  final String intro;
  final List<String> steps;
  final String tip;

  const TutorialItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.steps,
    required this.tip,
  });
}

class TutorialsData {
  static const List<TutorialItem> items = [
    TutorialItem(
      icon: '🚀',
      title: 'Getting Started with Architect Engine',
      subtitle: 'Learn the fundamentals of creating your first project',
      intro: 'Welcome to Architect Engine! Follow these quick steps to launch your first design project:',
      steps: [
        'Tap the "+ New Project" button located prominently on the Home dashboard.',
        'Input your real plot dimensions: Length and Width in feet or meters.',
        'Choose your room configuration (e.g. 2BHK, 3BHK, Custom) and number of floor levels.',
        'Specify your plot orientation (North, East, South, West) for auto-Vastu alignment.',
        'Choose your architectural styling: Modern Contemporary, Minimalist, Traditional, or Luxury.',
        'Set your target budget range to let the app calibrate recommended materials and finishes.',
        'Tap "Save Project" to store your project securely and unlock full drawing modules.',
      ],
      tip: 'Tip: For your initial test, start with a standard 30x40 or 40x60 ft rectangular plot.',
    ),
    TutorialItem(
      icon: '📐',
      title: 'Creating Architectural Floor Plans',
      subtitle: 'Spatial room layout planning and dimensioning',
      intro: 'A floor plan forms the bedrock of any building project. Here is how to plan it efficiently:',
      steps: [
        'Open the Design tab and select "Floor Plan" module.',
        'Verify your plot setbacks (front, rear, and side clearances as mandated by local bylaws).',
        'Place the living room and entryway in the North or East zones for natural daylight.',
        'Position the kitchen in South-East (Agni corner) and master bedroom in South-West.',
        'Define clear circulation corridors connecting rooms without wasted hallway space.',
        'Verify door swings and window ventilation points for every habitable room.',
        'Inspect the carpet area and built-up area totals calculated automatically.',
      ],
      tip: 'Rule of thumb: A comfortable 3BHK home typically spans between 1200 to 1800 sq.ft.',
    ),
    TutorialItem(
      icon: '📏',
      title: 'Mastering Unit Conversions',
      subtitle: 'Switch seamlessly between Metric and Imperial units',
      intro: 'Construction sites frequently juggle feet, inches, meters, and local land metrics:',
      steps: [
        'Navigate to Drawer → Unit Converter or open Tool #1 from the Tools tab.',
        'Select your conversion type: Length, Area, Volume, or Weight.',
        'Enter your quantity in the input field.',
        'Select the origin unit (e.g., Square Feet, Guntha, Gaj, Bigha, Acres, Square Meters).',
        'Observe instant real-time conversions without needing an internet connection.',
      ],
      tip: 'Standard conversions: 1 sq.m = 10.764 sq.ft | 1 Gaj = 9 sq.ft | 1 Guntha = 1089 sq.ft.',
    ),
    TutorialItem(
      icon: '🕉️',
      title: 'Applying Vastu Principles to Your Layout',
      subtitle: 'Ancient spatial orientation principles made easy',
      intro: 'Architect Engine features built-in directional guidelines for positive living:',
      steps: [
        'Confirm your plot cardinal direction using a smartphone compass or site survey.',
        'Main Door: Place in the auspicious fourth or fifth pada of North or East wall.',
        'Kitchen: Align the gas stove so you face East while preparing food.',
        'Master Bedroom: Keep in the South-West zone for health, peace, and longevity.',
        'Pooja Room: Set in North-East (Ishaan) and ensure no toilets share a wall with it.',
        'Staircase: Construct in South or West turning clockwise as you ascend.',
      ],
      tip: 'Refer to the comprehensive Vastu Guide section in the side drawer for room-by-room details.',
    ),
    TutorialItem(
      icon: '💾',
      title: 'Saving, Managing & Backing Up Projects',
      subtitle: 'Keep your work organized, secure, and accessible',
      intro: 'Every project you create is automatically indexed and preserved:',
      steps: [
        'All your creations appear directly under the "My Projects" section on Home.',
        'Tap any project card to open, review details, or update plot specifications.',
        'Use the "Duplicate" option to test alternative layouts without losing your baseline.',
        'Enable Cloud Sync to maintain cloud backups alongside local offline storage.',
        'Connect your Google Drive account for one-click cloud archiving.',
      ],
      tip: 'Naming tip: Give descriptive names like "Sharma Villa — 40x50 East Facing — R1".',
    ),
    TutorialItem(
      icon: '🎨',
      title: 'Personalizing Theme & Languages',
      subtitle: 'Dark mode, Light mode, and 5 Indian regional languages',
      intro: 'Tailor Architect Engine to match your personal working environment:',
      steps: [
        'Tap the moon/sun icon 🌗 in the top right header to instantly toggle between Dark and Light mode.',
        'Open Side Drawer → App Preferences → Theme to set your permanent preference.',
        'Open Side Drawer → Language to switch the interface language.',
        'Full UI translation is available in English, हिंदी, मराठी, ગુજરાતી, and தமிழ்.',
      ],
      tip: 'Dark mode is optimized for evening drafting sessions, saving battery on OLED displays.',
    ),
    TutorialItem(
      icon: '💰',
      title: 'Understanding Construction Cost & BOQ',
      subtitle: 'Estimation formulas, material quantities, and contractor quotes',
      intro: 'Estimate construction expenditure with realistic material ratios:',
      steps: [
        'Civil Construction Cost: Generally spans ₹1,500 to ₹2,500 per sq.ft based on grade.',
        'Finishing & Interiors: Accounts for ₹600 to ₹1,800 per sq.ft (flooring, sanitary, paint).',
        'Consultancy & Approvals: Municipality sanctions and architecture charges average 5% to 8%.',
        'Contingency Buffer: Always reserve 10% for material price variations and foundation surprises.',
        'Explore Tools 81–95 in the Tools tab for itemized rate analysis and cement/steel calculators.',
      ],
      tip: 'Always collect 3 detailed contractor quotations with specified material brands before starting.',
    ),
  ];
}
