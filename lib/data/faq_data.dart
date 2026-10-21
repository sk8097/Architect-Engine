class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}

class FAQData {
  static const List<FAQItem> items = [
    FAQItem(
      question: 'Is Architect Engine free to use?',
      answer: 'Yes! The core tools, including the Unit Converter, Vastu Guide, Tutorials, Project Manager, and standard calculation utilities are completely free. Advanced CAD and AI rendering features will be part of the upcoming Pro tier.',
    ),
    FAQItem(
      question: 'How does the architectural design system work?',
      answer: 'The system uses parametric design rules combined with standard National Building Code (NBC) setbacks, room clearance ratios, and Vastu orientation algorithms to generate coordinated floor plans, elevations, and structural schematics.',
    ),
    FAQItem(
      question: 'Does the application work offline?',
      answer: 'Yes! All 168 calculation tools, unit converters, Vastu guides, tutorials, and local project management work 100% offline without any internet connection. Online access is only needed for cloud syncing and sharing.',
    ),
    FAQItem(
      question: 'Where are my projects and calculations saved?',
      answer: 'All projects, saved calculations, and notes are stored locally on your device in secure persistent storage. If you enable Cloud Sync or link your Google Drive, encrypted backups are created in your personal cloud.',
    ),
    FAQItem(
      question: 'Can I export my project drawings and estimates?',
      answer: 'Yes! The Export Center supports exporting project summary sheets as print-ready PDF files, CAD-ready drawing data, and CSV/Excel Bill of Quantities (BOQ) sheets.',
    ),
    FAQItem(
      question: 'How accurate are the material calculations and cost estimates?',
      answer: 'The formulas adhere strictly to standard civil engineering dry-volume constants (e.g. 1.54 for concrete dry-volume, 1.33 for mortar, 500 bricks/m³). However, actual market rates vary by city and brand, so always verify with local suppliers.',
    ),
    FAQItem(
      question: 'Are the design plans Vastu-compliant?',
      answer: 'Yes! By default, room layouts and directional orientations follow traditional Vastu Shastra guidelines (East/North entrances, South-East kitchens, South-West master bedrooms, and North-East pooja shrines).',
    ),
    FAQItem(
      question: 'Is my personal data and drawing information secure?',
      answer: 'Your data privacy is strictly protected. Your project records reside solely on your device unless you explicitly opt to sync with your private Google Drive. We do not sell or monetize personal data.',
    ),
    FAQItem(
      question: 'How can I contact technical support or request new features?',
      answer: 'You can email our engineering team directly at support@architectengine.app or use the feedback option inside the app. We actively welcome feedback from architects, contractors, and students.',
    ),
    FAQItem(
      question: 'Can I use this app on tablets and desktops?',
      answer: 'Yes! Architect Engine is built with responsive Flutter UI that smoothly adapts to smartphones, iPads, Android tablets, and desktop screen sizes.',
    ),
  ];
}
