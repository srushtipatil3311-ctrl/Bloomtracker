import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart'; // ✅ bottom navigation root

class HealthInfoPage extends StatefulWidget {
  const HealthInfoPage({super.key});

  @override
  State<HealthInfoPage> createState() => _HealthInfoPageState();
}

class _HealthInfoPageState extends State<HealthInfoPage> {
  static const Color bloomPurple = Color(0xFF7B1FA2);
  static const Color bloomLavender = Color(0xFFF3E5F5);

  // ================= SYMPTOMS =================
  bool _acne = false;
  bool _hairFall = false;
  bool _cramps = false;

  // ================= LIFESTYLE =================
  String _lifestyle = 'Sedentary';
  String _dietPreference = 'Veg';

  // ================= WELLNESS =================
  int _workoutFrequency = 0;
  double _sleepHours = 7.0;
  int _stressLevel = 3;
  int _painLevel = 2;
  int _energyLevel = 3;
  int _waterIntake = 2;
  String _mood = 'Normal';

  final TextEditingController _medicationController =
  TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _medicationController.dispose();
    super.dispose();
  }

  // ================= SAVE + COMPLETE ONBOARDING =================
  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'healthInfo': {
          'acne': _acne,
          'hairFall': _hairFall,
          'cramps': _cramps,
          'lifestyle': _lifestyle,
          'dietPreference': _dietPreference,
          'workoutFrequency': _workoutFrequency,
          'sleepHours': _sleepHours,
          'stressLevel': _stressLevel,
          'painLevel': _painLevel,
          'energyLevel': _energyLevel,
          'waterIntake': _waterIntake,
          'mood': _mood,
          'medication': _medicationController.text.trim(),
        },

        // 🔑 ONLY PLACE onboarding is completed
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // ✅ GO TO HOME (BOTTOM NAV ROOT)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving health info')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= UI HELPERS =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: bloomPurple,
        ),
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
          'Health Information',
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
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Symptoms'),
                  _checkbox('Acne', _acne, (v) => setState(() => _acne = v)),
                  _checkbox('Hair Fall', _hairFall,
                          (v) => setState(() => _hairFall = v)),
                  _checkbox('Cramps', _cramps,
                          (v) => setState(() => _cramps = v)),

                  _sectionTitle('Lifestyle'),
                  _radio('Sedentary', _lifestyle,
                          (v) => setState(() => _lifestyle = v)),
                  _radio('Active', _lifestyle,
                          (v) => setState(() => _lifestyle = v)),

                  _sectionTitle('Diet Preference'),
                  _radio('Veg', _dietPreference,
                          (v) => setState(() => _dietPreference = v)),
                  _radio('Non-Veg', _dietPreference,
                          (v) => setState(() => _dietPreference = v)),

                  _sectionTitle('Wellness'),
                  _slider('Sleep (hours)', _sleepHours, 0, 12,
                          (v) => setState(() => _sleepHours = v)),
                  _slider('Stress Level', _stressLevel.toDouble(), 1, 5,
                          (v) => setState(() => _stressLevel = v.round())),
                  _slider('Pain Level', _painLevel.toDouble(), 0, 5,
                          (v) => setState(() => _painLevel = v.round())),
                  _slider('Energy Level', _energyLevel.toDouble(), 1, 5,
                          (v) => setState(() => _energyLevel = v.round())),
                  _slider('Water Intake (glasses)',
                      _waterIntake.toDouble(), 0, 10,
                          (v) => setState(() => _waterIntake = v.round())),

                  _sectionTitle('Mood'),
                  DropdownButtonFormField<String>(
                    value: _mood,
                    items: const [
                      DropdownMenuItem(value: 'Happy', child: Text('Happy')),
                      DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                    ],
                    onChanged: (v) => setState(() => _mood = v!),
                  ),

                  _sectionTitle('Medication'),
                  TextField(
                    controller: _medicationController,
                    decoration: const InputDecoration(
                      hintText: 'List medications (if any)',
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bloomPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
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
    );
  }

  // ================= SMALL HELPERS =================
  Widget _checkbox(String text, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(text),
      value: value,
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _radio(String text, String group, Function(String) onChanged) {
    return RadioListTile<String>(
      title: Text(text),
      value: text,
      groupValue: group,
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _slider(
      String label,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: max.toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
