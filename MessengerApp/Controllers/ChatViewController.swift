//
//  ChatViewController.swift
//  MessengerApp
//
//  Created by Emil on 15.01.2023.

import UIKit
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    //var photoURL: String
    var senderId: String
    var displayName: String
}
class ChatViewController: MessagesViewController {
    private var messages = [Message]()
    private let senderSelf = Sender( senderId: "1",displayName: "Jony Smith") //photoURL: "",
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        messages.append(Message(sender: senderSelf,
                                messageId: "1",
                                sentDate: Date(),
                                 kind: .text("Hello")
                                ))
        messages.append(Message(sender: senderSelf,
                                messageId: "1",
                                sentDate: Date(),
                                 kind: .text("HelloHelloHelloHelloHello")))
        print(messages)
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate  = self
    }
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    var currentSender: SenderType {
        return senderSelf
    }
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}
