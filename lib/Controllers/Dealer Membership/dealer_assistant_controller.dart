import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_assistant_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// The Dealer Home voice assistant. The phone does speech-to-text and reads
/// answers aloud; the backend (dealer-membership/assistant/chat) understands
/// the question with Sarvam AI and searches the database.
class DealerAssistantController extends GetxController {
  static const _languageKey = 'assistantLanguageKey';
  static const _autoReadKey = 'assistantAutoReadKey';
  static const _maxHistory = 10; // messages sent with each question

  // When listening stops by itself. Before the dealer says anything it waits
  // long enough for them to start; once words arrive, a short silence ends it
  // (3 s felt slow on a handset, 23 Nov 2026). The recogniser then has
  // _finalTimeout to send its final words, else its last partial ones are used.
  static const _waitToStart = Duration(seconds: 5);
  static const _silenceAfterSpeech = Duration(milliseconds: 1500);
  static const _finalTimeout = Duration(milliseconds: 800);

  final messages = <AssistantMessage>[].obs;
  final language = AssistantLanguage.english.obs;
  final isListening = false.obs;
  final isSending = false.obs;
  final heardText = ''.obs; // what the phone has heard so far
  final soundLevel = 0.0.obs;
  final speakingIndex = (-1).obs;
  final autoRead = false.obs; // read every answer aloud as it arrives
  final hint = ''.obs; // a short note under the mic ("didn't catch that")
  final scrollController = ScrollController();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;
  bool _sentThisListen = false;
  bool _heardSpeech =
      false; // words arrived in this listen: silence wait shortened

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _tts.setSpeechRate(0.5); // normal speed on both Android and iOS
    _tts.setCompletionHandler(() => speakingIndex.value = -1);
    _tts.setCancelHandler(() => speakingIndex.value = -1);
    _tts.setErrorHandler((_) => speakingIndex.value = -1);
  }

  @override
  void onClose() {
    _speech.cancel();
    _tts.stop();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _loadSettings() async {
    final saved = await SharedPrefsHelper.getString(_languageKey);
    if (saved != null && saved.isNotEmpty) {
      language.value = AssistantLanguage.of(saved);
    }
    autoRead.value = await SharedPrefsHelper.getBool(_autoReadKey);
  }

  void setLanguage(AssistantLanguage l) {
    language.value = l;
    hint.value = '';
    SharedPrefsHelper.saveString(_languageKey, l.code);
  }

  void toggleAutoRead() {
    autoRead.value = !autoRead.value;
    SharedPrefsHelper.saveBool(_autoReadKey, autoRead.value);
    if (!autoRead.value) stopSpeaking();
  }

  /// Words for the screen in the chosen language.
  String t(String key) =>
      _strings[key]?[language.value.code] ?? _strings[key]?['en'] ?? key;

  // ---------------------------------------------------------------------------
  // Listening (on the phone)
  // ---------------------------------------------------------------------------

  Future<void> toggleListening() =>
      isListening.value ? stopListening() : startListening();

  Future<void> startListening() async {
    if (isSending.value || isListening.value) return;
    await stopSpeaking();
    hint.value = '';
    if (!_speechReady) {
      // Asks for the microphone (and, on iOS, speech recognition) the first time.
      _speechReady = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        finalTimeout: _finalTimeout,
      );
      if (!_speechReady) {
        hint.value = t('micUnavailable');
        return;
      }
    }
    heardText.value = '';
    _sentThisListen = false;
    _heardSpeech = false;
    isListening.value = true;
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: (level) => soundLevel.value = level,
        listenOptions: SpeechListenOptions(
          localeId: language.value.speechLocale,
          listenFor: const Duration(seconds: 30),
          pauseFor: _waitToStart,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.search,
        ),
      );
    } catch (_) {
      isListening.value = false;
      hint.value = t('micUnavailable');
    }
  }

  /// Stops listening. The recogniser then delivers its final result (or, after
  /// a short timeout, its last partial one) and "done", and that is sent.
  Future<void> stopListening() async {
    if (!isListening.value) return;
    isListening.value = false;
    soundLevel.value = 0;
    await _speech.stop();
  }

  void _onResult(SpeechRecognitionResult result) {
    heardText.value = result.recognizedWords;
    if (result.finalResult) return _finishListening();
    // First words heard: from now on a short silence means "finished".
    if (!_heardSpeech && result.recognizedWords.trim().isNotEmpty) {
      _heardSpeech = true;
      try {
        _speech.changePauseFor(_silenceAfterSpeech);
      } catch (_) {
        // Listening already ended; nothing to shorten.
      }
    }
  }

  void _onStatus(String status) {
    if (status == SpeechToText.notListeningStatus) {
      // The mic is off, but the final (corrected) words may still be coming:
      // wait for them or for "done" before sending.
      isListening.value = false;
      soundLevel.value = 0;
    } else if (status == SpeechToText.doneStatus) {
      _finishListening();
    }
  }

  void _onError(SpeechRecognitionError error) {
    isListening.value = false;
    soundLevel.value = 0;
    if (heardText.value.trim().isNotEmpty) return _finishListening();
    hint.value = t(
      error.errorMsg.contains('permission') ? 'micUnavailable' : 'didNotCatch',
    );
  }

  void _finishListening() {
    isListening.value = false;
    soundLevel.value = 0;
    if (_sentThisListen) return;
    final text = heardText.value.trim();
    if (text.isEmpty) return;
    _sentThisListen = true;
    heardText.value = '';
    send(text);
  }

  // ---------------------------------------------------------------------------
  // Asking the backend
  // ---------------------------------------------------------------------------

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || isSending.value) return;
    await stopSpeaking();
    hint.value = '';
    final lang = language.value;
    messages.add(
      AssistantMessage(fromDealer: true, text: text, language: lang),
    );
    _scrollToEnd();
    isSending.value = true;
    try {
      final conversation = messages.where((m) => !m.isError).toList();
      final recent =
          conversation.length > _maxHistory
              ? conversation.sublist(conversation.length - _maxHistory)
              : conversation;
      final data = await DealerMembershipApi.post(AppUrls.dealerAssistantChat, {
        'language': lang.code,
        'messages': recent.map((m) => m.toHistory()).toList(),
      });
      messages.add(
        AssistantMessage.answer(Map<String, dynamic>.from(data as Map)),
      );
      if (autoRead.value) speak(messages.length - 1);
    } on DealerApiException catch (e) {
      messages.add(
        AssistantMessage(
          fromDealer: false,
          text: e.message,
          language: lang,
          isError: true,
        ),
      );
    } finally {
      isSending.value = false;
      _scrollToEnd();
    }
  }

  void clearConversation() {
    stopSpeaking();
    messages.clear();
    hint.value = '';
  }

  // ---------------------------------------------------------------------------
  // Reading aloud (on the phone)
  // ---------------------------------------------------------------------------

  Future<void> toggleSpeaking(int index) =>
      speakingIndex.value == index ? stopSpeaking() : speak(index);

  Future<void> speak(int index) async {
    if (index < 0 || index >= messages.length) return;
    final message = messages[index];
    await _tts.stop();
    final locale = message.language.ttsLocale;
    final available = await _tts.isLanguageAvailable(locale);
    if (available != true) hint.value = t('voiceMissing');
    await _tts.setLanguage(locale);
    speakingIndex.value = index;
    await _tts.speak(message.text);
  }

  Future<void> stopSpeaking() async {
    if (speakingIndex.value == -1) return;
    speakingIndex.value = -1;
    await _tts.stop();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  static const Map<String, Map<String, String>> _strings = {
    'title': {
      'en': 'OtoBix Assistant',
      'hi': 'OtoBix असिस्टेंट',
      'bn': 'OtoBix অ্যাসিস্ট্যান্ট',
    },
    'tapToSpeak': {
      'en': 'Tap the mic and ask for a car',
      'hi': 'माइक दबाइए और गाड़ी के बारे में पूछिए',
      'bn': 'মাইক টিপুন আর গাড়ির কথা জিজ্ঞেস করুন',
    },
    'listening': {'en': 'Listening…', 'hi': 'सुन रहा हूँ…', 'bn': 'শুনছি…'},
    'searching': {'en': 'Searching…', 'hi': 'खोज रहा हूँ…', 'bn': 'খুঁজছি…'},
    'typeHere': {
      'en': 'Or type your question',
      'hi': 'या अपना सवाल लिखें',
      'bn': 'অথবা আপনার প্রশ্ন লিখুন',
    },
    'tryAsking': {
      'en': 'Try asking',
      'hi': 'ऐसे पूछिए',
      'bn': 'এভাবে জিজ্ঞেস করুন',
    },
    'didNotCatch': {
      'en': "Didn't catch that. Tap the mic and try again.",
      'hi': 'समझ नहीं आया। माइक दबाकर फिर से बोलिए।',
      'bn': 'বুঝতে পারিনি। মাইক টিপে আবার বলুন।',
    },
    'micUnavailable': {
      'en':
          "Voice input isn't available. Allow microphone access for OtoBix in your phone's Settings, or type instead.",
      'hi':
          'आवाज़ से पूछना अभी उपलब्ध नहीं है। फ़ोन की सेटिंग्स में OtoBix को माइक्रोफ़ोन की अनुमति दें, या लिखकर पूछें।',
      'bn':
          'ভয়েস ইনপুট এখন পাওয়া যাচ্ছে না। ফোনের সেটিংসে OtoBix-কে মাইক্রোফোনের অনুমতি দিন, অথবা লিখে জিজ্ঞেস করুন।',
    },
    'voiceMissing': {
      'en':
          "This phone may not have a voice for this language. Install it in Settings → Text-to-speech.",
      'hi':
          'इस फ़ोन में इस भाषा की आवाज़ शायद नहीं है। सेटिंग्स → टेक्स्ट-टू-स्पीच में इसे इंस्टॉल करें।',
      'bn':
          'এই ফোনে এই ভাষার ভয়েস হয়তো নেই। সেটিংস → টেক্সট-টু-স্পিচ থেকে ইনস্টল করুন।',
    },
    'readAloud': {'en': 'Read aloud', 'hi': 'पढ़कर सुनाएँ', 'bn': 'পড়ে শোনান'},
    'stop': {'en': 'Stop', 'hi': 'रोकें', 'bn': 'থামান'},
    'autoReadOn': {
      'en': 'Answers will be read aloud',
      'hi': 'जवाब पढ़कर सुनाए जाएँगे',
      'bn': 'উত্তর পড়ে শোনানো হবে',
    },
    'autoReadOff': {
      'en': 'Answers will not be read aloud',
      'hi': 'जवाब पढ़कर नहीं सुनाए जाएँगे',
      'bn': 'উত্তর পড়ে শোনানো হবে না',
    },
    'newChat': {'en': 'New chat', 'hi': 'नई बातचीत', 'bn': 'নতুন চ্যাট'},
  };

  /// Example questions for an empty chat, in the chosen language.
  List<String> get examples => switch (language.value.code) {
    'hi' => const [
      '8 लाख से कम हुंडई क्रेटा',
      'कोलकाता में मारुति स्विफ्ट डीज़ल',
      'मेरे कितने पॉइंट्स बचे हैं?',
    ],
    'bn' => const [
      '৮ লাখের মধ্যে হুন্ডাই ক্রেটা',
      'কলকাতায় মারুতি সুইফট ডিজেল',
      'আমার কত পয়েন্ট বাকি আছে?',
    ],
    _ => const [
      'Hyundai Creta under 8 lakh',
      'Maruti Swift diesel in Kolkata',
      'How many points do I have left?',
    ],
  };
}
