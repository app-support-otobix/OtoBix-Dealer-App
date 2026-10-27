import 'dart:async';

import 'package:flutter/material.dart';
import 'package:otobix/Models/place_model.dart';
import 'package:otobix/Network/places_api.dart';
import 'package:otobix/Utils/app_colors.dart';

/// An address field that suggests real places (Google Places, through the
/// backend) once 3 characters are typed. Picking one fills in the full address
/// and hands its position to [onPicked]. Typing freely always works too, so a
/// form never depends on the suggestions.
///
/// The suggestions sit right under the field, inside the page, and are
/// scrolled into view: a floating list would open behind the keyboard.
class AddressSearchField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  /// The registration's verified OTP: identifies the caller before login.
  final String? otpVerificationToken;
  final ValueChanged<PlaceDetailsModel> onPicked;

  /// The field was emptied, so a position picked earlier no longer applies.
  final VoidCallback? onCleared;

  const AddressSearchField({
    super.key,
    required this.controller,
    required this.onPicked,
    this.decoration = const InputDecoration(),
    this.validator,
    this.autofocus = false,
    this.otpVerificationToken,
    this.onCleared,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final _focusNode = FocusNode();
  final _listKey = GlobalKey();
  Timer? _debounce;
  int _search = 0; // the latest search; older answers are dropped
  String _session = PlacesApi.newSessionToken();
  String _lastText = '';
  String _pickedText = ''; // what a pick put in the field; not searched again
  List<PlaceSuggestionModel> _options = const [];
  bool _located = false;
  bool _fetchingPlace = false;

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AddressSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _showOptions(const []);
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text == _lastText) return; // only the cursor moved
    _lastText = text;
    _debounce?.cancel();
    if (text.trim().isEmpty && _located) {
      setState(() {
        _located = false;
        _pickedText = '';
      });
      widget.onCleared?.call();
    }
    if (text.trim().length < 3 || text == _pickedText) {
      _search++;
      _showOptions(const []);
      return;
    }
    // Wait for a pause in typing.
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _suggest(text.trim()),
    );
  }

  Future<void> _suggest(String text) async {
    final search = ++_search;
    List<PlaceSuggestionModel> found;
    try {
      found = await PlacesApi.suggest(
        text,
        sessionToken: _session,
        otpVerificationToken: widget.otpVerificationToken,
      );
    } catch (e) {
      debugPrint('Address suggestions unavailable: $e');
      found = const [];
    }
    if (!mounted || search != _search || !_focusNode.hasFocus) return;
    _showOptions(found);
  }

  void _showOptions(List<PlaceSuggestionModel> options) {
    if (!mounted || (options.isEmpty && _options.isEmpty)) return;
    setState(() => _options = options);
    if (options.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listContext = _listKey.currentContext;
      if (listContext == null) return;
      Scrollable.ensureVisible(
        listContext,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  Future<void> _pick(PlaceSuggestionModel suggestion) async {
    _pickedText = suggestion.fullText;
    widget.controller.text = suggestion.fullText; // clears the list
    setState(() => _fetchingPlace = true);
    try {
      final place = await PlacesApi.details(
        suggestion.placeId,
        sessionToken: _session,
        otpVerificationToken: widget.otpVerificationToken,
      );
      if (!mounted) return;
      // Google's full address, led by the showroom's name when it lacks it.
      final address =
          place.address.isEmpty
              ? suggestion.fullText
              : place.address.toLowerCase().contains(
                suggestion.title.toLowerCase(),
              )
              ? place.address
              : '${suggestion.title}, ${place.address}';
      _pickedText = address;
      widget.controller.text = address;
      if (place.hasPosition) {
        _located = true;
        widget.onPicked(place);
      }
    } catch (e) {
      debugPrint('Address details unavailable: $e');
    } finally {
      _session = PlacesApi.newSessionToken(); // the details call ends a session
      if (mounted) setState(() => _fetchingPlace = false);
    }
  }

  Widget? get _suffix {
    if (_fetchingPlace) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_located) {
      return const Tooltip(
        message: 'Location saved from this address',
        child: Icon(Icons.where_to_vote, color: AppColors.green, size: 20),
      );
    }
    return widget.decoration.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.words,
          decoration: widget.decoration.copyWith(suffixIcon: _suffix),
          validator: widget.validator,
        ),
        if (_options.isNotEmpty)
          // Taps here count as inside the field, so it keeps focus.
          TextFieldTapRegion(
            child: Container(
              key: _listKey,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.grey.withValues(alpha: 0.25),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (final s in _options)
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: AppColors.grey,
                      ),
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle:
                          s.subtitle.isEmpty
                              ? null
                              : Text(
                                s.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey,
                                ),
                              ),
                      onTap: () => _pick(s),
                    ),
                  // Google requires this credit for Places results shown without a map.
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Google Maps',
                        style: TextStyle(fontSize: 10, color: AppColors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
