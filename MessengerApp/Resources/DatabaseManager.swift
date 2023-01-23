//
//  DatabaseManager.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import Foundation
import FirebaseDatabase
import SwiftUI
import CoreMedia

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
     let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}


//MARK: Account Manager
extension DatabaseManager {
    
    ///check have an user
    public func userExist(with email: String, completition: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail ).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completition(false)
                return
            }
            completition(true)
        }
    }
    
    
    /// insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ]) { error, _ in
            guard  error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            /*
                users => [
                    [
                        "name" :
                        "safe_email":
                    ],
                     [
                         "name" :
                         "safe_email":
                     ]
             ]
             */
            
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String:  String]] {
                    //append to user dictionary
                    
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                        
                    }
                } else {
                    //crate that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
            
            
            //completion(true)
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

/*
    users => [
        [
            "name" :
            "safe_email":
        ],
         [
             "name" :
             "safe_email":
         ]
 ]
 */

//MARK: - Sending messages / conversations
extension DatabaseManager {
    
    /*
     "conversationID" : "dddd"
     
     "dddd" {
        "messages": [
            {
             "id": String
             "type": text, photo, video
             "content": String
             "date": Date(),
             "sender_email": String,
             "is_read": true/false
            }
     ]
     
     }
     
     
        conversation => [
            [
                "conversationID" : "dddd"
                "other_user_email":
                "latest_message" : => {
                    "date": Date()
                    "latest_message": "message
                    "is_read": true/false
                }
            ]
     ]
     */
    
    
    ///create new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {return}
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let refChild = database.child("\(safeEmail)")
        
        refChild.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] =
            [
                "id" : conversationID,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "name": name,
                    "message": message,
                    "is_read": false
                                    ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //coversation array  exists for current user
                //you append should
                conversations.append(newConversationData)
                
                userNode["conversations"] = conversations
                
                refChild.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
                
            } else {
                //coversation array  does NOT exist
                //create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                refChild.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            }
        }
    }
    
    
    public func finishCreatingConversation(name: String, conversationID: String,firstMessage: Message ,completion: @escaping (Bool) -> Void) {
//        {
//         "id": String
//         "type": text, photo, video
//         "content": String
//         "date": Date(),
//         "sender_email": String,
//         "is_read": true/false
//        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var messageOne = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            messageOne = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }

        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId, 
            "type": firstMessage.kind.messageKindString,
            "content": messageOne,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]

        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]

        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                print("it here have")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    
    ///Fatches and return all conversations for the user with passed in email
    public func getAllConversation(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            /*
            [
             ["other_user_email": emil-emper-gmail-com, "latest_message": {
                date = "Jan 23, 2023 at 2:31:26 AM GMT+5";
                "is_read" = 0;
                message = Hi;
                name = "Emil McLaren";
            },
             
             "id": conversation_emil-emper-gmail-com_email-gmail-com_Jan 23, 2023 at 2:31:26 AM GMT+5],
             
             ["other_user_email": emil-emper-gmail-com,
             "id": conversation_emil-emper-gmail-com_email-gmail-com_Jan 23, 2023 at 11:03:44 AM GMT+5,
             "latest_message": {
                    date = "Jan 23, 2023 at 11:03:44 AM GMT+5";
                    "is_read" = 0;
                    message = Dd;
                    name = "Emil McLaren";
            }]]
             */
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let name = latestMessage["name"] as? String
                else {
                          print("Not unwrap in guard from firebase collection Conversation")
                          return nil
                      }
                
                let latestMessageObject = LatestMessage(date: date ,
                                                  text: message,
                                                  isRead: isRead)

                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            }
            completion(.success(conversations))
        }
        
    }
    ///Get all messages for a given conversatiom
    public func getAllMessagesForConversation(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    ///Sends message with target conversation and mesaage
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}





struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
    var profilePictureFileName: String {
        //emil-emper-gmail-com_profile_picture.png
        return "\(safeEmail )_profile_picture.png"
    }
}
