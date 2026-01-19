import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'health_info_page.dart';

class HealthProfilePage extends StatefulWidget {
  const HealthProfilePage({super.key});

  @override
  State<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends State<HealthProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _yearController = TextEditingController();
  final _cycleLengthController = TextEditingController();

  bool? _hasPcos;
  String? _cycleRegularity;
  bool _isLoading = false;

  static const Color bloomPurple = Color(0xFF7B1FA2);
  static const Color bloomLavender = Color(0xFFF3E5F5);

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _yearController.dispose();
    _cycleLengthController.dispose();
    super.dispose();
  }

  // ================= SAVE PROFILE =================
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasPcos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select PCOS/PCOD status')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'healthProfile': {
          'age': int.parse(_ageController.text),
          'height': double.tryParse(_heightController.text),
          'weight': double.tryParse(_weightController.text),
          'hasPcos': _hasPcos,
          'yearOfDiagnosis':
          _hasPcos == true ? int.tryParse(_yearController.text) : null,
          'cycleRegularity': _cycleRegularity,
          'averageCycleLength':
          int.tryParse(_cycleLengthController.text),
        },

        // ❗ DO NOT complete onboarding here
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ GO TO HEALTH INFO (MANDATORY)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HealthInfoPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: bloomPurple, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bloomPurple,
        centerTitle: true,
        title: Text(
          'Health Profile',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bloomLavender, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Tell us about yourself',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: bloomPurple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _ageController,
                      decoration: _inputDecoration('Age'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                      v == null || int.tryParse(v) == null
                          ? 'Enter valid age'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _heightController,
                      decoration: _inputDecoration('Height (cm)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _weightController,
                      decoration: _inputDecoration('Weight (kg)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PCOS / PCOD Diagnosis',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    RadioListTile<bool>(
                      title: const Text('Yes'),
                      value: true,
                      groupValue: _hasPcos,
                      activeColor: bloomPurple,
                      onChanged: (v) => setState(() => _hasPcos = v),
                    ),
                    RadioListTile<bool>(
                      title: const Text('No'),
                      value: false,
                      groupValue: _hasPcos,
                      activeColor: bloomPurple,
                      onChanged: (v) => setState(() => _hasPcos = v),
                    ),

                    if (_hasPcos == true) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _yearController,
                        decoration:
                        _inputDecoration('Year of Diagnosis'),
                        keyboardType: TextInputType.number,
                      ),
                    ],

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Cycle Regularity'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Regular',
                            child: Text('Regular')),
                        DropdownMenuItem(
                            value: 'Irregular',
                            child: Text('Irregular')),
                      ],
                      onChanged: (v) =>
                          setState(() => _cycleRegularity = v),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _cycleLengthController,
                      decoration: _inputDecoration(
                          'Average Cycle Length (days)'),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bloomPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
