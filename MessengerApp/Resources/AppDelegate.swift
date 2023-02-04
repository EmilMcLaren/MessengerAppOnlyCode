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
import GoogleSignInSwift


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
        
        //google
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                print("Sign in \(String(describing: user))")
            } else {
                print("Error \(String(describing: error))")
            }
        }
        
        
        let conversationVC = ConversationVC()
        let profileVC = ProfileVC()
        
        let firstController = UINavigationController(rootViewController: conversationVC)
        let secondController = UINavigationController(rootViewController: profileVC)
        
        firstController.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(named: "messageBar")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal), tag: 0)
        secondController.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "profileBar")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal), tag: 0)
        
        let tapBar = UITabBarController()
        tapBar.tabBar.tintColor = .black
        
        tapBar.viewControllers = [firstController, secondController]
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tapBar
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
        
        //return GIDSignIn.sharedInstance.handle(url)
        var handled: Bool
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        // Handle other custom URL types.
        
        // If not handled by this app, return false.
        return false
    }
}

