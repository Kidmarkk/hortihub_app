import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/farmer_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/farmer_provider.dart';

class AddEditFarmerScreen extends ConsumerStatefulWidget {
  final String hubCode;
  final Farmer? farmer;
  const AddEditFarmerScreen({super.key, required this.hubCode, this.farmer});

  @override
  ConsumerState<AddEditFarmerScreen> createState() =>
      _AddEditFarmerScreenState();
}

class _AddEditFarmerScreenState extends ConsumerState<AddEditFarmerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.farmer != null) {
      _nameCtrl.text = widget.farmer!.farmerName ?? '';
      _villageCtrl.text = widget.farmer!.villageName ?? '';
      _mobileCtrl.text = widget.farmer!.mobileno ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _villageCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isEditing = widget.farmer != null;
    final hubCode = int.tryParse(widget.hubCode) ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Farmer' : 'Add Farmer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Farmer Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _villageCtrl,
              decoration: const InputDecoration(labelText: 'Village'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final notifier = ref.read(addFarmerNotifierProvider.notifier);
                if (!_formKey.currentState!.validate()) return;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                  return;
                }

                final payload = <String, String>{
                  'farmerName': _nameCtrl.text.trim(),
                  'villageName': _villageCtrl.text.trim(),
                  'mobileno': _mobileCtrl.text.trim(),
                  'userCode': user.userCode.toString(),
                };

                if (isEditing) {
                  final payload = <String, String>{
                    'collectionCode': widget.farmer!.collectionCode!,
                    'farmerName': _nameCtrl.text.trim(),
                    'villageName': _villageCtrl.text.trim(),
                    'mobileno': _mobileCtrl.text.trim(),
                    'userCode': user.userCode.toString(),
                  };
                  await notifier.updateFarmer(payload);
                } else {
                  final payload = <String, String>{
                    'farmerName': _nameCtrl.text.trim(),
                    'villageName': _villageCtrl.text.trim(),
                    'mobileno': _mobileCtrl.text.trim(),
                    'userCode': user.userCode.toString(),
                  };
                  await notifier.addFarmer(payload, hubCode.toString());
                }

                ref.refresh(farmerListProvider(widget.hubCode));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Farmer saved successfully')),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
