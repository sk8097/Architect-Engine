class VastuItem {
  final String title;
  final List<String> guidelines;

  const VastuItem({required this.title, required this.guidelines});
}

class VastuData {
  static const List<VastuItem> items = [
    VastuItem(
      title: '🚪 Main Entrance (Mukhya Dwar)',
      guidelines: [
        'Entrance should ideally face North, East, or North-East direction for prosperity and positive energy flow.',
        'The main door should always open inward (clockwise) rather than outward.',
        'Keep the entrance well-lit with warm illumination, clutter-free, and immaculately clean.',
        'Avoid positioning the main entrance directly facing a bathroom, cooking stove, or descending staircase.',
        'Adorn the entrance threshold with a clean nameplate, auspicious toran, or traditional rangoli.',
        'Ensure the door hinges are oiled regularly to prevent any creaking sounds.',
      ],
    ),
    VastuItem(
      title: '🍳 Kitchen (Rasoi)',
      guidelines: [
        'The primary kitchen must be situated in the South-East corner (governed by Agni Deva).',
        'The cooking platform should be oriented such that one faces East while cooking.',
        'The water sink and fire stove must never be placed adjacent to or directly opposite each other.',
        'Drinking water filters (RO) or clay pots should reside in the North-East section of the kitchen.',
        'Avoid locating the kitchen directly beneath or above a bathroom.',
        'Favorable wall shades for kitchens include warm peach, light green, or soft yellow.',
        'Keep the cooking stove safe from direct wind drafts from open windows.',
      ],
    ),
    VastuItem(
      title: '🛏️ Master Bedroom',
      guidelines: [
        'The master bedroom should be situated in the South-West corner of the home for stability and health.',
        'Position the bed so that sleeping heads point toward the South or East.',
        'Ensure that mirrors or reflective wardrobe doors do not reflect the sleeping person directly.',
        'Keep electronic chargers, routers, and screens at a distance from the bed.',
        'Opt for soothing earthy shades like cream, ivory, beige, or soft moss green.',
        'Refrain from keeping active water fountains or aquariums inside the bedroom.',
        'Heavy wardrobes and storage should ideally line the South or West walls.',
      ],
    ),
    VastuItem(
      title: '🛋️ Living Room (Hall)',
      guidelines: [
        'Living rooms thrive in the North, East, or North-East directions to foster social harmony.',
        'Heavy sofas and furniture should be anchored against the Southern and Western walls.',
        'Keep the North-East quadrant of the living hall open, light, and spotless.',
        'House electronic entertainment centers and TVs along the South-East wall.',
        'Seat family and esteemed guests facing East or North for uplifting conversations.',
        'Incorporate light, luminous colors on walls and airy, sheer drapery.',
        'Immediately discard broken ornaments, non-working clocks, or dried flowers.',
      ],
    ),
    VastuItem(
      title: '🚿 Bathroom & Sanitary',
      guidelines: [
        'Bathrooms are best positioned in the West or North-West direction.',
        'Strictly avoid bathrooms in the sacred North-East (Ishaan) corner of the home.',
        'Commode seats should be aligned facing North-South.',
        'Keep the bathroom door firmly closed at all times to seal in heavy energies.',
        'Immediately repair dripping faucets and leaky pipelines.',
        'Ensure generous ventilation with high exhaust fans and light, pastel tile choices.',
        'Never place mirrors reflecting the toilet commode.',
      ],
    ),
    VastuItem(
      title: '🕉️ Pooja Room (Mandir)',
      guidelines: [
        'The sacred Pooja room must always be positioned in the North-East (Ishaan corner).',
        'Idols and deities should face West or East, allowing worshippers to face East or North.',
        'Keep the mandir tranquil, uncluttered, and gracefully lit with pure white or warm brass tones.',
        'Never construct a pooja room inside a bedroom, beneath a staircase, or adjacent to toilets.',
        'Choose natural white marble, pure teakwood, or stone for the altar shrine.',
        'Avoid keeping chipped idols, cracked glass photos, or faded offerings.',
        'Kindle an authentic ghee or oil lamp every morning and evening for divine vitality.',
      ],
    ),
    VastuItem(
      title: '🏢 Staircase',
      guidelines: [
        'Staircases belong along the South, West, or South-West perimeters of the structure.',
        'Always design staircases to ascend in a clockwise direction.',
        'Never position a heavy staircase in the delicate North-East or the central Brahmasthan.',
        'Plan the total step count to an odd number (such as 15, 17, 19, or 21).',
        'Utilize the space beneath the stairs only for dry storage, never for pooja or restrooms.',
      ],
    ),
    VastuItem(
      title: '🌳 Outdoor & Garden',
      guidelines: [
        'Plant the sacred Tulsi (Holy Basil) plant in the North-East or East courtyard.',
        'Avoid planting towering, dense shade trees in the North-East quadrant.',
        'Plant tall, broad-canopied trees along the South and West boundaries for thermal insulation.',
        'A serene water fountain or reflective pond in the North-East is deeply auspicious.',
        'Avoid planting thorny cacti or milky-sap flora right near the main entry gate.',
      ],
    ),
    VastuItem(
      title: '💡 General Harmonization Rules',
      guidelines: [
        'Keep the exact geometric center of the floor plan (Brahmasthan) open and free of pillars.',
        'Maximize natural sunlit openings along East and North for health and positive vibes.',
        'Promptly repair peeling paint, damp patches, and broken tiles.',
        'Avoid stagnant, dark alcoves with gentle accent uplighting.',
        'Incorporate natural building materials like timber, terracotta, and stone wherever feasible.',
        'Fill your morning ambiance with tranquil instrumental melodies or Vedic chants.',
      ],
    ),
  ];
}
