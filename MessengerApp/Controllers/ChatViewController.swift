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


struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}


class ChatViewController: MessagesViewController {

    private var messages = [Message]()
    private var selfSender = Sender(photoURL: "", senderId: "18",displayName: "Jony Smith")

   override func viewDidLoad() {
       super.viewDidLoad()

        self.becomeFirstResponder()
        view.backgroundColor = .red
        self.tabBarController?.tabBar.isHidden = true

       messagesCollectionView.messagesDataSource = self
       messagesCollectionView.messagesLayoutDelegate = self
       messagesCollectionView.messagesDisplayDelegate  = self
       messagesCollectionView.messageCellDelegate = self
       //messageInputBar.delegate = self
       
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate:  Date(),
                                kind: .text("Hello")
                                ))

        messages.append(Message(sender: selfSender,
                                messageId: "121",
                                sentDate:  Date(),
                                kind: .text("HelloHelloHelloHelloHello Hello HHH GG HHHH")))

       loadFirstMessages()
    }


    
    func loadFirstMessages() {
        DispatchQueue.main.async {
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: false)
        }
    }

   
    override func viewDidAppear(_ animated: Bool) {
//        DispatchQueue.main.async {
//          self.messagesCollectionView.reloadData()
//          self.messagesCollectionView.scrollToLastItem(animated: false)
//        }
    }
}

extension ChatViewController:  MessagesDataSource {

    var currentSender: SenderType {
        return selfSender
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






