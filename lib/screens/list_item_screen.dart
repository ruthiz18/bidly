import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../state/auction_state.dart';
import '../state/auth_state.dart';
import '../widgets/photo_field.dart';
import 'listing_success_screen.dart';
import '../widgets/primary_button.dart';

/// Screen 14: list an item for auction.
class ListItemScreen extends StatefulWidget {
  const ListItemScreen({super.key});

  @override
  State<ListItemScreen> createState() => _ListItemScreenState();
}

class _ListItemScreenState extends State<ListItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _startPrice = TextEditingController();
  final _buyNow = TextEditingController();
  String? _photoUrl; // Cloudinary URL once the upload has finished
  bool _uploading = false;

  DateTime? _endDate;
  TimeOfDay? _endTimeOfDay;
  String? _endError;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _startPrice.dispose();
    _buyNow.dispose();
    super.dispose();
  }

  /// The seller's wall-clock choice. (The server decides lateness of bids.)
  DateTime? get _endDateTime {
    if (_endDate == null || _endTimeOfDay == null) return null;
    return DateTime(_endDate!.year, _endDate!.month, _endDate!.day,
        _endTimeOfDay!.hour, _endTimeOfDay!.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (d != null) setState(() => _endDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _endTimeOfDay ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (t != null) setState(() => _endTimeOfDay = t);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _submit() async {
    final end = _endDateTime;
    String? endError;
    if (end == null) {
      endError = 'Pick an end date and time.';
    } else if (end.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      endError = 'The auction must end at least 5 minutes from now.';
    }
    setState(() => _endError = endError);
    if (!_formKey.currentState!.validate() || endError != null) return;

    final auth = context.read<AuthState>();
    final auction = context.read<AuctionState>();
    final uid = auth.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final startingPrice = int.parse(_startPrice.text.trim());
      final title = _title.text.trim();
      final photo = _photoUrl;
      final id = await auction.createItem(Item(
        id: '',
        sellerId: uid,
        sellerName: auth.user?.name ?? 'Seller',
        title: _title.text.trim(),
        description: _description.text.trim(),
        imageUrl: _photoUrl,
        startingPrice: int.parse(_startPrice.text.trim()),
        highestBid: int.parse(_startPrice.text.trim()),
        buyNowPrice:
            _buyNow.text.trim().isEmpty ? null : int.parse(_buyNow.text.trim()),
        endTime: end!,
      ));
      if (!mounted) return;
      // Screen 15 replaces the form, so Back never returns to a filled form.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ListingSuccessScreen(
          itemId: id,
          title: title,
          startingPrice: startingPrice,
          endTime: end,
          imageUrl: photo,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not publish your item. Please try again.')));
    }
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );

  String? _positiveInt(String? v, {bool required = true}) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return required ? 'Required.' : null;
    final n = int.tryParse(s);
    if (n == null || n <= 0) return 'Enter a whole number above 0.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final end = _endDateTime;
    return Scaffold(
      appBar: AppBar(title: const Text('List Item on Bidly')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Item Details & Pricing', style: text.headlineMedium),
                const SizedBox(height: 20),
                _label('Item Title'),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(hintText: 'e.g. Vintage Camera'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Enter a title.';
                    if (s.length < 3) return 'Title is too short.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _label('Description'),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Condition, history, what is included...',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Describe your item.'
                      : null,
                ),
                const SizedBox(height: 12),
                _label('Photo'),
                PhotoField(
                  initialUrl: null,
                  onChanged: (url) => _photoUrl = url,
                  onBusyChanged: (b) => setState(() => _uploading = b),
                ),
                const SizedBox(height: 18),
                _label('Starting Bid (RWF)'),
                TextFormField(
                  controller: _startPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: '45000', prefixText: 'RWF  '),
                  validator: _positiveInt,
                ),
                const SizedBox(height: 18),
                _label('Buy Now Price (optional)'),
                TextFormField(
                  controller: _buyNow,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Leave empty for no Buy Now',
                      prefixText: 'RWF  '),
                  validator: (v) {
                    final base = _positiveInt(v, required: false);
                    if (base != null) return base;
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return null;
                    final start = int.tryParse(_startPrice.text.trim());
                    if (start != null && int.parse(s) <= start) {
                      return 'Must be higher than the starting bid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _label('Auction Ends'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_endDate == null
                            ? 'Pick date'
                            : '${_endDate!.year}-${_two(_endDate!.month)}-${_two(_endDate!.day)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(_endTimeOfDay == null
                            ? 'Pick time'
                            : '${_two(_endTimeOfDay!.hour)}:${_two(_endTimeOfDay!.minute)}'),
                      ),
                    ),
                  ],
                ),
                if (end != null && _endError == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    child: Text('Ends in ${_humanRemaining(end)}',
                        style: text.bodySmall),
                  ),
                if (_endError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    child: Text(_endError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12)),
                  ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Publish Live Auction',
                  icon: Icons.rocket_launch_outlined,
                  loading: _saving,
                  onPressed: _uploading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _humanRemaining(DateTime end) {
    final d = end.difference(DateTime.now());
    if (d.inDays >= 1) return '${d.inDays} day(s) ${d.inHours % 24} h';
    if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes % 60} min';
    return '${d.inMinutes} min';
  }
}
