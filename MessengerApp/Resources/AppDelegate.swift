//
//  AppDelegate.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ConversationVC()
        //window?.rootViewController = UINavigationController(rootViewController: TaskListViewController())
        window?.makeKeyAndVisible()
        

       
        return true
    }




}

