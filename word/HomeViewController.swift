//
//  ViewController.swift
//  word
//
//  Created by Andy Feng on 8/21/16.
//  Copyright © 2016 Andy Feng. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation
import AVFoundation.AVAudioSession
import AudioToolbox



class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    // MARK: - Global Variables -------------------------------------------------------------------
    var senderText = String()
    var senderTextDirty = String()
    var definitions = [Definition]()
    var uDTags = [String]()
    var uDSounds = [String]()
    var uDLists = [uDList]()
    var wikiExtract = ""
    
    
    var currentRow = 0 // used for scrolling to a specific row
    var verticalOffset = 0 // used for bringing down search field using scroll action
    var isFirstLoad = 1 // used to disable drag down gesture on first page after app loads
    var random = 0
    var prevRand = 0 // to track if the current displayed word was a random one
    
    var player = AVPlayer()
    
    
    // variable to save the last position visited, default to zero
    private var lastContentOffset: CGFloat = 0
    
    // Cache the baseline top title left constraint for each new word
    var topTitleLeftConstraint: CGFloat = 0
   
    
    
    
    
    
    // MARK: - Outlets -----------------------------------------------------------------------------

    @IBOutlet weak var topHeaderLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var definitionTableView: UITableView!
    @IBOutlet weak var searchIconTapZone: UIView!
    @IBOutlet weak var searchIcon: UIImageView!
    @IBOutlet weak var searchIconDark: UIImageView!
    @IBOutlet weak var topRightTapZone: UIView! // <----------- top right tap zone (not assigned yet)
    
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var topHeaderLabel: UILabel!
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var promptTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var linkView: UIView!
    @IBOutlet weak var linkViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var soundImage: UIImageView!
   
    @IBOutlet weak var xButton: UIImageView!
    @IBOutlet weak var randomWordIndicator: UILabel!
    
    @IBOutlet weak var shakeForRandView: UIView!
    @IBOutlet weak var shakeForRandLabel: UILabel!
 
    
    // MARK: - Handle Stuff Pressed Functions ---------------------------------------------------
    
    
    func handleSearchIconTap() {
        animateSearchBox()
        
        // Stop the scroll movement by scrolling to the nearest row. This prevents the search bar to be hidden repeatedly during auto-scroll.
        if currentRow > 1 {
            self.definitionTableView.scrollToNearestSelectedRowAtScrollPosition(UITableViewScrollPosition.Middle, animated: true)
        }
        
        self.verticalOffset = 0
    }
    
    
    func handleRandTap() {
        self.random = 1
        self.prevRand = 1
       
        self.setTopTitleText("rolling dice..")
        self.topHeaderLabel.textColor = UIColorFromRGB(0xD1D1D1)
        
        
        self.cleanInputString("rand")
    }
    
    
    
    func handleClearText() {
        
        self.searchTextField.text = ""
        self.xButton.hidden = true
        
    }
    
    // Function that executes every time the text field is altered
    func textFieldDidChange(textField: UITextField) {
        // Do code here when the text field is altered
        self.xButton.hidden = false
    }
    
    
    func handlePlaySound() {
        // Check if there is a sound url in the sounds array
        if self.uDSounds.count > 0 {
           
            // Play the sound if the sound image is gray
            if self.soundImage.image == UIImage(named: "sound") {
                
                // Right when the sound starts playing, change the color of the sound icon
                self.soundImage.image = UIImage(named: "soundPlaying")
                
                // Convert normal string to NSURL String
                let url : NSURL = NSURL(string: self.uDSounds[0])!
                
                // Create the player item that will play the sound
                let playerItem = AVPlayerItem(URL: url)
                
                // Set an listener for when the sounds is done playing
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
            
                // Play the sound
                self.player = AVPlayer(playerItem:playerItem)
                self.player.volume = 1.0
                self.player.play()
                
            } else {
                // Change the sound icon
                self.soundImage.image = UIImage(named: "sound")
                
                // Stop playing the sound
                self.player.pause()
                
                // Initiate new player so the sound will play from the beginning next time
                self.player = AVPlayer()
            }
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        
        // When the sound is done playing, change the sound icon back to original
        self.soundImage.image = UIImage(named: "sound")
    }
    
    
    
    @IBAction func handleSearchButtonPressed(sender: UITextField) {
        // Set the top title text
        self.setTopTitleText(sender.text!)

        // Move to the top of the table every time a new search is initiated
        self.definitionTableView.contentOffset = CGPointMake(0, 0 - self.definitionTableView.contentInset.top);
        
        // Cleans the input string and then calls the API
        self.cleanInputString(sender.text!)
    }
    
    
    
    
    
    
    
    // MARK: - NEW HOTNESS API ----------------------------------------------------------------------------------
    
    func callNewHotness(cleanString: String) {

        // Hide the rand indicator in case it's not hidden
        if self.randomWordIndicator.hidden == false {
            self.randomWordIndicator.hidden = true
        }
        
        let headers = [
            "X-Mashape-Key": "MHOVySweXOmsh65XEw8g4ZIbCooup10TJsMjsnK8rElAjjA3JJ"
        ]
        
        var wordsURL = ""
        if self.random == 0 {
            wordsURL = "https://wordsapiv1.p.mashape.com/words/\(cleanString)"
            
            // reset prev random
            if self.prevRand == 1 {
                self.prevRand = 0
            }
            
        } else {
            wordsURL = "https://wordsapiv1.p.mashape.com/words/?random=true"
        }
       
        Alamofire.request(.GET, wordsURL, headers: headers).responseJSON { response in   // Words API ---------------------------------------
            
            if let responseArray = response.result.value as? NSDictionary {

                if self.random == 1 {
                    if let randomWord = responseArray["word"] as? String {
                        
                        // Show the random word as the title
                        self.setTopTitleText(randomWord)
                        
                        // Show random word indicator
                        self.randomWordIndicator.hidden = false
                        
                        self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                        let wikiRand = self.removeSpecialCharsFromString(randomWord)
                        self.senderTextDirty = wikiRand
                        self.senderText = wikiRand.stringByReplacingOccurrencesOfString(" ", withString: "")
                    } else {
                        print("404")
                        self.topHeaderLabel.text = "404"
                        self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                    }
                } else {
                    if self.topHeaderLabel.textColor != self.UIColorFromRGB(0x333333) {
                        self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                    }
                }
                
                self.random = 0
                
                if let results = responseArray["results"] as? NSArray {
                    
                    for dic in results {
                        
                        var typeSave = ""
                        if let type = dic["partOfSpeech"] as? String {
                            typeSave = type
                        }
                        
                        var definitionSave = ""
                        if let definition = dic["definition"] as? String {
                            definitionSave = definition
                        }

                        var exampleSave = ""
                        if let example = dic["examples"] as? NSArray {
                            if example.count > 0 {
                                if let exp1 = example[0] as? String {
                                    exampleSave = exp1
                                }
                            } else {
                                print("no mas")
                            }
                        }
                        
                        // Cache the data in a global array if the definition is not blank
                        if definitionSave != "" {
                            let dataToInsert = Definition(type: typeSave, definition: definitionSave, example: exampleSave)
                            self.definitions.append(dataToInsert)
                        }
                        

                    } // End for loop
                    
                    // Update UI
                    self.definitionTableView.reloadData()
                    self.wikipediaAPI()
                } else {
                    self.definitionTableView.reloadData()
                    self.wikipediaAPI()
                }
            } else {
                
                if self.random == 1 {
                    self.random = 0
                    print("error ---> no random found!!!")
                    self.topHeaderLabel.text = "404"
                    self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                    self.senderTextDirty = "404"
                    self.senderText = "404"
                }
                
                if self.topHeaderLabel.textColor != self.UIColorFromRGB(0x333333) {
                    self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                }
                
                self.definitionTableView.reloadData()
                self.wikipediaAPI()
            }
        } // END Words API ----------------------------------
    }
    
    
    func wikipediaAPI() { // WORDNIK API ------------------------------------------------------------------------------
        
        // Clean the string
        let cleanString = self.removeSpecialCharsFromString(self.senderTextDirty)
        
        // Replace empty spaces with %20
        let modifiedString = cleanString.stringByReplacingOccurrencesOfString(" ", withString: "%20")
   
        let wikipediaURL = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&exintro=&titles=\(modifiedString)"
        
        Alamofire.request(.GET, wikipediaURL).responseJSON { response in
            
            if let responseArray = response.result.value as? NSDictionary {
                
                if let data = responseArray["query"] {
                    if let pages = data["pages"] {
                        if let extract = pages!.allValues[0]["extract"] as? String {
                            
                            // Clean HTML string
                            var extractStr = extract.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
                            extractStr = self.removeSpecialCharsFromStringWiki(extractStr)

                            // Don't display wiki extract if if gives you that From other cap nonsense..
                            var sampleString = extractStr as NSString
                            
                            // Sample the first 26 characters
                            if extractStr.characters.count > 25 {
                                sampleString = sampleString.substringWithRange(NSRange(location: 0, length: 26))
                            }

                            // Cache the extract in the global variable. Check if it's useful info.
                            if extractStr.characters.count > cleanString.characters.count + 15  && sampleString != "From other capitalisation:" {

                                // If the extract starts with "?? may refer to:" Remove that part :::::::::::::::::::::::::::::::::::::
                                var capitalizedString = cleanString
                                
                                // Capitalizing first letter only
                                capitalizedString = String(capitalizedString.characters.first!).capitalizedString + String(capitalizedString.characters.dropFirst())
                                
                                // Removing front and back whitespace
                                capitalizedString = capitalizedString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                                
                                sampleString = extractStr as NSString
                                sampleString = sampleString.substringWithRange(NSRange(location: 0, length: capitalizedString.characters.count + 14))
                                
                                // test word: Norristown
                                var sampleString2 = extractStr as NSString
                                sampleString2 = sampleString2.substringWithRange(NSRange(location: 0, length: capitalizedString.characters.count + 10))
                                
                                if sampleString == "\(capitalizedString) may refer to:" {
                                    // Remove the front part
                                    sampleString = extractStr as NSString
                                    sampleString = sampleString.substringWithRange(NSRange(location: capitalizedString.characters.count + 14, length: extractStr.characters.count - (capitalizedString.characters.count + 14)))
                                    extractStr = sampleString as String
                                } else if sampleString2 == "\(capitalizedString) may mean:" {
                                    // Remove the front part
                                    sampleString2 = extractStr as NSString
                                    sampleString2 = sampleString2.substringWithRange(NSRange(location: capitalizedString.characters.count + 10, length: extractStr.characters.count - (capitalizedString.characters.count + 10)))
                                    extractStr = sampleString2 as String
                                }
                                // End remove "?? may refer to:" ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                                
                                self.wikiExtract = extractStr
                            }

                            // Update UI
                            self.definitionTableView.reloadData()
                            self.callUrbanDictionaryAPI()
                            
                        } else {
                            // Update UI
                            self.definitionTableView.reloadData()
                            self.callUrbanDictionaryAPI()
                        }
                    } else {
                        // Update UI
                        self.definitionTableView.reloadData()
                        self.callUrbanDictionaryAPI()
                    }
                } else {
                    // Update UI
                    self.definitionTableView.reloadData()
                    self.callUrbanDictionaryAPI()
                }
            } else {
                print("no mas")
                // Update UI
                self.definitionTableView.reloadData()
                self.callUrbanDictionaryAPI()
            }
            
            
        }
    } // END WIKIPEDIA API ------------------------------------------------------------------------------
    
    
    

    
    func callUrbanDictionaryAPI() {
        // URBAN DICTIONARY API ------------------------------------------------------------------------------
        
        let cleanString = self.senderText
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
                            
                            
                            // If there are sounds, then show the sound image.
                            self.soundImage.hidden = false
                            
                            self.refreshTopTitleConstraint()

                            
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
                            
                            // Cache the result if there is both a definition and example
                            if definition != "" && example != "" {
                                let dataToInsert = uDList(defid: defid, word: word, author: author, permalink: permalink, definition: definition, example: example, thumbs_up: thumbs_up, thumbs_down: thumbs_down)
                                self.uDLists.append(dataToInsert)
                            }

                        }
                        
                        // Sort according to score
                        self.uDLists.sortInPlace { $0.score > $1.score }
                        
                        
                        // Update UI
                        self.definitionTableView.reloadData()
                        self.updatePrompt()
 
                    } else {
                        print("no list")
                    }
                    
                } else {
                    // Update UI
                    self.definitionTableView.reloadData()
                    self.updatePrompt()
                }
   
                
        } // End URBAN DICTIONARY API ------------------------------------------------------------------------------
    }
    
    

    
    
    
    
    // GHIPHY API test -----------
    func giphyAPI() {
        
        
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - View Did Load ----------------------------------------------------------------
    override func viewDidLoad() {
        

        super.viewDidLoad()
        
        
        // Motion detect for shake guesture
        self.becomeFirstResponder()
        
        
        
        
        self.view.backgroundColor = UIColorFromRGB(0x00c860)
        self.topHeaderLabel.textColor = UIColorFromRGB(0x333333)
        
        // Top header left constraint
        self.topHeaderLeftConstraint.constant = (self.view.frame.width / 2) - (self.topHeaderLabel.intrinsicContentSize().width / 2)
        
        
        // Table view styles
        self.definitionTableView.contentInset = UIEdgeInsetsMake(11, 0, 200, 0);
   
        // Hide sound image amoung other things on first load
        self.soundImage.hidden = true
        self.xButton.hidden = true
        self.searchIconDark.alpha = 1
        self.searchIcon.alpha = 0
        self.randomWordIndicator.hidden = true
        
        
        
        // Set sound playing to 'Ambient' so it won't inturrupt other audio
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        
        
        // Initialize prompt settings
        self.promptLabel.textColor = UIColorFromRGB(0x0c743e)
        self.promptLabel.text = "Pick a word. Any word."
        self.promptTopConstraint.constant = 25
        
        // Shake for rand styles
        self.shakeForRandView.backgroundColor = UIColorFromRGB(0x0D7A42) // dark green
        self.shakeForRandView.layer.cornerRadius = self.shakeForRandView.frame.height / 2
        self.shakeForRandLabel.textColor = UIColorFromRGB(0x00c860)
        
        
        
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
        
        
        // Add guesture action to Top Header Label
        let playSound = UITapGestureRecognizer(target: self, action: #selector(self.handlePlaySound))
        self.topHeaderLabel.userInteractionEnabled = true
        self.topHeaderLabel.addGestureRecognizer(playSound)
        
        // Add guesture action to X Button
        let clearText = UITapGestureRecognizer(target: self, action: #selector(self.handleClearText))
        self.xButton.userInteractionEnabled = true
        self.xButton.addGestureRecognizer(clearText)

        // Add gesture to text field to sense text change
        self.searchTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.linkViewBottomConstraint.constant = -400

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("My god.. The memory level on this app is over 9000!!! Quick, do something!")
    }

    // Allows shake gesture to be recognized
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // Function that executes after shake is detected
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if(event!.subtype == UIEventSubtype.MotionShake) {
            //            print("You shook me, now what")
            handleRandTap()
        }
    }
 

    
    // MARK: - Helper Functions ------------------------------------------------------------
    func cleanInputString(dirty: String) {

        if self.isFirstLoad == 1 {
            self.isFirstLoad = 0
        }
        
        self.dismissKeyboard()
        self.animateSearchBox()
        self.verticalOffset = 0
        
        
        
        
        self.senderTextDirty = dirty
        
        // Clear definition variable
        self.definitions = [Definition]()
        self.uDTags = [String]()
        self.uDSounds = [String]()
        self.uDLists = [uDList]()
        self.promptLabel.hidden = false
        self.promptLabel.text = "Searching..."
        self.shakeForRandView.hidden = true
        
        // Reset wikiExtract variable
        self.wikiExtract = ""
        
        // Hide sound image on new api call
        self.soundImage.hidden = true
        
        // Remove spaces from input and create the URL string.
        var trimmedString = dirty.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // Give the user a search term if they search for an empty string
        if trimmedString == "" {
            trimmedString = "nothing"
            self.setTopTitleText(trimmedString)
        }
        
        
        // Change the string if it's really really long
        if trimmedString.characters.count > 50 {
            trimmedString = "long"
            self.setTopTitleText(trimmedString)
        }
        
        
        let cleanString = removeSpecialCharsFromString(trimmedString)
        self.senderText = cleanString
        
        // Initiate API Call
        self.callNewHotness(cleanString)
        
    }
    
    
    
    
    
    func setTopTitleText(word: String) {
        var wordToDisplay = word
        
        if word.characters.count > 25 {
            while wordToDisplay.characters.count > 15 {
                wordToDisplay.removeAtIndex(wordToDisplay.endIndex.predecessor())
            }
            wordToDisplay += ".."
        }
        
        self.topHeaderLabel.text = wordToDisplay
        self.senderText = word
        
        // Cache the title lebel left constraint for future use
        self.topTitleLeftConstraint = (self.view.frame.width / 2) - (self.topHeaderLabel.intrinsicContentSize().width / 2) + 2
        
        // Update the title label left constraint
        self.topHeaderLeftConstraint.constant = self.topTitleLeftConstraint
        
        
    }
    
    
    func refreshTopTitleConstraint() {
        // Update the title label left constraint
        self.topHeaderLeftConstraint.constant = self.topTitleLeftConstraint - 8
        
        // Code to start animation
        self.view.setNeedsLayout()
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.2, options: [UIViewAnimationOptions.AllowUserInteraction], animations: {
            self.view.layoutIfNeeded()
        }) { (finished) in
            if finished {
                // Code to execute after animation...
            }
        }

    }
    
    
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890 ".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    func removeSpecialCharsFromStringWiki(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890 ,.?!'<>=@/~#$%^&*()-+:;{}[]|`".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    
    func updatePrompt() {
        if self.definitions.count + self.uDLists.count == 0 && self.wikiExtract == "" {
            self.promptLabel.text = "Perhaps one day '\(self.senderText)' will be a searchable word. Today is not that day.. Try another!"
            self.shakeForRandView.hidden = false
        } else {
            if self.prevRand == 1 {
                // vibrate to alert the user some random content is found
//                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
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
    
    

    
    func animateSearchBox() {
        // Set transitions
        if self.topViewHeightConstraint.constant == 150 || self.random == 1 {
            self.searchTextField.alpha = 0
            self.xButton.hidden = true
            self.transitionToSearchIcon()
            self.topViewHeightConstraint.constant = 82
            dismissKeyboard()
        } else {
            self.searchTextField.alpha = 1
            self.topViewHeightConstraint.constant = 150
            self.transitionToSearchIcon()
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
    
    // Makes the search icon a little darker when search bar is expanded
    func transitionToSearchIcon() {
        if self.searchIconDark.alpha == 0 && self.random == 0 {
            self.searchIconDark.alpha = 1
            self.searchIcon.alpha = 0
        } else {
            self.searchIconDark.alpha = 0
            self.searchIcon.alpha = 1
        }
    }
    
    
    
    
    
    
    // MARK: - Table View Prototype Functions ------------------------------------------------------------
   
    // How many cells are we going to need?
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.wikiExtract != "" {
            return self.uDLists.count + self.definitions.count + 1
        } else {
            return self.uDLists.count + self.definitions.count
        }
    }
    
    // How should I create each cell?
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        self.currentRow = indexPath.row
        
        if indexPath.row < self.definitions.count {
        
            
            let cell = tableView.dequeueReusableCellWithIdentifier("myCell") as! CustomDefinitionCell
            
            // Clean HTML string
            var definitionStr = self.definitions[indexPath.row].definition.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
            definitionStr = self.removeSpecialCharsFromStringWiki(definitionStr)
            
            var exampleStr = self.definitions[indexPath.row].example.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
            exampleStr = self.removeSpecialCharsFromStringWiki(exampleStr)
            

            // Set table data
            cell.typeLabel.text = self.definitions[indexPath.row].type
            cell.definitionLabel.text = definitionStr
            cell.exampleLabel.text = exampleStr
            
            
            // Hide sections that have no data
            
            cell.staticExampleLabel.hidden = false // Revert to default settings

            if self.definitions[indexPath.row].example == "" {
                cell.staticExampleLabel.hidden = true
            }
            
            
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

        } else if self.wikiExtract != "" && indexPath.row == self.definitions.count {
            // Wikipedia Extract Prototype Cells
            
            // Dequeue the cell from our storyboard
            let cell = tableView.dequeueReusableCellWithIdentifier("wikiCell") as! CustomWikiCell
            
            // Set custom cell data
            cell.extractLabel.text = self.wikiExtract
            
            // Set custom cell styles
            cell.wikiCellView.layer.cornerRadius = 20
            
            // Set dynamic cell height
            self.definitionTableView.estimatedRowHeight = 80
            self.definitionTableView.rowHeight = UITableViewAutomaticDimension
            
            return cell
            
        } else {
            // Urban Dictionary Prototype Cells

            // Calculate the corresponding index/row for uDLists
            var index = 0
            if self.wikiExtract == "" {
                index = indexPath.row - self.definitions.count
            } else {
                index = indexPath.row - self.definitions.count - 1
            }
            
            // Dequeue the cell from our storyboard
            let cell = tableView.dequeueReusableCellWithIdentifier("urbanCell") as! CustomUrbanCell
            
            // Set custom cell data
            cell.definitionLabel.text = self.uDLists[index].definition
            cell.exampleLabel.text = self.uDLists[index].example
            cell.userLabel.text = self.uDLists[index].author

            
            if self.uDLists[index].score >= 0 {
                cell.scoreLabel.text = "+\(self.uDLists[index].score)"
                cell.scoreLabel.textColor = UIColorFromRGB(0x9A6FF7)
            } else {
                cell.scoreLabel.text = "-\(self.uDLists[index].score)"
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
        if (self.lastContentOffset > scrollView.contentOffset.y && self.isFirstLoad != 1) {
 
            // If the view is scrolled all the way up and the user is still scrolling up. Bring down the search field.
            if scrollView.contentOffset.y < -100 && self.verticalOffset == 0 {

                // Change the verticalOffset variable so the following code does not get executed repeatedly
                self.verticalOffset = 1
              
                // Set changes tp be made in order to bring down search field
                self.topViewHeightConstraint.constant = 150
                self.searchTextField.alpha = 1
                self.searchTextField.text = ""
                self.transitionToSearchIcon()
                
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
                    self.transitionToSearchIcon()

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

