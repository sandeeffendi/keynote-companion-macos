//
//  AppIcon.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

enum AppIcon {
    static let permissionMissing = "hand.raised"
    static let noKeynoteFileOpen = "document.viewfinder"
    static let noKeynoteSlideshowActive = "cursorarrow"
    static let keynoteSlideshowActive = "flag.pattern.checkered.2.crossed"

    static let headerAction = "questionmark"
    static let openKeynote = "doc"
    static let settings = "gearshape"
    static let activities = "clock.arrow.circlepath"
    static let record = "record.circle"

    static let permissionMicrophone = "microphone"
    static let permissionKeynoteAutomation = "rectangle.on.rectangle"
    static let permissionWPMDetector = "waveform.badge.microphone"

    // Permissions sheet rows (Keynote → Microphone → Speech).
    static let permissionSheetKeynote = "rectangle.on.rectangle"
    static let permissionSheetMicrophone = "mic"
    static let permissionSheetSpeech = "waveform"
    static let permissionInfo = "info.circle"

    static let onboardingSpeechRate = "microphone.and.signal.meter"
    static let onboardingFillerWords = "person.wave.2"
    static let onboardingInsights = "text.document"
}
