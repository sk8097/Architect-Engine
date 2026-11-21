import 'package:flutter/material.dart';

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';

class RequirementFields extends StatelessWidget {
  const RequirementFields({super.key, required this.fields, required this.values,
    required this.onChanged, this.onChoiceChanged});

  final List<RequirementField> fields;
  final Map<String, Object> values;
  final void Function(String, Object?) onChanged;
  final VoidCallback? onChoiceChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final field in fields)
        if (field.applies(values)) Padding(
          key: ValueKey(field.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildField(field),
        ),
    ],
  );

  Widget _buildField(RequirementField field) {
    final label = '${field.label}${field.unit == null || field.unit!.isEmpty ? '' : ' (${field.unit})'}${field.required ? ' (required)' : ' (optional)'}';
    final value = values[field.id];
    switch (field.kind) {
      case RequirementKind.choice:
        final current = taxonomyChoice(field.options, value is String ? value : null)?.id ?? '';
        return DropdownButtonFormField<String>(
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            const DropdownMenuItem(value: '', child: Text('Not specified')),
            for (final option in field.options)
              DropdownMenuItem(value: option.id, child: Text(option.label, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (value) {
            onChanged(field.id, value == '' ? null : value);
            onChoiceChanged?.call();
          },
          validator: (value) => field.validate(value),
        );
      case RequirementKind.multi:
        final selected = value is Iterable ? value.whereType<String>().toSet() : <String>{};
        return FormField<List<String>>(
          initialValue: selected.toList(),
          validator: (value) => field.validate(value),
          builder: (fieldState) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final option in field.options)
                    FilterChip(
                      label: Text(option.label),
                      selected: fieldState.value?.contains(option.id) ?? false,
                      onSelected: (checked) {
                        final next = {...?fieldState.value};
                        if (checked) { next.add(option.id); } else { next.remove(option.id); }
                        final updated = next.toList();
                        fieldState.didChange(updated);
                        onChanged(field.id, updated);
                        onChoiceChanged?.call();
                      },
                    ),
                ],
              ),
              if (fieldState.hasError) Text(fieldState.errorText!),
            ],
          ),
        );
      default:
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(labelText: label),
          keyboardType: switch (field.kind) {
            RequirementKind.integer => TextInputType.number,
            RequirementKind.decimal => TextInputType.numberWithOptions(decimal: true, signed: (field.min ?? 0) < 0),
            _ => TextInputType.multiline,
          },
          minLines: 1,
          maxLines: field.kind == RequirementKind.text ? 3 : 1,
          validator: field.validate,
          onChanged: (value) => onChanged(field.id, value),
        );
    }
  }
}

class SpaceRequirementsDialog extends StatefulWidget {
  const SpaceRequirementsDialog({super.key, required this.title,
    required this.fields, required this.values});

  final String title;
  final List<RequirementField> fields;
  final Map<String, Object> values;

  @override
  State<SpaceRequirementsDialog> createState() => _SpaceRequirementsDialogState();
}

class _SpaceRequirementsDialogState extends State<SpaceRequirementsDialog> {
  final _form = GlobalKey<FormState>();
  late final _draft = Map<String, Object>.of(widget.values);
  String? _error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    scrollable: true,
    content: SizedBox(
      width: 560,
      child: Form(
        key: _form,
        child: RequirementFields(fields: widget.fields, values: _draft,
          onChanged: (id, value) {
            if (value == null) { _draft.remove(id); } else { _draft[id] = value; }
            if (_error != null) setState(() => _error = null);
          },
          onChoiceChanged: () => setState(() {}),
        ),
      ),
    ),
    actions: [
      if (_error != null)
        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () {
        if (!_form.currentState!.validate()) {
          setState(() => _error = 'Correct the highlighted fields.');
          return;
        }
        final error = validateSpaceDetails(_draft);
        if (error != null) {
          setState(() => _error = error);
          return;
        }
        Navigator.pop(context, requirementAnswers(widget.fields, _draft));
      }, child: const Text('Apply space details')),
    ],
  );
}
