import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/project_model.dart';
import '../providers/project_provider.dart';
import '../providers/notification_provider.dart';

class ProjectFormDialog extends StatefulWidget {
  final ProjectModel? existingProject;

  const ProjectFormDialog({super.key, this.existingProject});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late String _bhk;
  late String _floors;
  late String _facing;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _nameController = TextEditingController(text: p?.name ?? '');
    _lengthController = TextEditingController(text: p != null ? p.length.toString() : '40');
    _widthController = TextEditingController(text: p != null ? p.width.toString() : '30');
    _bhk = p?.bhk ?? '2 BHK';
    _floors = p?.floors ?? 'Ground floor';
    _facing = p?.facing ?? 'North';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final length = double.parse(_lengthController.text);
      final width = double.parse(_widthController.text);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

      if (widget.existingProject != null) {
        projectProvider.updateProject(
          id: widget.existingProject!.id,
          name: name,
          length: length,
          width: width,
          bhk: _bhk,
          floors: _floors,
          facing: _facing,
        );
        notifProvider.addNotification('success', 'Project Updated', '$name has been updated.');
      } else {
        projectProvider.addProject(
          name: name,
          length: length,
          width: width,
          bhk: _bhk,
          floors: _floors,
          facing: _facing,
        );
        notifProvider.addNotification('success', 'New Project Created', '$name ($bhk, ${length * width} sqft) was created.');
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingProject != null ? 'Project updated!' : 'Project created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProject != null;

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text(
                      isEditing ? 'Edit Project' : 'Create New Project',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Project Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    hintText: 'e.g. Sharma Villa, My 2BHK Home',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a project name' : null,
                ),
                const SizedBox(height: 14),

                // Plot Dimensions
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Plot Length (ft) *',
                          hintText: '40',
                        ),
                        validator: (v) {
                          final num = double.tryParse(v ?? '');
                          if (num == null || num <= 0) return 'Valid length';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Plot Width (ft) *',
                          hintText: '30',
                        ),
                        validator: (v) {
                          final num = double.tryParse(v ?? '');
                          if (num == null || num <= 0) return 'Valid width';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // BHK and Floors
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _bhk,
                        decoration: const InputDecoration(labelText: 'BHK Type'),
                        items: const [
                          DropdownMenuItem(value: '1 BHK', child: Text('1 BHK')),
                          DropdownMenuItem(value: '2 BHK', child: Text('2 BHK')),
                          DropdownMenuItem(value: '3 BHK', child: Text('3 BHK')),
                          DropdownMenuItem(value: '4 BHK', child: Text('4 BHK')),
                          DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                        ],
                        onChanged: (v) => setState(() => _bhk = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _floors,
                        decoration: const InputDecoration(labelText: 'Floors'),
                        items: const [
                          DropdownMenuItem(value: 'Ground floor', child: Text('Ground floor')),
                          DropdownMenuItem(value: 'G+1', child: Text('G+1')),
                          DropdownMenuItem(value: 'G+2', child: Text('G+2')),
                          DropdownMenuItem(value: 'G+3', child: Text('G+3')),
                          DropdownMenuItem(value: 'G+4 or more', child: Text('G+4 or more')),
                        ],
                        onChanged: (v) => setState(() => _floors = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Facing Direction
                DropdownButtonFormField<String>(
                  value: _facing,
                  decoration: const InputDecoration(labelText: 'Plot Facing (Vastu)'),
                  items: const [
                    DropdownMenuItem(value: 'North', child: Text('North')),
                    DropdownMenuItem(value: 'East', child: Text('East')),
                    DropdownMenuItem(value: 'South', child: Text('South')),
                    DropdownMenuItem(value: 'West', child: Text('West')),
                    DropdownMenuItem(value: 'North-East', child: Text('North-East')),
                    DropdownMenuItem(value: 'North-West', child: Text('North-West')),
                    DropdownMenuItem(value: 'South-East', child: Text('South-East')),
                    DropdownMenuItem(value: 'South-West', child: Text('South-West')),
                    DropdownMenuItem(value: 'Not decided', child: Text('Not decided')),
                  ],
                  onChanged: (v) => setState(() => _facing = v!),
                ),
                const SizedBox(height: 24),

                // Actions
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimary,
                    foregroundColor: const Color(0xFF0A1128),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: Text(
                    isEditing ? 'UPDATE PROJECT' : 'SAVE PROJECT',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
