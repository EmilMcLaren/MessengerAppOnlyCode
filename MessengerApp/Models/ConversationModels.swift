//
//  ConversationModels.swift
//  MessengerApp
//
//  Created by Emil on 04.02.2023.
//

import Foundation


struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text : String
    let isRead: Bool
}










