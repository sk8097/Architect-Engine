import '../models/module_models.dart';

class ProfessionalData {
  static const List<ProfessionalModule> modules = [
    ProfessionalModule(
      id: 1,
      icon: '🖥️',
      key: 'cad',
      status: 'progress',
      fullDescription: 'Precision drawing workspace with coordinates, grid, snap, object selection, move, copy, rotate, mirror, offset, trim, extend, align. Future DXF import/edit/export integration.',
      uses: [
        'Coordinates, grid and snap for millimeter-accurate placement',
        'Object selection, move, copy, rotate, mirror operations',
        'Offset, trim, extend, align geometry tools',
        'Direct measurement and supported entity modification',
        'Future DXF import, CAD layer editing, and export workflows'
      ],
      screenDesign: 'Dedicated vector canvas with coordinate display HUD, grid overlay toggle, snap indicators, and contextual drawing toolbar that adapts to selected tool.',
    ),
    ProfessionalModule(
      id: 2,
      icon: '✏️',
      key: 'draw_tools',
      status: 'progress',
      fullDescription: 'Line, polyline, rectangle, circle, arc, hatch, select, erase, duplicate, undo/redo and object properties. Context-sensitive drawing tools.',
      uses: [
        'Draw and modify precise 2D architectural shapes',
        'Context-sensitive tool activation based on active drawing type',
        'Object properties panel for stroke color, layer, line-type, and style',
        'Multi-level undo/redo for effortless mistake recovery',
        'Smart duplicate with polar or rectangular offset and mirror'
      ],
      screenDesign: 'Left toolbar with geometric shape tools, center zoomable canvas, and collapsible right-hand properties inspector. Bottom sheet for mobile controls.',
    ),
    ProfessionalModule(
      id: 3,
      icon: '📚',
      key: 'layers',
      status: 'planned',
      fullDescription: 'Layer create/rename/delete, visibility, lock/unlock, color, line type and lineweight. Architectural, structural, electrical and plumbing layers organization.',
      uses: [
        'Create and isolate separate layers per engineering discipline',
        'Toggle visibility and freeze/lock states effortlessly',
        'Set color, line type (dashed, continuous) and lineweight per layer',
        'Organize architectural, structural, electrical, and plumbing layers',
        'Filter layer tree by active discipline or phase'
      ],
      screenDesign: 'Layer manager bottom drawer with color swatch picker, eye visibility toggle, padlock icon, and discipline group headers.',
    ),
    ProfessionalModule(
      id: 4,
      icon: '📏',
      key: 'dimensions',
      status: 'planned',
      fullDescription: 'Linear, aligned, angular, radius and diameter dimensions; unit/precision settings; dimension styles and readable annotation placement.',
      uses: [
        'Add linear, aligned, angular, radius, and diameter dimensions',
        'Configure unit display (Metric/Imperial) and precision roundings',
        'Create and store reusable dimension styles for consistency',
        'Auto-place readable annotations at appropriate drawing scale',
        'Dynamic dimension editing with linked geometry updates'
      ],
      screenDesign: 'Dimension style dropdown selector, on-screen interactive dimension placement with smart snapping to endpoints and midpoints.',
    ),
    ProfessionalModule(
      id: 5,
      icon: '📝',
      key: 'annotations',
      status: 'planned',
      fullDescription: 'Text, room labels, notes, leaders, symbols, callouts, north arrows and drawing legends with text size and plotting scale control.',
      uses: [
        'Add rich text and room name/area stamps anywhere on the drawing',
        'Multi-line notes with leader arrows and custom pointers',
        'Place standard architectural symbols, callouts, and North arrows',
        'Fine-tune text heights for exact sheet plotting scales',
        'Generate and position auto-updating drawing legends'
      ],
      screenDesign: 'Annotation ribbon toolbar with text, leader, and symbol libraries. Rich-text editor overlay with font, size, and alignment sliders.',
    ),
    ProfessionalModule(
      id: 6,
      icon: '📋',
      key: 'templates',
      status: 'planned',
      fullDescription: 'Reusable drawing sheets, title blocks, standard layers, dimension styles, annotation presets and project templates.',
      uses: [
        'Save any project setup as a standard reusable organization template',
        'Apply ISO / Indian Standard title blocks to new drawing sheets',
        'Reuse discipline layers, dimension styles, and annotation presets',
        'Build project-specific templates for rapid onboarding',
        'Import and export template files across team members'
      ],
      screenDesign: 'Templates gallery featuring visual sheet previews, Save-as-Template modal, and template metadata configuration sheet.',
    ),
    ProfessionalModule(
      id: 7,
      icon: '⚙️',
      key: 'standards',
      status: 'planned',
      fullDescription: 'Configurable units, lineweights, text styles, symbols, layer naming and drawing conventions complying with national building codes.',
      uses: [
        'Set project default units (mm, cm, m, inches, feet) and precision',
        'Configure pen lineweights and drafting line styles',
        'Standardize architectural symbols and AIA / NBC layer naming',
        'Enforce consistent drafting standards across all project sheets',
        'Maintain jurisdiction-specific compliance guidelines separately'
      ],
      screenDesign: 'Tabbed standards inspector with Units, Lineweights, Typography, Symbols, and Layer Naming configurations.',
    ),
    ProfessionalModule(
      id: 8,
      icon: '⚡',
      key: 'productivity',
      status: 'planned',
      fullDescription: 'Recent tools, favorites, command history, shortcuts, repeat-last-command, quick properties and frequently used operations.',
      uses: [
        'Instant 1-tap access to recently used and pinned favorite tools',
        'Searchable command history audit log',
        'Comprehensive keyboard shortcuts and gesture accelerators',
        'Repeat last command with a single tap or spacebar',
        'Quick properties floating panel for high-velocity editing'
      ],
      screenDesign: 'Top horizontal recent tools ribbon, pinned quick-action toolbar, and customizable shortcut mapper screen.',
    ),
    ProfessionalModule(
      id: 9,
      icon: '📄',
      key: 'documentation',
      status: 'planned',
      fullDescription: 'Drawing register, sheet numbering, revision history, drawing notes, issue status, sheet composition and PDF/DXF export workflow.',
      uses: [
        'Maintain a master drawing register for the entire project',
        'Auto-number sheets (A-101, S-101, E-101) and track revision logs',
        'Record general drawing notes, approvals, and issue status',
        'Compose multi-view sheet layouts with viewports and scales',
        'Direct export to publication-grade vector PDF and editable DXF'
      ],
      screenDesign: 'Documentation workbench with tabs for Register, Sheet Layouts, Revisions, and Batch Export status cards.',
    ),
  ];
}
