import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_users_to_photo_page.dart';
import 'package:can_guix/services/api_service.dart';
import 'package:can_guix/services/user_provider.dart';

class DoAdvertisePage extends StatefulWidget {
  @override
  _DoAdvertisePageState createState() => _DoAdvertisePageState();
}

class _DoAdvertisePageState extends State<DoAdvertisePage> {
  DateTime selectedDate = DateTime.now();
  String selectedMeal = 'sopar';
  List<String> participants = [];
  TimeOfDay? selectedTime;
  bool noTimeSelected = false;
  int? _currentUserId;
  String message = "";
  final TextEditingController _messageController = TextEditingController();

  // Paleta de colors (dark theme)
  static const Color _primaryBlue = Color(0xFF60A5FA);
  static const Color _lightBlue = Color(0xFF1E3A5F);
  static const Color _cardShadow = Color(0x40000000);
  static const Color _bgColor = Color(0xFF0F172A);
  static const Color _cardColor = Color(0xFF1E293B);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _borderColor = Color(0xFF334155);

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadCurrentUserId() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _currentUserId = userProvider.id;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('ca', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _primaryBlue),
        ),
        child: child!,
      ),
      helpText: 'Tria hora',
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        noTimeSelected = false;
      });
    }
  }

  Future<void> _selectParticipants() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUsersToPhotoPage(
          title: "QUI VE SEGUR?",
          selectedParticipants: participants,
        ),
      ),
    );
    if (result != null && result is List<String>) {
      setState(() => participants = result);
    }
  }

  void _uploadNewAdvertise() async {
    if (_currentUserId == null) {
      _showSnack('No s\'ha pogut obtenir l\'ID de l\'usuari creador.', isError: true);
      return;
    }

    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    String? formattedTime;
    if (selectedTime != null && !noTimeSelected) {
      formattedTime =
          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';
    }

    try {
      final response = await ApiService.crearNouAvis(
        idUsuariCreador: _currentUserId!,
        dataAvis: formattedDate,
        horaAvis: formattedTime,
        tipusApat: selectedMeal,
        usuarisParticipants: participants,
        missatge: message,
      );

      if (response.statusCode == 201) {
        _showSnack('Avís creat correctament! ✓', isError: false);
        Navigator.pop(context);
      } else {
        final errorBody = json.decode(response.body);
        _showSnack('Error: ${errorBody['message'] ?? 'Error desconegut'}', isError: true);
      }
    } catch (e) {
      _showSnack('No s\'ha pogut connectar amb el servidor.', isError: true);
    }
  }

  void _showSnack(String text, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Helpers de text ──────────────────────────────────────────────────────
  String get _horaText {
    if (noTimeSelected) return "Encara no ho tinc clar";
    if (selectedTime != null) {
      return '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
    }
    return "No seleccionada";
  }

  String get _diaText =>
      DateFormat('EEEE, d MMMM yyyy', 'ca').format(selectedDate);

  // ── Widget helpers ────────────────────────────────────────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: _cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryBlue.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _primaryBlue,
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBlue,
        side: const BorderSide(color: _primaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onPressed,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: _textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Nou avís d\'àpat',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── DIA ──────────────────────────────────────────────────────
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Dia', Icons.calendar_today_rounded),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _infoChip(_diaText)),
                      const SizedBox(width: 12),
                      _outlineButton(
                        label: 'Canvia',
                        icon: Icons.edit_calendar_rounded,
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── HORA ─────────────────────────────────────────────────────
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Hora', Icons.access_time_rounded),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _infoChip(_horaText)),
                      const SizedBox(width: 12),
                      _outlineButton(
                        label: 'Tria',
                        icon: Icons.schedule_rounded,
                        onPressed: () => _selectTime(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      selectedTime = null;
                      noTimeSelected = true;
                    }),
                    child: Row(
                      children: [
                        Icon(
                          noTimeSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: noTimeSelected
                              ? _primaryBlue
                              : _textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Encara no ho tinc clar',
                          style: TextStyle(
                            color: noTimeSelected
                                ? _primaryBlue
                                : _textSecondary,
                            fontWeight: noTimeSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── ÀPAT ─────────────────────────────────────────────────────
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Àpat', Icons.restaurant_rounded),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MealOption(
                        label: 'Esmorzar',
                        emoji: '☕',
                        value: 'esmorzar',
                        selected: selectedMeal,
                        onTap: (v) => setState(() => selectedMeal = v),
                      ),
                      const SizedBox(width: 10),
                      _MealOption(
                        label: 'Dinar',
                        emoji: '🍽️',
                        value: 'dinar',
                        selected: selectedMeal,
                        onTap: (v) => setState(() => selectedMeal = v),
                      ),
                      const SizedBox(width: 10),
                      _MealOption(
                        label: 'Sopar',
                        emoji: '🌙',
                        value: 'sopar',
                        selected: selectedMeal,
                        onTap: (v) => setState(() => selectedMeal = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── PARTICIPANTS ──────────────────────────────────────────────
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Qui ve segur?', Icons.group_rounded),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Afegir participants'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _selectParticipants,
                    ),
                  ),
                  if (participants.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: participants
                          .map(
                            (p) => Chip(
                              avatar: CircleAvatar(
                                backgroundColor: _primaryBlue,
                                child: Text(
                                  p[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              label: Text(p, style: const TextStyle(color: _textPrimary)),
                              backgroundColor: _lightBlue,
                              side: BorderSide(
                                  color: _primaryBlue.withOpacity(0.4)),
                              deleteIcon: Icon(Icons.close, size: 16, color: _textSecondary),
                              onDeleted: () => setState(
                                  () => participants.remove(p)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // ── MISSATGE ──────────────────────────────────────────────────
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Vols dir alguna cosa?', Icons.chat_bubble_outline_rounded),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLength: 50,
                    style: const TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Escriu un missatge opcional...',
                      hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                      counterText: '${message.length}/50',
                      counterStyle: TextStyle(color: _textSecondary, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _primaryBlue, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                    ),
                    onChanged: (v) => setState(() => message = v),
                  ),
                ],
              ),
            ),

            // ── BOTÓ CONFIRMAR ────────────────────────────────────────────
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: _uploadNewAdvertise,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Confirmar avís'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar per a cada opció d'àpat ───────────────────────────────
class _MealOption extends StatelessWidget {
  final String label;
  final String emoji;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _MealOption({
    required this.label,
    required this.emoji,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF334155),
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}