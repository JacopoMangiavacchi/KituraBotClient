# KituraBotClient
iOS 10 Swift Bot Messenger App: a mobile app channel for the KituraBot Swift Bot Framework supporting SiriKit, Notification, SFSpeechRecognizer and AVSpeechSynthesizer

This iOS App allow to interact with KituraBot based multichannel Bot from Siri or from the Mobile App messenger like UX.

The Mobile App support iOS 10 new SFSpeechRecognizer API to implemnet a voice first interface.

**Warning: This is work in progress**

This is a iOS10 Mobile App that implement a mobile app channel for KituraBot (https://github.com/JacopoMangiavacchi/KituraBot), a Swift, Kitura based, declarative multi-channel BOT framework.

Please setup first your KituraBot project and host it on your Mac or Linux server or on a Cloud platform supporting Swift such as IBM Bluemix.  

Please refere to the sample Echo Bot KituraBotFrontendEchoSample project for how to implement a simple Bot with this framework (https://github.com/JacopoMangiavacchi/KituraBotFrontendEchoSample)

This sample iOS App connect in particular with the KituraBotMobileAPI plugin (https://github.com/JacopoMangiavacchi/KituraBotMobileAPI) that must be configured in your KituraBot server project.

## App Setup

Configure the Configuration.swift file in the KituraBotFramework project in order to connect to your KituraBot server project.

    public struct Configuration {
        public static let appName = "KBot"
        static let sharedGroup = "group.jacopomangiavacchi.KituraBot"

        static let apiUrl = "https://server/mobileapi"

        // Token to use for verifing access to the Mobile API
        static let mobileApiSecurityToken = "xxx"
    }
    
The mobileApiSecurityToken value must be the same you setup in your KituraBot configuration for the KituraBotMobileAPI plugin
