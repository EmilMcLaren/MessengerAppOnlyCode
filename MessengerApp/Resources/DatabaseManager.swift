//
//  DatabaseManager.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
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
            completion(true)
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
