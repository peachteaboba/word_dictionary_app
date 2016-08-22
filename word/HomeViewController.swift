//
//  ViewController.swift
//  word
//
//  Created by Andy Feng on 8/21/16.
//  Copyright © 2016 Andy Feng. All rights reserved.
//

import UIKit
import Alamofire

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var definitions = [Definition]()
   
    @IBOutlet weak var definitionTableView: UITableView!
    @IBOutlet weak var searchIconTapZone: UIView!
    @IBOutlet weak var searchIcon: UIImageView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var topHeaderLabel: UILabel!
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var promptBottomConstraint: NSLayoutConstraint!

    
    
    
    
    
    @IBAction func handleSearchButtonPressed(sender: UITextField) {
    
        self.dismissKeyboard()
        animateSearchBox()
        self.topHeaderLabel.text = sender.text!
        
        callAPI(sender.text!)
    }
    
    func callAPI(word: String) {
        
        // Clear definition variable
        self.definitions = [Definition]()
        
        
        // Remove spaces from input and create the URL string.
        let trimmedString = word.stringByReplacingOccurrencesOfString(" ", withString: "")
        let url = "https://owlbot.info/api/v1/dictionary/\(trimmedString)?format=json"
//        print(url)
        
        Alamofire.request(.GET, url)
            .responseJSON { response in

                if let responseArray = response.result.value as? NSArray {

                    for obj in responseArray {
                        
                        var type = ""
                        if let saveType = obj["type"] as? String {
                            type = saveType
                        }
                        var definition = ""
                        if let saveDefinition = obj["defenition"] as? String {
                            definition = saveDefinition
                        }
                        var example = ""
                        if let saveExample = obj["example"] as? String {
                            example = saveExample
                        }
                        
                        
                        let dataToInsert = Definition(type: type, definition: definition, example: example)
                        self.definitions.append(dataToInsert)
                    }
                    
                    // Update UI
                    self.definitionTableView.reloadData()
                    
                    
                    print(responseArray.count)
                    
                    if responseArray.count == 0 {
                        self.promptLabel.text = "Any word except that one.. Try another!"
                    } else {
                        self.promptLabel.text = "Peekaboo! Nothing to see here.."
                    }
                    
                    
                    
                    
                } else {
                    print("no word found")
                    
                }
                
                
        }
        
        
        
    }
    
    
    // MARK: - View Did Load ----------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColorFromRGB(0x00c860)
        self.topHeaderLabel.textColor = UIColorFromRGB(0x333333)
        
        self.promptLabel.textColor = UIColorFromRGB(0x0c743e)
        self.promptLabel.text = "Pick a word, Any word."
        self.promptBottomConstraint.constant = -60
        
        
        // Search field styles
        self.searchTextField.backgroundColor = UIColorFromRGB(0xf2f4f9)
        self.searchTextField.layer.cornerRadius = 8
        self.searchTextField.returnKeyType = UIReturnKeyType.Search
        self.searchTextField.layer.sublayerTransform = CATransform3DMakeTranslation(20, 2, 0)
        self.searchTextField.becomeFirstResponder()
        
        //Looks for single or multiple taps ----> Used to hide keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        // Add guesture action to search icon
        let searchIconTap = UITapGestureRecognizer(target: self, action: #selector(self.handleSearchIconTap))
        self.searchIconTapZone.userInteractionEnabled = true
        self.searchIconTapZone.addGestureRecognizer(searchIconTap)
        
        
//        self.definitionTableView.rowHeight = 244.0
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    
    
    
    
    // MARK: - Helper Functions ------------------------------------------------------------
    
    // Helper function to set colors with Hex values
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    func handleSearchIconTap() {
        animateSearchBox()
    }
    
    func animateSearchBox() {
        // Set transitions
        if self.topViewHeightConstraint.constant == 150 {
            self.searchTextField.alpha = 0
            self.topViewHeightConstraint.constant = 82
            dismissKeyboard()
            
        } else {
            self.searchTextField.alpha = 1
            self.topViewHeightConstraint.constant = 150
            
            self.searchTextField.text = ""
            self.searchTextField.becomeFirstResponder()
        }
        
        // Code to start animation
        self.view.setNeedsLayout()
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.7, options: [UIViewAnimationOptions.AllowUserInteraction], animations: {
            self.view.layoutIfNeeded()
        }) { (finished) in
            if finished {
                // Code to execute after animation...
            }
        }
    }
    
    
    
    
    // MARK: - Table View Prototype Functions ------------------------------------------------
    
    // How many cells are we going to need?
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.definitions.count
    }
    
    // How should I create each cell?
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Dequeue the cell from our storyboard
        let cell = tableView.dequeueReusableCellWithIdentifier("myCell") as! CustomDefinitionCell
        
        
        // Set table data
        cell.typeLabel.text = self.definitions[indexPath.row].type
        cell.definitionLabel.text = self.definitions[indexPath.row].definition
        cell.exampleLabel.text = self.definitions[indexPath.row].example
        
        
        
        // Table Cell View Styles
        cell.tableCellView.layer.cornerRadius = 20
 
        cell.exampleLabel.textColor = UIColorFromRGB(0x00c860)
        
        self.definitionTableView.estimatedRowHeight = 80
        self.definitionTableView.rowHeight = UITableViewAutomaticDimension
        
        
        
        
        
        // Change type text color based on type
        if cell.typeLabel.text == "noun" {
            cell.typeLabel.textColor = UIColorFromRGB(0x2b9bea)
        } else if cell.typeLabel.text == "adjective" {
            cell.typeLabel.textColor = UIColorFromRGB(0x8548f3)
        } else if cell.typeLabel.text == "verb" {
            cell.typeLabel.textColor = UIColorFromRGB(0xf35648)
        } else if cell.typeLabel.text == "exclamation" {
            cell.typeLabel.textColor = UIColorFromRGB(0xf69130)
        } else {
            cell.typeLabel.textColor = UIColorFromRGB(0x2b4ec1)
        }
        
        
        
        
        
        // Return cell so that Table View knows what to draw in each row
        return cell
    }
    

    
}

