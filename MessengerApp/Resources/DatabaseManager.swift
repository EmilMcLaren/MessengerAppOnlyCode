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
        database.child(email).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completition(false)
                return
            }
            completition(true)
        }
    }
    
    
    /// insert new user to database
    public func insertUser(with user: ChatAppUser) {
        database.child(user.emailAddress).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ])
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
   // let profileImage: String
}
