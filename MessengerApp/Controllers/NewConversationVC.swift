//
//  NewConversationVC.swift
//  MessengerApp
//
//  Created by Emil on 11.01.2023.
//

import UIKit
import JGProgressHUD

final class NewConversationVC: UIViewController {

    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]()

    private var results = [SearchResult]()
    
    private var hasFetched = false
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let searchBar : UISearchBar = {
        let search = UISearchBar()
        search.placeholder = "Search for user..."
        return search
    }()
    
    private let tableView : UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        navigationItem.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.becomeFirstResponder()
        
        view.addSubview(noResultsLabel)
        view.addSubview(self.tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y: (view.width-200/2),
                                      width: view.width/2,
                                      height: 200)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

//tableView DataSource
extension NewConversationVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier,
                                                 for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetDataUsers = results[indexPath.row]
        dismiss(animated: true) { [weak self] in
         self?.completion?(targetDataUsers)
        }
        print("deselectRow")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

extension NewConversationVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("clicked")
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "" ).isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        
        self.searchUsers(query: text)
    }
    
    func searchUsers(query: String) {
        //check if array has firebase result
        if hasFetched {
            //if it does: filter
            filterUsers(with: query)
            print("filterUsers")
        } else {
            print("else")
            print(DatabaseManager.shared.database.child("users"))
            //if it not: fetching
            DatabaseManager.shared.getAllUsers { [weak self] results in
                switch results {
                case .success(let userCollection):
                    print("get")
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                    self?.spinner.dismiss()
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        //update UI: show results or show noResultsLabel
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        self.spinner.dismiss()

        let results: [SearchResult] = self.users.filter {
            guard let email = $0["email"], email != safeEmail else {
                      return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
            
        }.compactMap({
                guard let email = $0["email"], let name = $0["name"] else {
                          return nil
                }
                return SearchResult(name: name, email: email)
            })
    
        self.results = results
        updateUI()
    }

    func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = false
        }
        else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
