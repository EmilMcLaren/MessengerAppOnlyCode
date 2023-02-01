//
//  ViewController.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import openssl_grpc
import AVFoundation

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

class ConversationVC: UIViewController {

    private let spinner = JGProgressHUD(style: .dark )
    
    public var completion: ((SearchResult) -> (Void))?
    private var loginObserver: NSObjectProtocol?
    
    var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversation"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad ()
        title = "Chats"
        view.backgroundColor = .white
        navBarAppearance()
        
        //resetDefaults()
        //print(UserDefaults.value(forKey: "email"))
        
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        
        fetchConversation()
        setupTableView()
        startListeningForConversation()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversation()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
//        DispatchQueue.main.async {
//            self.tableView.reloadData()
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    
    
    private func startListeningForConversation() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let loginObserver = loginObserver {
            NotificationCenter.default.removeObserver(loginObserver)
        }
        
        
        print("starting conversation fetch...")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversation(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):

                print("success conversations models")
                
                guard !conversations.isEmpty else {return}
                
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get convos \(error)")
            }
            
        
        }
    }
    
    
    
    //Set NavigationBar and SearchController
     func  navBarAppearance() {
         navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                             target: self,
                                                             action: #selector(didTapComposeButton))
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = #colorLiteral(red: 0.8496792912, green: 0.9519454837, blue: 1, alpha: 1)
        
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    func fetchConversation() {
        tableView.isHidden = false
    }
    
    
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationVC()
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            print("\(result)")
            
            let currentConversation = strongSelf.conversations
            //check have and get to set profile conversation
            if let targetConversation = currentConversation.first(where: { $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            } else {
                strongSelf.createNewConversation(result: result)
            }
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        //check in database if Conversation with these two users exists
        //if it does, reuse Conversation id
        //otherwise use existing code
        DatabaseManager.shared.conversationExists(with: email) { [weak self] result in
            
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    
    
    //let isLoggedIN = UserDefaults.standard.bool(forKey: "logged_in")
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginVC()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
}


//MARK: TableView Data Source
extension ConversationVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell =  tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                  for: indexPath ) as! ConversationTableViewCell
       
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let model = conversations[indexPath.row]
        
        openConversation(model)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //begin delete
            tableView.beginUpdates()
            let conversationId = conversations[indexPath.row].id
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            }
            tableView.endUpdates()
        }
    }
    
}
