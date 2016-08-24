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
    
    var senderText = String()
    var definitions = [Definition]()
    var uDTags = [String]()
    var uDSounds = [String]()
    var uDLists = [uDList]()
    
    
    var currentRow = 0 // used for scrolling to a specific row
    var verticalOffset = 0 // used for bringing down search field using scroll action
    
    
    
    
    // variable to save the last position visited, default to zero
    private var lastContentOffset: CGFloat = 0

    
    @IBOutlet weak var definitionTableView: UITableView!
    @IBOutlet weak var searchIconTapZone: UIView!
    @IBOutlet weak var searchIcon: UIImageView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var topHeaderLabel: UILabel!
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var promptTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var linkView: UIView!
    @IBOutlet weak var linkViewBottomConstraint: NSLayoutConstraint!
    
    
    
    
    
    @IBAction func handleSearchButtonPressed(sender: UITextField) {
    
        self.dismissKeyboard()
        animateSearchBox()
        self.topHeaderLabel.text = sender.text!
        
        self.senderText = sender.text!
        self.verticalOffset = 0
        
        callAPI(sender.text!)
    }
    
    func callAPI(word: String) {
        
        // Clear definition variable
        self.definitions = [Definition]()
        self.uDTags = [String]()
        self.uDSounds = [String]()
        self.uDLists = [uDList]()
        self.promptLabel.hidden = false
        self.promptLabel.text = "Searching..."
        
        // Remove spaces from input and create the URL string.
        let trimmedString = word.stringByReplacingOccurrencesOfString(" ", withString: "")
        let cleanString = removeSpecialCharsFromString(trimmedString)
        self.senderText = cleanString
        
        

        // OWLBOT API ------------------------------------------------------------------------------
        let owlBotURL = "https://owlbot.info/api/v1/dictionary/\(cleanString)?format=json"
        
        Alamofire.request(.GET, owlBotURL)
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
                    self.callUrbanDictionaryAPI(cleanString)
     
                } else {
                    self.promptLabel.text = "Space: the final frontier. These are the voyages of the starship Enterprise. Its five-year mission: to explore strange new worlds, to seek out new life and new civilizations, to boldly go where no man has gone before. (PS: Nice try Mr. Robot.. How bout we try a real word this time)"
                    self.definitionTableView.reloadData()
                }
                
                
        } // End OWLBOT API ------------------------------------------------------------------------------
        
        
        

        
        
    }
    
    
    
    func callUrbanDictionaryAPI(cleanString: String) {
        // URBAN DICTIONARY API ------------------------------------------------------------------------------
        let urbanDictionaryURL = "http://api.urbandictionary.com/v0/define?term=\(cleanString)"
        
        Alamofire.request(.GET, urbanDictionaryURL)
            .responseJSON { response in
                
                if let res = response.result.value {

                    // TAGS
                    if let tags = res["tags"] as? NSArray {
                        for val in tags {
                            self.uDTags.append(val as! String)
                        }
                    } else {
                        print("no tags")
                    }
                    
                    // SOUNDS
                    if let sounds = res["sounds"] as? NSArray {
                        for val in sounds {
                            self.uDSounds.append(val as! String)
                        }
                    } else {
                        print("no sounds")
                    }
                    
                    // LIST
                    if let lists = res["list"] as? NSArray {
                        for obj in lists {
                            
                            var defid = 0
                            if let saveDefid = obj["defid"] as? Int {
                                defid = saveDefid
                            }
                            var word = ""
                            if let saveWord = obj["word"] as? String {
                                word = saveWord
                            }
                            var author = ""
                            if let saveAuthor = obj["author"] as? String {
                                author = saveAuthor
                            }
                            var permalink = ""
                            if let savePermalink = obj["permalink"] as? String {
                                permalink = savePermalink
                            }
                            var definition = ""
                            if let saveDefinition = obj["definition"] as? String {
                                definition = saveDefinition
                            }
                            var example = ""
                            if let saveExample = obj["example"] as? String {
                                example = saveExample
                            }
                            var thumbs_up = 0
                            if let saveThumbs_up = obj["thumbs_up"] as? Int {
                                thumbs_up = saveThumbs_up
                            }
                            var thumbs_down = 0
                            if let saveThumbs_down = obj["thumbs_down"] as? Int {
                                thumbs_down = saveThumbs_down
                            }
                            
                            let dataToInsert = uDList(defid: defid, word: word, author: author, permalink: permalink, definition: definition, example: example, thumbs_up: thumbs_up, thumbs_down: thumbs_down)
                            self.uDLists.append(dataToInsert)
                        }
                        // Update UI
                        self.definitionTableView.reloadData()
                        self.updatePrompt()
                        
                    } else {
                        print("no list")
                    }
                    
                }
   
                
        } // End URBAN DICTIONARY API ------------------------------------------------------------------------------
        
        
    }
    
    
    
    
    
    
    
    
    
    // MARK: - View Did Load ----------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColorFromRGB(0x00c860)
        self.topHeaderLabel.textColor = UIColorFromRGB(0x333333)
        
        // Initialize prompt settings
        self.promptLabel.textColor = UIColorFromRGB(0x0c743e)
        self.promptLabel.text = "Pick a word, Any word."
        self.promptTopConstraint.constant = 25
        
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.linkViewBottomConstraint.constant = -400
 
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    
    
    
    
    // MARK: - Helper Functions ------------------------------------------------------------
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    
    
    func updatePrompt() {
        
        if self.definitions.count + self.uDLists.count == 0 {
            self.promptLabel.text = "Perhaps one day '\(self.senderText)' will be a searchable word. Today is not that day.. Try another!"
        } else {
            self.promptLabel.hidden = true
        }
    }
    
    
    
    
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
        
        // Stop the scroll movement by scrolling to the nearest row. This prevents the search bar to be hidden repeatedly during auto-scroll.
        if currentRow > 1 {
            self.definitionTableView.scrollToNearestSelectedRowAtScrollPosition(UITableViewScrollPosition.Middle, animated: true)
        }
        
        self.verticalOffset = 0
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
    
    
    
    
    
    
    
    
    
    // MARK: - Table View Prototype Functions ------------------------------------------------------------
   
    // How many cells are we going to need?
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.uDLists.count + self.definitions.count
    }
    
    // How should I create each cell?
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        self.currentRow = indexPath.row
        
        if indexPath.row < self.definitions.count {
        
            
            let cell = tableView.dequeueReusableCellWithIdentifier("myCell") as! CustomDefinitionCell
            
            // Set table data
            cell.typeLabel.text = self.definitions[indexPath.row].type
            cell.definitionLabel.text = self.definitions[indexPath.row].definition
            cell.exampleLabel.text = self.definitions[indexPath.row].example
            

            // Set custom cell styles
            cell.tableCellView.layer.cornerRadius = 20
            cell.exampleLabel.textColor = UIColorFromRGB(0x00c860)
            
            
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

            // Set dynamic cell height
            self.definitionTableView.estimatedRowHeight = 80
            self.definitionTableView.rowHeight = UITableViewAutomaticDimension
        
            
            return cell

        }  else {
            // Urban Dictionary Prototype Cells
            // Calculate the corresponding index/row for uDLists
            let row = indexPath.row - self.definitions.count

            // Dequeue the cell from our storyboard
            let cell = tableView.dequeueReusableCellWithIdentifier("urbanCell") as! CustomUrbanCell
            
            // Set custom cell data
            cell.definitionLabel.text = self.uDLists[row].definition
            cell.exampleLabel.text = self.uDLists[row].example
            cell.userLabel.text = self.uDLists[row].author
            
            let score = self.uDLists[row].thumbs_up - self.uDLists[row].thumbs_down
            
            if score >= 0 {
                cell.scoreLabel.text = "+\(score)"
                cell.scoreLabel.textColor = UIColorFromRGB(0x9A6FF7)
            } else {
                cell.scoreLabel.text = "-\(score)"
                cell.scoreLabel.textColor = UIColorFromRGB(0xFF3B65)
            }
            
            
            // Set custom cell styles
            cell.urbanCellView.layer.cornerRadius = 20
            cell.exampleLabel.textColor = UIColorFromRGB(0x00c860)
            
            // Set dynamic cell height
            self.definitionTableView.estimatedRowHeight = 80
            self.definitionTableView.rowHeight = UITableViewAutomaticDimension

            return cell
        }
    }
    
    
    
    
    
    // MARK: - Detect SCROLL function -------------------------------------------------------------------------
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (self.lastContentOffset > scrollView.contentOffset.y) {
 
            // If the view is scrolled all the way up and the user is still scrolling up. Bring down the search field.
            if scrollView.contentOffset.y < -100 && self.verticalOffset == 0 {

                // Change the verticalOffset variable so the following code does not get executed repeatedly
                self.verticalOffset = 1
              
                // Set changes tp be made in order to bring down search field
                self.topViewHeightConstraint.constant = 150
                self.searchTextField.alpha = 1
                self.searchTextField.text = ""
                
                // Code to start animation
                self.view.setNeedsLayout()
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.2, options: [UIViewAnimationOptions.AllowUserInteraction], animations: {
                    self.view.layoutIfNeeded()
                }) { (finished) in
                    if finished {
                        // Code to execute after animation:
                        // Bring up the keyboard after the first animation ends.
                        self.searchTextField.becomeFirstResponder()
                    }
                }
            }
        }
        else if (self.lastContentOffset < scrollView.contentOffset.y) {
            // Hide the keyboard and search bar if the user scrolls down in the table view.
            // Only do this if the contentOffset.y is above a certain point as to not conflict with the first if statement in this function.
            if self.lastContentOffset > 150 {
            
                // Hide the search text field only if its not already hidden
                if self.topViewHeightConstraint.constant != 82 {
                    self.searchTextField.alpha = 0
                    self.topViewHeightConstraint.constant = 82
                    dismissKeyboard()
                    self.verticalOffset = 0

                    // Code to start animation
                    self.view.setNeedsLayout()
                    UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [UIViewAnimationOptions.AllowUserInteraction], animations: {
                        self.view.layoutIfNeeded()
                    }) { (finished) in
                        if finished {
                            // Code to execute after animation...
                        }
                    }
                }
            }
        }
        // update the new position acquired
        self.lastContentOffset = scrollView.contentOffset.y
    }


    
    
    
    
    
    
    
    
    
}

