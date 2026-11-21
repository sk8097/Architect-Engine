import 'project_requirements.dart';

const badmintonCadTypes={'indoor_arena','sports_complex','sports_club','training_centre','recreation_centre'};

const badmintonCadFields=<RequirementField>[
  RequirementField('bc_side_clear','Clear side run-off outside each court boundary',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('bc_end_clear','Clear end run-off outside each court baseline',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('bc_singles_inset','Singles line inset from each doubles sideline',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('bc_short_service','Short service-line distance from the net',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('bc_long_service','Doubles long service-line inset from baseline',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('bc_player_walk','Clear width of the front player approach',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];

const badmintonViewingFields=<RequirementField>[
  RequirementField('bc_view_aisle','Clear spectator aisle and approach width',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('bc_seat_span','Seat width along the side of the hall',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('bc_seat_depth','Seating footprint depth across the viewing strip',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];
