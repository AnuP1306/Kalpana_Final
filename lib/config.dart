const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY',
    defaultValue: 'PASTE_YOUR_GEMINI_API_KEY_HERE');

/// Change this if Google retires the model name.
const String kGeminiModel = 'gemini-2.5-flash';

/// Gemini is OFF by default: every command and photo is handled on the phone,
/// so the app never hits a quota or waits on the network. Set true only if you
/// want richer cloud descriptions (it still falls back to offline if it fails).
const bool kUseCloudAi = false;

/// Lets "okay, got it" / "okay stop" interrupt Kalpana while she is talking, by listening during speech.
/// Set to false if your phone's speech recogniser disturbs the voice output. Tapping the top bar always stops speech.
const bool kBargeIn = true;
