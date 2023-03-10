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
import MessageKit
import CoreLocation
import AVFAudio


/// Manager objects  to read and write data to real time firebase database
final class DatabaseManager {
    
    ///shared instance of class
    static let shared = DatabaseManager()
    private init() {}
    
    let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
    ///return dictionary node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observe(.value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//MARK: Account Manager
extension DatabaseManager {
    ///check if user exist for given email
    ///Parameters
    /// - `email`:            Target email to be checked
    /// - `completion`: Asynch closure to return with result
    public func userExist(with email: String, completition: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
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
        }
    }
    /// Gets all users from database
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

//MARK: - Sending messages / conversations
extension DatabaseManager {
    
    ///create new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                  return
              }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let refChild = database.child("\(safeEmail)")
        
        refChild.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateStringToSafe = ChatViewController.dateFormatter.string(from: messageDate)
            let dateString = DatabaseManager.safeEmail(emailAddress: dateStringToSafe)

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
            //
            
            let newConversationData: [String: Any] = [
                "id" : conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString, //norm
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id" : conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString, //norm
                    "message": message,
                    "is_read": false
                ]
            ]

            //update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot  in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            
            //update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //coversation array  exists for current user
                //you append should
                print("THIS in conversations")
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
                print("THIS else in conversations")
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
    
    ///Sends message with target conversation and mesaage
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else { return }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }

            let messageDate = newMessage.sentDate
            let dateStringToSelf = ChatViewController.dateFormatter.string(from: messageDate)
            let dateString = DatabaseManager.safeEmail(emailAddress: dateStringToSelf)
            
            var messageOne = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                messageOne = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString  {
                    messageOne = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString  {
                    messageOne = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                messageOne = ("\(location.coordinate.longitude),\(location.coordinate.latitude)")
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
            
            guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": messageOne,
                "date": dateString, //norm
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]

            currentMessages.append(newMessageEntry)

            self?.database.child("\(conversation)/messages/").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    var databaseEntryConversations = [[String:Any]]()
                    
                    let updateValue: [String:Any] = [
                        "date" : dateString, //norm
                        "is_read" : false,
                        "message" : messageOne
                    ]
                    
                    if var currentUserConversation = snapshot.value as? [[String:Any]]  {
                        //we need to create conversation entry
                        var targetConversation: [String:Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversation {
                            if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updateValue
                            currentUserConversation[position] = targetConversation
                            databaseEntryConversations = currentUserConversation
                        } else {
                            let newConversationData: [String: Any] = [
                                "id" : conversation,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updateValue
                            ]
                            currentUserConversation.append(newConversationData)
                            databaseEntryConversations = currentUserConversation
                        }
                        
                        
                    } else {
                        let newConversationData: [String: Any] = [
                            "id" : conversation,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": updateValue
                        ]
                        
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }

                    strongSelf.database.child("\(currentUserEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        //update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            
                            let updateValue: [String:Any] = [
                                "date" : dateString, //norm
                                "is_read" : false,
                                "message" : messageOne
                            ]
                            
                            var databaseEntryConversations = [[String:Any]]()
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            if var othertUserConversation = snapshot.value as? [[String:Any]] {
                                var targetConversation: [String:Any]?
                                var position = 0
                                
                                
                                for conversationDictionary in othertUserConversation {
                                    if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updateValue
                                    
                                    othertUserConversation[position] = targetConversation
                                    databaseEntryConversations = othertUserConversation
                                }
                                else{
                                    //failed to find in current collection
                                    let newConversationData: [String: Any] = [
                                        "id" : conversation,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name": currentName,
                                        "latest_message": updateValue
                                    ]
                                    othertUserConversation.append(newConversationData)
                                    databaseEntryConversations = othertUserConversation
                                }
                                
                            } else {
                                //current collection does not exist
                                let newConversationData: [String: Any] = [
                                    "id" : conversation,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name": currentName,
                                    "latest_message": updateValue
                                ]
                                
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
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
        let dateStringToSelf = ChatViewController.dateFormatter.string(from: messageDate)
        let dateString = DatabaseManager.safeEmail(emailAddress: dateStringToSelf)
        
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
            "date": dateString, //norm
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
                completion(false)
                return
            }
            print("collection created")
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
         
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let name = dictionary["name"] as? String
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
    public func getAllMessagesForConversation(for id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }

            let messages: [Message] = value.compactMap { dictionary in
                guard let name = dictionary["name"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let messageID = dictionary["id"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String
                      //let date = ChatViewController.dateFormatter.date(from: dateString)
                else {
                    print("failed to get messages from unwrap")
                    return nil
                }

                var kind: MessageKind?
                
                //view in chat (image, video, map)
                if type == "photo" {
                    //photo
                    guard let imageUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "plus") else {
                              return nil
                          }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    
                    kind = .photo(media)
                    
                } else if type == "video" {
                    //photo
                    guard let videoUrl = URL(string: content),
                          let placeHolder = UIImage(named: "video_placeholder") else {
                              return nil
                          }
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    
                    kind = .video(media)
                }
                else if type == "location" {
                    let locationComponent = content.components(separatedBy: ",")
                    
                    print("this locationComponent \(locationComponent)")
                    
                    guard let longitude = Double(locationComponent[0]),
                          let latitude = Double(locationComponent[1])  else {
                              print("Failed to get coordinates in send")
                              return nil
                          }
                    print("Rendering location long=\(longitude),latit\(latitude)")
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                            size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {return nil}
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: Date(),
                               kind: finalKind)
            }
            completion(.success(messages))
        }
    }
    
    ///delete conversation
    public func deleteConversation(conversationId: String, completion: @escaping (Bool)-> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Deleting conversation with id: \(conversationId)")
        
        //Get all conversation for current user
        //delete conversation in colletion with target id
        //reset those conversation for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationId {
                        print("found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("failed to write new conversation array")
                        return
                    }
                    print("deleted conversation")
                    completion(true)
                }
            }
        }
        
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            //iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard  let targerSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targerSenderEmail
            }) {
                //get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
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



