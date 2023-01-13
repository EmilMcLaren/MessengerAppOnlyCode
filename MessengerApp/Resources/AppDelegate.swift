//
//  AppDelegate.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit
import Firebase
import FirebaseCore
import FBSDKCoreKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //firebase
        FirebaseApp.configure()
        //facebook
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
//        //google
//        GIDSignIn.sharedInstance.configuration?.clientID = "664606879930-a43q4ejjb2n7p8lur3e0rc0hecrtimnu.apps.googleusercontent.com"
//        GIDSignIn.sharedInstance()?.delegate = self
        
        

        
        let conversationVC = ConversationVC()
        let profileVC = ProfileVC()
        
        let firstController = UINavigationController(rootViewController: conversationVC)
        let secondController = UINavigationController(rootViewController: profileVC)
        
//        firstController.tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 0)
//        firstController.tabBarItem.title = "first"
        firstController.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(named: "person.crop.circle"), tag: 0)
        secondController.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "person.crop.circle"), tag: 1)
        
        let tapBar = UITabBarController()
        tapBar.tabBar.tintColor = .black
        tapBar.tabBar.backgroundColor = #colorLiteral(red: 0.8496792912, green: 0.9519454837, blue: 1, alpha: 1)
        //tapBar.setViewControllers([firstController, secondController], animated: true)
        tapBar.viewControllers = [firstController, secondController]
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tapBar
        //window?.rootViewController = UINavigationController(rootViewController: ConversationVC())
        window?.makeKeyAndVisible()
        
        return true
    }
    
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
}

