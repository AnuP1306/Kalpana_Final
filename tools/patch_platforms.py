"""Adds the Android/iOS permissions + queries Kalpana needs. Safe to re-run."""

import pathlib, re

m = pathlib.Path("android/app/src/main/AndroidManifest.xml")
if m.exists():
    s = m.read_text()
    if "RECORD_AUDIO" not in s:
        perms = "".join(
            f'    <uses-permission android:name="android.permission.{p}"/>\n'
            for p in [
                "INTERNET",
                "RECORD_AUDIO",
                "CAMERA",
                "ACCESS_FINE_LOCATION",
                "ACCESS_COARSE_LOCATION",
                "VIBRATE",
                "READ_CONTACTS",
            ]
        )
        queries = """    <queries>
        <intent><action android:name="android.speech.RecognitionService"/></intent>
        <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="sms"/></intent>
    </queries>
"""
        s = re.sub(
            r"(<manifest[^>]*>\n)", lambda mo: mo.group(1) + perms + queries, s, count=1
        )
        m.write_text(s)
        print("patched AndroidManifest.xml")

p = pathlib.Path("ios/Runner/Info.plist")
if p.exists():
    s = p.read_text()
    if "NSMicrophoneUsageDescription" not in s:
        keys = {
            "NSMicrophoneUsageDescription": "Kalpana listens to your voice commands.",
            "NSSpeechRecognitionUsageDescription": "Kalpana turns your speech into commands.",
            "NSContactsUsageDescription": "Kalpana finds your emergency contact by name.",
            "NSCameraUsageDescription": "Kalpana reads labels and describes what is in front of you.",
            "NSLocationWhenInUseUsageDescription": "Kalpana tells you where you are and shares your location in an emergency.",
        }
        add = "".join(
            f"\t<key>{k}</key>\n\t<string>{v}</string>\n" for k, v in keys.items()
        )
        add += "\t<key>LSApplicationQueriesSchemes</key>\n\t<array>\n\t\t<string>tel</string>\n\t\t<string>sms</string>\n\t</array>\n"
        i = s.rfind("</dict>")
        p.write_text(s[:i] + add + s[i:])
        print("patched Info.plist")

pod = pathlib.Path("ios/Podfile")
if pod.exists():
    s = pod.read_text()
    if "PERMISSION_MICROPHONE" not in s:
        hook = """    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)',
        'PERMISSION_MICROPHONE=1', 'PERMISSION_SPEECH_RECOGNIZER=1', 'PERMISSION_CAMERA=1', 'PERMISSION_LOCATION=1', 'PERMISSION_CONTACTS=1']
    end
"""
        s = s.replace(
            "flutter_additional_ios_build_settings(target)\n",
            "flutter_additional_ios_build_settings(target)\n" + hook,
            1,
        )
        pod.write_text(s)
        print("patched Podfile")
