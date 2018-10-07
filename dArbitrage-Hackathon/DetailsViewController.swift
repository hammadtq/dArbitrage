//
//  DetailsViewController.swift
//  dArbitrage-Hackathon
//
//  Created by Gaurav Shukla on 10/7/18.
//  Copyright © 2018 uk.co.iologics. All rights reserved.
//

import UIKit

class detailsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var exchangeLabel: UILabel!
    @IBOutlet weak var pairLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var buttonLabel: UIButton!
}

class DetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var detailsArray = [[String]]()
    var selectedPair = [[String]]()
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
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
        cell.buttonLabel.setTitle(detailsArray[indexPath.item][3], for: .normal)
        return cell
    }


}

