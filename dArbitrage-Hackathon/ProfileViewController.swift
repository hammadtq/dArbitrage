//
//  ProfileViewController.swift
//  dArbitrage-Hackathon
//
//  Created by Hammad Tariq on 10/7/18.
//  Copyright © 2018 uk.co.iologics. All rights reserved.
//

import UIKit
import KyberWidget
import MBProgressHUD

class profileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tokenLabel: UILabel!
    @IBOutlet weak var tokenBalance: UILabel!
}

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    var tokenArray = [[String]]()
    let privateKey : String = "3035a231c9f08f56459751aaa9b15c2de8848722f32b4b75d688624fba617a94"
    let walletAddress : String = "0x54a56fE3c98Fc9cFeC5609eEAB228a721deF40d1"
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        loadProfile()
    }
    
    func loadProfile(){
        showProgress()
        do {
            let keystore = try KWKeystore()
            keystore.importWallet(type: KWImportType.privateKey(string: privateKey)){ result in
                let external = KWExternalProvider(keystore: keystore, network: KWEnvironment.ropsten)
                external.getETHBalance(address: self.walletAddress) { result in
                    
                    switch result {
                    case .success:
                        let valueInDouble = Double(result.value!)/pow(10.0, 18.0)
                        print(valueInDouble.rounded(toPlaces: 6))
                        let eachToken = ["ETH", "\(valueInDouble.rounded(toPlaces: 6))"]
                        self.tokenArray.append(eachToken)
                        self.reloadData()
                    case .failure(let error):
                        print("failure \(error)")
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                }
            }
        } catch{}
    }
    
    
    
    
    //MARK:- TableView Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokenArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! profileTableViewCell
        cell.tokenLabel.text = tokenArray[indexPath.item][0]
        cell.tokenBalance.text = tokenArray[indexPath.item][1]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("This cell from the chat list was selected: \(indexPath.row)")
    }
    
    func reloadData(){
        MBProgressHUD.hide(for: self.view, animated: true)
        tableView.reloadData()
    }
    
    func showProgress(){
        let loadingNotification = MBProgressHUD.showAdded(to: view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading"
    }
    
}
