//
//  Chat.swift
//  MessengerApp
//
//  Created by Emil on 16.01.2023.
//


import UIKit
import MessageKit
import MessageUI
import InputBarAccessoryView
import openssl_grpc
import PhotosUI
import SDWebImage
import AVKit
import AVFoundation
import CoreLocation


struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}


struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}



extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}


class ChatViewController: MessagesViewController {

    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var otherUserEmail: String
    private var conversationID: String?
    
    public var isNewConversation = false
    
    
    private var messages = [Message]()
    
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") else {return nil}
        
        let selfEmail = DatabaseManager.safeEmail(emailAddress: email as! String)
        
        return Sender(photoURL: "",
               senderId: selfEmail,
               displayName: "Me")
    }

    init(with email: String, id: String? ) {
        self.otherUserEmail = email
        self.conversationID = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
   override func viewDidLoad() {
       super.viewDidLoad()

        self.becomeFirstResponder()
        view.backgroundColor = .red
        self.tabBarController?.tabBar.isHidden = true

       messagesCollectionView.messagesDataSource = self
       messagesCollectionView.messagesLayoutDelegate = self
       messagesCollectionView.messagesDisplayDelegate  = self
       messagesCollectionView.messageCellDelegate = self
       messageInputBar.delegate = self
       messagesCollectionView.delegate = self
       messageInputBar.becomeFirstResponder()
       setupInputButton()
    }


    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            
            guard let strongSelf = self else { return }
            
            guard  let messageID = strongSelf.createMessageId(),
                  let conversationID = strongSelf.conversationID,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            
            print("long=\(longitude) | lati=\(latitude)")
            
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                 size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageID,
                                  sentDate: Date(),
                                  kind: .location(location))

            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("sent location message")
                } else {
                    print("failed to sent location message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputAction() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach photo?",
                                            preferredStyle: .actionSheet)
        
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            var configuration: PHPickerConfiguration = PHPickerConfiguration()
            configuration.filter = PHPickerFilter.images

            let picker: PHPickerViewController = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    
    private func presentVideoInputAction() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach video?",
                                            preferredStyle: .actionSheet)
        
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            var configuration: PHPickerConfiguration = PHPickerConfiguration()
            configuration.filter = PHPickerFilter.videos
            

            let picker: PHPickerViewController = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    
    
    func loadFirstMessages() {
        DispatchQueue.main.async {
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: false)
        }
    }

   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationID = conversationID {
            listenForMessage(id: conversationID, shouldScrollToBottom: true)
        }
    }
    
    private func listenForMessage(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(for: id) { [weak self] result in
            switch result {
            case .success(let messages):
                //print("success in get messages in listenForMessage: \(messages)")
                guard !messages.isEmpty else {
                    print("messages is empty")
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
    }
}


//MARK: UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard  let messageID = self.createMessageId(),
              let conversationID = self.conversationID,
              let name = self.title,
              let selfSender = self.selfSender else {
            return
        }
        
        guard let provider = results.first?.itemProvider else { return }
        
        
//        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
//            provider.loadObject(ofClass: UIImage.self) { image, error in
//                <#code#>
//            }
//        }
        
        
        
        DispatchQueue.global().async {
            
//            for item in results {
//                item.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                   
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
 
                    if let image = image as? UIImage, let imageData = image.pngData() {
                        let fileName = "photo_messages_" + messageID.replacingOccurrences(of: " ", with: "-") + ".png"
                        DispatchQueue.main.async {
                            //upload image
                            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self]  result in
                                guard let strongSelf = self else { return }
                                
                                switch result {
                                case .success(let urlString):
                                    //ready to send message
                                    print("Uploaded messages photo: \(urlString)")
                                    
                                    guard let url = URL(string: urlString),
                                    let placeholder = UIImage(systemName: "plus") else {
                                        return
                                    }

                                    
                                    let media = Media(url: url,
                                                      image: nil,
                                                      placeholderImage: placeholder,
                                                      size: .zero)
                                    
                                    let message = Message(sender: selfSender,
                                                          messageId: messageID,
                                                          sentDate: Date(),
                                                          kind: .photo(media))

                                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                                        if success {
                                            print("sent photo message")
                                        } else {
                                            print("failed to sent photo message")
                                        }
                                    }
                                case .failure(let error):
                                    print("message photo upload error: \(error)")
                                }
                            }}
                        
                    } else {
                        print("Its not unwrap from image send")
                    }
                    
            
                }
            
            } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                
                provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: [:]) { movieUrl, error in
                    
                
                //provider.loadObject(ofClass: UTType.movie.identifier) { movie, error in


                let fileName = "video_messages_" + messageID.replacingOccurrences(of: " ", with: "-") + ".mov"
                            DispatchQueue.main.async {
                                if let url = movieUrl as? URL {
                                //upload image
                                    StorageManager.shared.uploadMessageVideo(with: url, fileName: fileName) { [weak self]  result in
                                    guard let strongSelf = self else { return }

                                    switch result {
                                    case .success(let urlString):
                                        //ready to send message
                                        print("Uploaded messages video: \(urlString)")

                                        
                                        guard let url = URL(string: urlString),
                                        let placeholder = UIImage(systemName: "plus") else {
                                            return
                                        }


                                        let media = Media(url: url,
                                                          image: nil,
                                                          placeholderImage: placeholder,
                                                          size: .zero)

                                        let message = Message(sender: selfSender,
                                                              messageId: messageID,
                                                              sentDate: Date(),
                                                              kind: .video(media))

                                        DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                                            if success {
                                                print("sent video message")
                                            } else {
                                                print("failed to sent video message")
                                            }
                                        }
                                    case .failure(let error):
                                        print("message photo upload error: \(error)")
                                    }
                                }}}
                }
                print("There sent movie")
            }
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageID = createMessageId() else {
            return
        }
    
        print("sending \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageID,
                              sentDate: Date(),
                              kind: .text(text))
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let otherUserEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        //send message
        if isNewConversation {
            print("isNewConversation true")
            //create convo in database
            DatabaseManager.shared.createNewConversation(with: self.otherUserEmail, name: self.title ?? "User", firstMessage: message) {  [weak self] success in
                if success {
                    print("seccess send message")
                    self?.isNewConversation = false
                } else {
                    print("failed to sent")
                }
            }
        } else {
            print("isNewConversation false")
//            to conversation: String, name: String, newMessage: Message
            guard let conversationID = conversationID, let name = self.title else {return}
            
            //apped to existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("message sent")
                } else {
                    print("message not sent")
                }
            }
        }
    }


    
    private func createMessageId() ->  String? {
        //date, senderEmail, randomInt, otherUserEmail
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String  else {
                  return ""
            }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        let safeDateString = DatabaseManager.safeEmail(emailAddress: dateString)
        
        let newIndetifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(safeDateString)"
        //debag dateString
        //let newIndetifier = "\(otherUserEmail)_\(safeCurrentEmail)"
        print("created message id: \(newIndetifier)")
        
        return newIndetifier
    }
}



extension ChatViewController:  MessagesDataSource {

    
//    override class func setAccessibilityDropPointDescriptors(_ accessibilityDropPointDescriptors: [UIAccessibilityLocationDescriptor]?) {
//        <#code#>
//    }
    
    var currentSender: SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email shoul be cashed")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {return}
            
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let message = messages[indexPath.section]
//
//        switch message.kind {
//        case .photo(let media):
//            guard let imageUrl = media.url else {return}
//
//            let vc = PhotoVC(with: imageUrl)
//            self.navigationController?.pushViewController(vc, animated: true)
//        default:
//            break
//        }
//    }
    
}

extension ChatViewController: MessageCellDelegate, MessagesLayoutDelegate, MessagesDisplayDelegate /*, InputBarAccessoryViewDelegate */ {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {return}
        
        let message = messages[indexPath.section]
       
           switch message.kind {
           case .location(let locationData):
               let coordinates = locationData.location.coordinate
               let vc = LocationPickerViewController(coordinates: coordinates)
               vc.title = "Location"
               vc.isPickable = false
               self.navigationController?.pushViewController(vc, animated: true)
           default:
               break
           }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {return}
        
        let message = messages[indexPath.section]
       
           switch message.kind {
           case .photo(let media):
               guard let imageUrl = media.url else {return}
   
               let vc = PhotoVC(with: imageUrl)
               self.navigationController?.pushViewController(vc, animated: true)
               
           case .video(let media):
               guard let videoUrl = media.url else {return}
               print(videoUrl)
               let vc = AVPlayerViewController()
               vc.player = AVPlayer(url: videoUrl)
               
               present(vc, animated: true)
               
           default:
               break
           }
    }
}






