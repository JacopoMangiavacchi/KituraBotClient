//
//  ChatViewController.swift
//  KituraBot
//
//  Created by Jacopo Mangiavacchi on 10/3/16.
//
//

import UIKit
import JSQMessagesViewController
import Speech
import AVFoundation
import UserNotifications
import UserNotificationsUI //framework to customize the notification
import Intents

import KituraBotFramework

class ChatViewController: JSQMessagesViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var audioSwitch: UISwitch!
    
    
    // MARK: Properties
    var messages = [JSQMessage]() // messages is an array to store the various instances of JSQMessage
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    // Typing tracking related properties
    private var localTyping = false // Store whether the local user is typing in a private property
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // Using a computed property, update userIsTypingRef each time user updates this property.
            localTyping = newValue
        }
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = "jacopo"
        senderDisplayName = "Jacopo"
        
        INPreferences.requestSiriAuthorization { (status) in
            // process status
        }
        
        title = "KituraBot"
        setupBubbles()
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        UNUserNotificationCenter.current().delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.refresh), name:  NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    func refresh() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if let lastNotificationResponse = KituraBotShared.getLastNotificationResponse() {
            addResponseMessage(responseText: lastNotificationResponse)
            
            KituraBotShared.storeLastNotificationResponse(nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupBubbles() {
        // JSQMessagesBubbleImageFactory has methods that create the images for the chat bubbles. There’s even a category provided by JSQMessagesViewController that creates the message bubble colors used in the native Messages app.
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        incomingBubbleImageView = factory?.incomingMessagesBubbleImage(with: UIColor(red: 64.0/256.0, green: 192.0/256.0, blue: 0.0, alpha: 1.0))
        
        //self.inputToolbar.contentView.leftBarButtonItem.imageView?.image = UIImage(named: "mic")
        
        let accessoryImage = UIImage(named: "mic")
        
        let normalImage = accessoryImage?.jsq_imageMasked(with: UIColor.darkGray)
        let highlightedImage = accessoryImage?.jsq_imageMasked(with: UIColor.lightGray);
        let redImage = accessoryImage?.jsq_imageMasked(with: UIColor.red);
        
        let accessoryButton = UIButton()
        accessoryButton.frame = CGRect(x: 0.0, y: 0.0, width: accessoryImage!.size.width, height: 32.0)
        accessoryButton.setImage(normalImage, for: UIControlState.normal)
        accessoryButton.setImage(highlightedImage, for: UIControlState.highlighted)
        accessoryButton.setImage(redImage, for: UIControlState.selected)
        accessoryButton.contentMode = .scaleAspectFit
        accessoryButton.backgroundColor = UIColor.clear
        accessoryButton.tintColor = UIColor.lightGray
        
        accessoryButton.isSelected = false
        inputToolbar.contentView.leftBarButtonItem = accessoryButton
        inputToolbar.contentView.leftBarButtonItem.isEnabled = true
        
        self.automaticallyScrollsToMostRecentMessage = true
    }
    
    override  func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.inputToolbar.contentView.leftBarButtonItem.isEnabled = true
                    
                case .denied:
                    self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
                    print("User denied access to speech recognition")
                    
                case .restricted:
                    self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
                    print("Speech recognition restricted on this device")
                    
                case .notDetermined:
                    self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
                    print("Speech recognition not yet authorized")
                }
            }
        }
        
        refresh()
    }
    
    
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        inputToolbar.contentView.textView.text = ""

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        //try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                print(result.bestTranscription.formattedString)
                self.inputToolbar.contentView.textView.text = result.bestTranscription.formattedString
                self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                try! audioSession.setActive(false)
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.inputToolbar.contentView.leftBarButtonItem.isEnabled = true
                self.inputToolbar.contentView.textView.text = ""
                self.inputToolbar.contentView.textView.placeHolder = "New Message"
                self.inputToolbar.contentView.leftBarButtonItem.isSelected = false

                
                self.recognitionTask?.cancel()
                self.recognitionTask = nil

                print("Remove tat")
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        inputToolbar.contentView.textView.text = ""
        inputToolbar.contentView.textView.placeHolder = "(Go ahead, I'm listening)"
        inputToolbar.contentView.leftBarButtonItem.isSelected = true
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    @IBAction func startNewConversation(_ sender: AnyObject) {
        KituraBotShared.storeContext(nil)

        messages.removeAll()
        
        finishReceivingMessage()
    }
    
    
    // MARK: SFSpeechRecognizerDelegate
    
    internal func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.inputToolbar.contentView.leftBarButtonItem.isEnabled = true
            print("Recognition availabe")
        } else {
            self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
            print("Recognition not available")
        }
    }
    
    

    // MARK: JSQMessagesCollectionView Datasource
    override func collectionView(_ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // retrieve the message based on the NSIndexPath item.
        if message.senderId == senderId { // Check if the message was sent by the local user. If so, return the outgoing image view.
            return outgoingBubbleImageView
        } else {  // If the message was not sent by the local user, return the incoming image view.
            return incomingBubbleImageView
        }
    }
    
//    // set text color based on who is sending the messages
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
//        
//        let message = messages[indexPath.item]
//        
//        if message.senderId == senderId {
//            cell.textView!.textColor = UIColor.whiteColor()
//        } else {
//            cell.textView?.textColor = UIColor.blackColor()
//        }
//        
//        
//        return cell
//    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    // MARK: - Create Message
    // This helper method creates a new JSQMessage with a blank displayName and adds it to the data source.
    func addMessage(_ id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: "", text: text)
        messages.append(message!)
    }
    
    internal func addResponseMessage(responseText: String) {
        addMessage("BOT", text: responseText)
        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
        finishReceivingMessage()
        
        if audioSwitch.isOn {
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: responseText)
            //utterance.rate = 0.5
            //utterance.voice = AVSpeechSynthesisVoice(language: "en-EN")
            synthesizer.speak(utterance)
            synthesizer.delegate = self
        }
    }


    // SEND button pressed
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {

        stopRecording()
        
        inputToolbar.contentView.leftBarButtonItem.isEnabled = true
        inputToolbar.contentView.textView.text = ""
        inputToolbar.contentView.textView.placeHolder = "New Message"
        inputToolbar.contentView.leftBarButtonItem.isSelected = false

        sendMessage(text: text)
    }
    
    
    func sendMessage(text: String) {
        addMessage(senderId, text: text)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
        
        KituraBotShared.sendMesage(text: text) { (responseText) in
            self.addResponseMessage(responseText: responseText)
        }
    }

    
    // Mark: textView delegate
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        
        // If the text is not empty, the user is typing
         isTyping = textView.text != ""
        
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.inputToolbar.contentView.leftBarButtonItem.isEnabled = false
            print("Stopping")
        } else {
            try! startRecording()
            print("Start recording")
        }
    }
    
    private func stopRecording() {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode?.removeTap(onBus: 0)
            
            print("Stopping")
        }
    }
    
}


extension ChatViewController : AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didPressAccessoryButton(nil)
    }

}


extension ChatViewController:UNUserNotificationCenterDelegate{

    private func extractMessage(fromPushNotificationUserInfo userInfo:[AnyHashable: Any]) -> String? {
        var message: String?
        if let aps = userInfo["aps"] as? NSDictionary {
            if let alert = aps["alert"] as? NSDictionary {
                if let alertMessage = alert["body"] as? String {
                    message = alertMessage
                }
            }
        }
        return message
    }
    

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {


        
        if let responseText = extractMessage(fromPushNotificationUserInfo: response.notification.request.content.userInfo) {
            print("===> Add Message: \(responseText)")
            self.addResponseMessage(responseText: responseText)
        }
        else {
            print("Received notification with no body")
        }
        
        
        if let textAction = response as? UNTextInputNotificationResponse {
            //print("Text \(textAction.userText)")
            
            sendMessage(text: textAction.userText)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        if let responseText = extractMessage(fromPushNotificationUserInfo: notification.request.content.userInfo) {
            print("===> Add Message: \(responseText)")
            self.addResponseMessage(responseText: responseText)
        }
        else {
            print("Received notification with no body")
        }
    }
}

