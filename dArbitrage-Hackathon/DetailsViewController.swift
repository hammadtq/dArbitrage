//
//  DetailsViewController.swift
//  dArbitrage-Hackathon
//
//  Created by Gaurav Shukla on 10/7/18.
//  Copyright © 2018 uk.co.iologics. All rights reserved.
//

import UIKit
import KyberWidget

class detailsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var exchangeLabel: UILabel!
    @IBOutlet weak var pairLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
}

class DetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, KWCoordinatorDelegate {
    
    
    fileprivate var coordinator: KWCoordinator?
    
    var detailsArray = [[String]]()
    var selectedPair = [[String]]()
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        let config = KWThemeConfig.current
        config.navigationBarBackgroundColor = #colorLiteral(red: 0.2250583768, green: 0.3118225634, blue: 0.387561202, alpha: 1)
        config.actionButtonNormalBackgroundColor = #colorLiteral(red: 0.2250583768, green: 0.3118225634, blue: 0.387561202, alpha: 1)
        loadData()
    }
    
    func loadData(){
        let defaults = UserDefaults.standard
        selectedPair.append(defaults.stringArray(forKey: "selectedPair") ?? [String]())
        
        if(selectedPair[0][3] < selectedPair[0][5]){
            var pairArray = [selectedPair[0][0], selectedPair[0][2], selectedPair[0][3], "Buy"]
            detailsArray.append(pairArray)
            pairArray = [selectedPair[0][0], selectedPair[0][4], selectedPair[0][5], "Sell"]
            detailsArray.append(pairArray)
        }else{
            var pairArray = [selectedPair[0][0], selectedPair[0][4], selectedPair[0][5], "Buy"]
            detailsArray.append(pairArray)
            pairArray = [selectedPair[0][0], selectedPair[0][2], selectedPair[0][3], "Sell"]
            detailsArray.append(pairArray)
        }
        
    }
    
    //MARK:- TableView Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detailsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailsCell", for: indexPath) as! detailsTableViewCell
        cell.pairLabel.text = "\(detailsArray[indexPath.item][0])/ETH"
        cell.exchangeLabel.text = detailsArray[indexPath.item][1]
        cell.priceLabel.text = detailsArray[indexPath.item][2]
        cell.actionLabel.text = detailsArray[indexPath.item][3]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("This cell from the chat list was selected: \(indexPath.row)")
        print(detailsArray[indexPath.item])
        let selectedArray = detailsArray[indexPath.item]
        print(selectedArray)
        if selectedArray[1] == "Kyber" {
            print("kyber")
            let action = selectedArray[3]
            if action == "Buy" {
                let alert = UIAlertController(title: "Buy from Kyber", message: "How many \(selectedArray[0]) tokens you want to buy?", preferredStyle: .alert)
                alert.addTextField { field in
                    field.placeholder = "0.0001"
                }
                self.present(alert, animated: true, completion: nil)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Buy", style: .default) { _ in
                    let tokenAmount = alert.textFields?.first?.text ?? "0.0001"
                    self.buyTokens(receiveToken: selectedArray[0], receiveAmount: Double(tokenAmount) ?? 0.0000, network: KWEnvironment.ropsten, signer: "", commissionId: "", pinnedTokens: "ETH_KNC_DAI")
                })
                
            }else{
                swapTokens(network: KWEnvironment.ropsten, signer: "", commissionId: "")
            }
        }else{
            showAlert(title: "Patience", message: "This exchange hasn't been integrated fully with the app, yet!")
        }
    }
    
    //MARK:- Kyber Network Functions
    func swapTokens(network : KWEnvironment,
                    signer : String, commissionId : String){
        do {
            self.coordinator = try KWSwapCoordinator(
                baseViewController: self,
                network: network, // ETH network, default ropsten
                signer: nil,
                commissionId: nil
            )
            // set delegate to receive transaction data
            self.coordinator?.delegate = self
            
            // show the widget
            self.coordinator?.start()
        } catch {}
    }
    
    func buyTokens(receiveToken : String, receiveAmount : Double, network : KWEnvironment,
                   signer : String, commissionId : String, pinnedTokens : String){
        do {
            self.coordinator = try KWBuyCoordinator(
                baseViewController: self,
                receiveToken: receiveToken,
                receiveAmount: receiveAmount,
                network: network, // ETH network, default ropsten
                signer: nil,
                commissionId: nil
            )
            // set delegate to receive transaction data
            self.coordinator?.delegate = self
            
            // show the widget
            self.coordinator?.start()
        } catch {}
    }
    
    func coordinatorDidCancel() {
        self.coordinator?.stop(completion: {
            self.coordinator = nil
        })
    }
    
    func coordinatorDidFailed(with error: KWError) {
        self.coordinator?.stop(completion: {
            let errorMessage: String = {
                switch error {
                case .unsupportedToken: return "Unsupported Tokens"
                case .invalidAddress(let errorMessage):
                    return errorMessage
                case .invalidToken(let errorMessage):
                    return errorMessage
                case .invalidAmount: return "Invalid Amount"
                case .failedToLoadSupportedToken(let errorMessage):
                    return errorMessage
                case .failedToSendTransaction(let errorMessage):
                    return errorMessage
                }
            }()
            self.showAlert(title: "Failed", message: errorMessage)
            self.coordinator = nil
        })
    }
    
    func coordinatorDidBroadcastTransaction(with hash: String) {
        self.coordinator?.stop(completion: {
            self.showAlert(title: "Payment sent", message: "Tx hash: \(hash)")
            self.coordinator = nil
        })
    }
    
    func showAlert(title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

