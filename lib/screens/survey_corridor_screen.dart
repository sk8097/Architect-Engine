import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/survey_corridor_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SurveyCorridorScreen extends StatefulWidget {
  const SurveyCorridorScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<SurveyCorridorScreen> createState() => _SurveyCorridorScreenState();
}

class _SurveyCorridorScreenState extends State<SurveyCorridorScreen> {
  late final _result=SurveyCorridorGenerator().generate(widget.brief);
  late final _cad=_result.drawing==null?null:FloorPlanCad.fromSurveyCorridor(_result.drawing!);
  var _sharing=false;

  Future<void> _share(BuildContext context, FloorPlanCad cad) async {
    if (_sharing) return;
    final box=context.findRenderObject();
    final origin=box is RenderBox?box.localToGlobal(Offset.zero)&box.size:null;
    final name=widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'),'_');
    setState(()=>_sharing=true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(cad.toDxf())),mimeType:'application/dxf')],
        fileNameOverrides:['${name.isEmpty?'project':name}_survey_corridor.dxf'],sharePositionOrigin:origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content:Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(()=>_sharing=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheet=_result.drawing;
    final cad=_cad;
    return Scaffold(appBar:AppBar(title:const Text('Survey corridor CAD')),body:SafeArea(child:ListView(
      padding:const EdgeInsets.all(16),children:[
        Text(widget.name,style:Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height:8),
        if (sheet==null || cad==null) ...[
          const Text('No corridor drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading:const Icon(Icons.info_outline),title:Text(issue)),
        ] else ...[
          Text('${sheet.stations.length} survey points · ${(sheet.lengthMm/1000).toStringAsFixed(3)} m · ${(sheet.widthMm/1000).toStringAsFixed(3)} m ROW'),
          Text('Grid: ${sheet.grid} · Survey reference: ${sheet.reference}'),
          const Text('Blue: centreline · Purple: survey stations · Green: band divisions · Grey: ROW'),
          CadPlanPreview(drawing:cad),
          Builder(builder:(button)=>Align(alignment:Alignment.centerLeft,child:FilledButton.icon(icon:const Icon(Icons.ios_share),
            onPressed:_sharing?null:()=>_share(button,cad),label:const Text('Share corridor DXF')))),
          const Text('Straight segments with mitred joins; not designed curves. No junctions, grade, drainage, road safety or land ownership verified.'),
          ExpansionTile(title:const Text('Station schedule (metres)'),children:[for(final station in sheet.stations)
            ListTile(dense:true,title:Text(station.label),subtitle:Text('E ${(station.point.easting/1000).toStringAsFixed(3)} · N ${(station.point.northing/1000).toStringAsFixed(3)}'))]),
          ExpansionTile(title:const Text('Measured bands, left to right'),children:[for(final band in sheet.bands)
            ListTile(dense:true,title:Text(band.label),subtitle:Text('${(band.widthMm/1000).toStringAsFixed(3)} m'))]),
        ],
      ])));
  }
}
