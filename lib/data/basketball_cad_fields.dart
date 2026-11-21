import 'project_requirements.dart';

bool basketballCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' &&
    const {'sports_complex','sports_club','training_centre','playground','recreation_centre'}.contains(type);

RequirementField _m(String key, String label, {num min = .001}) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:300,required:true);

final basketballCadFields = <RequirementField>[
  _m('bk_width','Marked court width'),
  _m('bk_length','Marked baseline-to-baseline length'),
  _m('bk_side','Clear side run-off outside each sideline'),
  _m('bk_end','Clear end run-off behind each baseline'),
  _m('bk_left','Run-off envelope offset from plot left', min:0),
  _m('bk_front','Run-off envelope offset from plot frontage'),
  _m('bk_walk','Clear width of the front approach'),
  _m('bk_rim','Basket centre offset inside each baseline'),
  _m('bk_centre_r','Centre circle radius'),
  _m('bk_key_width','Width of each key'),
  _m('bk_key_depth','Baseline to free-throw line'),
  _m('bk_free_r','Free-throw semicircle radius'),
  _m('bk_three_r','Three-point arc radius from basket centre'),
  _m('bk_corner_inset','Straight corner line inset from each sideline'),
];
