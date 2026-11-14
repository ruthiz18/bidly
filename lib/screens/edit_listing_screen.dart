import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../state/auction_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/photo_field.dart';
import '../widgets/primary_button.dart';

/// Screen 18: edit a listing. Once bidCount > 0 the price and end-time fields
/// are locked (the Firestore rules refuse those changes too), so a seller
/// cannot move the finish line after people have committed money.
class EditListingScreen extends StatefulWidget {
  const EditListingScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late final Stream<Item?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<AuctionState>().watchItem(widget.itemId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: StreamBuilder<Item?>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorView(
                message: 'Could not load this listing. Please go back and try again.');
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final item = snap.data;
          if (item == null) {
            return const EmptyView(
                icon: Icons.search_off, message: 'This listing no longer exists.');
          }
          if (item.isClosed) {
            return const EmptyView(
                icon: Icons.lock_outline,
                message: 'This auction has ended, so it can no longer be edited.');
          }
          // The form is built once from the first snapshot; later snapshots
          // only update `item` so the lock reacts if a bid lands mid-edit.
          return _EditForm(item: item);
        },
      ),
    );
  }
}

class _EditForm extends StatefulWidget {
  const _EditForm({required this.item});

  final Item item;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item.title);
  late final _description =
      TextEditingController(text: widget.item.description);
  late String? _photoUrl = widget.item.imageUrl;
  bool _uploading = false;
  late final _startPrice =
      TextEditingController(text: widget.item.startingPrice.toString());
  late final _buyNow = TextEditingController(
      text: widget.item.buyNowPrice?.toString() ?? '');

  late DateTime _end = widget.item.endTime;
  String? _endError;
  bool _saving = false;

  /// Locked as soon as anyone has bid. Read from the live item.
  bool get _locked => widget.item.bidCount > 0;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _startPrice.dispose();
    _buyNow.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = _end.isBefore(now) ? _end : now;
    final d = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: first,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (d != null) {
      setState(() =>
          _end = DateTime(d.year, d.month, d.day, _end.hour, _end.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _end.hour, minute: _end.minute),
    );
    if (t != null) {
      setState(() => _end =
          DateTime(_end.year, _end.month, _end.day, t.hour, t.minute));
    }
  }

  String? _positiveInt(String? v, {bool required = true}) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return required ? 'Required.' : null;
    final n = int.tryParse(s);
    if (n == null || n <= 0) return 'Enter a whole number above 0.';
    return null;
  }

  Future<void> _save() async {
    final item = widget.item;
    final locked = _locked;

    String? endError;
    if (!locked && _end != item.endTime &&
        _end.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      endError = 'The auction must end at least 5 minutes from now.';
    }
    setState(() => _endError = endError);
    if (!_formKey.currentState!.validate() || endError != null) return;

    final changes = <String, dynamic>{};
    final title = _title.text.trim();
    final description = _description.text.trim();
    final photo = _photoUrl ?? '';
    if (title != item.title) changes['title'] = title;
    if (description != item.description) changes['description'] = description;
    if (photo != (item.imageUrl ?? '')) changes['imageUrl'] = photo;

    // Price and time only go to the server while nobody has bid.
    if (!locked) {
      final start = int.parse(_startPrice.text.trim());
      final buy =
          _buyNow.text.trim().isEmpty ? null : int.parse(_buyNow.text.trim());
      if (start != item.startingPrice) {
        changes['startingPrice'] = start;
        changes['highestBid'] = start; // no bids yet: highest == starting
      }
      if (buy != item.buyNowPrice) changes['buyNowPrice'] = buy;
      if (_end != item.endTime) changes['endTime'] = Timestamp.fromDate(_end);
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (changes.isEmpty) {
      navigator.pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuctionState>().updateItem(item.id, changes);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Listing updated.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'Could not save. The auction may have ended or just received a bid.')));
    }
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locked = _locked;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (locked)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 20, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This listing has ${widget.item.bidCount} bid(s). '
                          'Price and end time are locked so bidders are treated fairly.',
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              _label('Item Title'),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
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
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Describe your item.'
                    : null,
              ),
              const SizedBox(height: 12),
              _label('Photo'),
              PhotoField(
                initialUrl: widget.item.imageUrl,
                onChanged: (url) => _photoUrl = url,
                onBusyChanged: (b) => setState(() => _uploading = b),
              ),
              const SizedBox(height: 18),
              _label('Starting Bid (RWF)'),
              TextFormField(
                controller: _startPrice,
                enabled: !locked,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'RWF  ',
                  suffixIcon: locked ? const Icon(Icons.lock_outline) : null,
                ),
                validator: locked ? null : _positiveInt,
              ),
              const SizedBox(height: 18),
              _label('Buy Now Price (optional)'),
              TextFormField(
                controller: _buyNow,
                enabled: !locked,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: locked ? null : 'Leave empty for no Buy Now',
                  prefixText: 'RWF  ',
                  suffixIcon: locked ? const Icon(Icons.lock_outline) : null,
                ),
                validator: locked
                    ? null
                    : (v) {
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
                      onPressed: locked ? null : _pickDate,
                      icon: Icon(locked ? Icons.lock_outline : Icons.calendar_today,
                          size: 18),
                      label: Text(
                          '${_end.year}-${_two(_end.month)}-${_two(_end.day)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: locked ? null : _pickTime,
                      icon: Icon(locked ? Icons.lock_outline : Icons.access_time,
                          size: 18),
                      label: Text('${_two(_end.hour)}:${_two(_end.minute)}'),
                    ),
                  ),
                ],
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
                label: 'Save Changes',
                icon: Icons.check,
                loading: _saving,
                onPressed: _uploading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
