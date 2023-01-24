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


struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(let string):
            return "text"
        case .attributedText(let nSAttributedString):
            return "attributedText"
        case .photo(let mediaItem):
            return "photo"
        case .video(let mediaItem):
            return "video"
        case .location(let locationItem):
            return "location"
        case .emoji(let string):
            return "emoji"
        case .audio(let audioItem):
            return "audio"
        case .contact(let contactItem):
            return "contact"
        case .linkPreview(let linkItem):
            return "linkPreview"
        case .custom(let optional):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
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

       //listenForMessage()
    }

    
    
    private func listenForMessage(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(for: id) { result in
            switch result {
            case .success(let messages):
                print("success in get messages in listenForMessage: \(messages)")
                guard !messages.isEmpty else {
                    print("messages is empty")
                    return
                }
                self.messages = messages
                
                DispatchQueue.main.async {
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self.messagesCollectionView.scrollToLastItem()
                    }
                        
                    
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
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
//        DispatchQueue.main.async {
//          self.messagesCollectionView.reloadData()
//          self.messagesCollectionView.scrollToLastItem(animated: false)
//        }
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
        
        
        //send message
        if isNewConversation {
            //create convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] success in
                if success {
                    print("seccess send message")
                    self?.isNewConversation = false
                } else {
                    print("failed to sent")
                }
            }
        } else {
            //apped to existing conversation data
            DatabaseManager.shared.sendMessage(to: otherUserEmail, message: message) { success in
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
        
        let newIndetifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("created message id: \(newIndetifier)")
        
        return newIndetifier
    }
}


extension ChatViewController:  MessagesDataSource {

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
    
}

extension ChatViewController: MessageCellDelegate, MessagesLayoutDelegate, MessagesDisplayDelegate /*, InputBarAccessoryViewDelegate */{

}






