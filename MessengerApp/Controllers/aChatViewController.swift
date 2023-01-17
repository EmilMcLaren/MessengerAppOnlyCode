//
//  ChatViewController.swift
//  MessengerApp
//
//  Created by Emil on 15.01.2023.
//
//import UIKit
//import MessageKit
//import MessageUI
//import InputBarAccessoryView
//
//
//struct Message: MessageType {
//    var sender: SenderType
//    var messageId: String
//    var sentDate: Date
//    var kind: MessageKind
//}
//
//struct Sender: SenderType {
//    var photoURL: String
//    var senderId: String
//    var displayName: String
//}
//
//
//class ChatViewController: MessagesViewController {
//
//    private var messages = [Message]()
//    private var selfSender = Sender(photoURL: "", senderId: "18",displayName: "Jony Smith")
//    //private var selfSender1 = Sender(photoURL: "", senderId: "181",displayName: "Jony Smithy")
//
//   override func viewDidLoad() {
//
//      //messagesCollectionView = MessagesCollectionView.init(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height), collectionViewLayout: MessagesCollectionViewFlowLayout)
//
//       super.viewDidLoad()
//
//
//
////       open var messagesCollectionViewFlowLayout: MessagesCollectionViewFlowLayout {
////           guard let layout = collectionViewLayout as? MessagesCollectionViewFlowLayout else {
////               fatalError(MessageKitError.layoutUsedOnForeignType)
////           }
////           return layout
////       }
//       self.becomeFirstResponder()
//        view.backgroundColor = .red
//        self.tabBarController?.tabBar.isHidden = true
//
//        messages.append(Message(sender: selfSender,
//                                messageId: "1",
//                                sentDate:  Date().addingTimeInterval(-86410),
//                                kind: .text("Hello")
//                                ))
//
//        messages.append(Message(sender: selfSender,
//                                messageId: "121",
//                                sentDate:  Date().addingTimeInterval(-86420),
//                                kind: .text("HelloHelloHelloHelloHello Hello HHH GG HHHH")))
//       messages.append(Message(sender: selfSender,
//                               messageId: "122",
//                               sentDate:  Date().addingTimeInterval(-86430),
//                               kind: .text("HelloHelloHelloHelloHello Hello HHH GG HHHH")))
//       messages.append(Message(sender: selfSender,
//                               messageId: "123",
//                               sentDate:  Date().addingTimeInterval(-86440),
//                               kind: .text("HelloHelloHelloHelloHello Hello HHH GG HHHH")))
//
//       print(messages)
//       print(messages.count)
//
//       messagesCollectionView.messagesDataSource = self
//       messagesCollectionView.messagesLayoutDelegate = self
//       messagesCollectionView.messagesDisplayDelegate  = self
//       messagesCollectionView.messageCellDelegate = self
//
//       messagesCollectionView.contentSize = CGSize(width: view.width, height: view.height)
//
//       print(messagesCollectionView.messagesCollectionViewFlowLayout.itemSize)
//       print(messagesCollectionView.contentSize)
//
////       if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
////               layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
////               layout.textMessageSizeCalculator.incomingAvatarSize = .zero
////               layout.sectionInset = UIEdgeInsets(top: -10, left: 0, bottom: -5, right: 0)
////               layout.minimumInteritemSpacing = 0
////               layout.minimumLineSpacing = 0
////           }
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//
//    }
//
////    func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
////    }
//
//}
//
//
//extension ChatViewController:  MessagesDataSource {
//
//
//
//    var currentSender: SenderType {
//        print("Messages in currentSender\(messages)")
//        return selfSender
//    }
//
//    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
//        print("Messages in messageForItem\(messages)")
//        return messages[indexPath.section]
//    }
//
//    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
//        print("Messages in numberOfSections\(messages)")
//        return messages.count
//    }
//
//
////    func numberOfItems(inSection section: Int, in messagesCollectionView: MessagesCollectionView) -> Int {
////        print("Messages in numberOfItems\(messages)")
////        return messages.count
////    }
//
//}
//
//extension ChatViewController: MessageCellDelegate, MessagesLayoutDelegate, MessagesDisplayDelegate {
//    func messageStyle(for message: MessageType, at indexPath: IndexPath,
//                          in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
//            return .bubbleTail(isFromCurrentSender(message: message) ? .topRight : .topLeft, .curved)
//        }
//
//func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//    return 0
//}
//}
//
//
//
//
//
//
