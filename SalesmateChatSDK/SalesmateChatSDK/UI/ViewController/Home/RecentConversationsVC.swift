//
//  RecentConversationsVC.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import UIKit

class RecentConversationsVC: UIViewController {

    // MARK: - Static Functions
    static func create(with viewModel: RecentConversationsViewModel) -> RecentConversationsVC {
        let storyboard = UIStoryboard(name: "RecentConversations", bundle: Bundle(for: Self.self))
        let VC = storyboard.instantiateInitialViewController() as! RecentConversationsVC
        
        VC.viewModel = viewModel
        
        return VC
    }
    
    // MARK: - Private Properties
    private var viewModel: RecentConversationsViewModel!
    
    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var btnViewAll: UIButton!
    @IBOutlet private weak var lblPowerBy: UILabel!
    @IBOutlet private weak var btnStartChat: UIButton!
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareView()
    }
    
    // MARK: - View
    private func prepareView() {
        prepareTableView()
        
        lblPowerBy.isHidden = !viewModel.showPowerBy
        btnStartChat.backgroundColor = UIColor(hex: viewModel.actionColorCode)
        btnViewAll.setTitleColor(UIColor(hex: viewModel.actionColorCode), for: .normal)
    }
    
    private func prepareTableView() {
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "ConversationCell", bundle: .salesmate),
                           forCellReuseIdentifier: ConversationCell.ID)
    }
}

extension RecentConversationsVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.conversationViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.ID, for: indexPath) as! ConversationCell
        
        cell.viewModel = viewModel.conversationViewModels[indexPath.row]
        
        return cell
    }
}
