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
//import AVFoundation.AVAudioSession
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
    var synonymsArray = [String]()
    
    var totalRows = 0 // total number of rows in the table (if there is data to show)
    var currentRow = 0 // used for scrolling to a specific row
    var verticalOffset = 0 // used for bringing down search field using scroll action
    var isFirstLoad = 1 // used to disable drag down gesture on first page after app loads
    var random = 0
    var prevRand = 0 // to track if the current displayed word was a random one
    
    
    
    // Similar words variables
    var simSpelledArray = [String]()
    var showSimPrompt = 0
    var searchFromRedirect = 0
    var noSimWords = 0
    
    var hasWiki = 0
    var hasSynonym = 0
    var showSynonymPrompt = 0
    
    
    
    // Audio player
    var player = AVPlayer()
    
    
    // variable to save the last position visited, default to zero
    fileprivate var lastContentOffset: CGFloat = 0
    
    // Cache the baseline top title left constraint for each new word
    var topTitleLeftConstraint: CGFloat = 0
   
    
    
    
    // Original top constraints
    var originalSearchIconTopConstraint: CGFloat = 0
    var originalTopHeaderLabelTopConstraint: CGFloat = 0
    var originalSoundIconTopConstraint: CGFloat = 0
    // MARK: - Outlets -----------------------------------------------------------------------------
    
    
    @IBOutlet weak var topInfoBarBackgroundView: UIView!
    

    
    
    @IBOutlet weak var definitionTableView: UITableView!
    @IBOutlet weak var searchIconTapZone: UIView!
    @IBOutlet weak var searchIcon: UIImageView!
    @IBOutlet weak var searchIconTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchIconDark: UIImageView!
    
    
    
    @IBOutlet weak var topRightTapZone: UIView! // <----------- top right tap zone (not assigned yet)
    @IBOutlet weak var randomIcon: UIImageView!
    
    
    
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var topHeaderLabel: UILabel!
    @IBOutlet weak var topHeaderLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var topHeaderTopConstraint: NSLayoutConstraint!
    
    
    
    
    
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var promptTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var linkView: UIView!
    @IBOutlet weak var linkViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var soundImage: UIImageView!
    @IBOutlet weak var soundImageTopConstraint: NSLayoutConstraint!
   
    @IBOutlet weak var xButton: UIImageView!
    @IBOutlet weak var randomWordIndicator: UILabel!
    
    @IBOutlet weak var shakeForRandView: UIView!
    @IBOutlet weak var shakeForRandLabel: UILabel!
 
    
    // MARK: - Handle Stuff Pressed Functions ---------------------------------------------------
    
    func handleRandomIconTap() {
        // User tapped the random button via the top right tap zone
        self.handleRandTap()
    }
    
     func handleRandTap() {
        self.random = 1
        self.prevRand = 1
       
        self.setTopTitleText("rolling dice..")
        self.topHeaderLabel.textColor = UIColorFromRGB(0xD1D1D1)
        
        
        self.cleanInputString("rand")
    }
    
    func handleSearchIconTap() {
        self.animateSearchBox()
        
        // Stop the scroll movement by scrolling to the nearest row. This prevents the search bar to be hidden repeatedly during auto-scroll.
        if currentRow > 1 {
            self.definitionTableView.scrollToNearestSelectedRow(at: UITableViewScrollPosition.middle, animated: true)
        }

    }
    
    
   
    
    
    
    func handleClearText() {
        
        self.searchTextField.text = ""
        self.xButton.isHidden = true
        
    }
    
    // Function that executes every time the text field is altered
    func textFieldDidChange(_ textField: UITextField) {
        // Do code here when the text field is altered
        self.xButton.isHidden = false
    }
    
    
    
    // Function that executes when the the word shown in the top title label is tapped
    func handleTopTitleLabelTap() {

        // Only play sounds if the search input field is hidden
        if self.searchTextField.alpha == 0 {
            
            // Check if there is a sound url in the Urban Dictionary sounds array
            if self.uDSounds.count > 0 {
           
                // Play the sound if the sound image is gray
                if self.soundImage.image == UIImage(named: "sound") {
                
                    // Right when the sound starts playing, change the color of the sound icon
                    self.soundImage.image = UIImage(named: "soundPlaying")
                
                    // Convert normal string to NSURL String
                    let url : URL = URL(string: self.uDSounds[0])!
                
                    // Create the player item that will play the sound
                    let playerItem = AVPlayerItem(url: url)
                
                    // Set an listener for when the sounds is done playing
                    NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
            
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
            } else {
                // No Urban Dictionary sounds. Play default sound instead.
            
                let wordToSay = self.removeSpecialCharsFromString(self.senderTextDirty)
                self.talkToMe(wordToSay)
            }
            

        } else {
            // Search text input field is shown. Input word tapped into search field instead of playing sound.
            self.searchTextField.text = self.topHeaderLabel.text
        }
    }
    
    
    
    
    func playerDidFinishPlaying(_ note: Notification) {
        
        // When the sound is done playing, change the sound icon back to original
        self.soundImage.image = UIImage(named: "sound")
    }
    
    
    
    @IBAction func handleSearchButtonPressed(_ sender: UITextField) {
        
        // Set top title text for this new input word
        self.setTopTitleText(sender.text!)


        // Clean the input string and then call the APIs
        self.cleanInputString(sender.text!)
    }
    
    
    
    
    
    
    
    // MARK: - NEW HOTNESS API ----------------------------------------------------------------------------------
    
    func callNewHotness(_ cleanString: String) {

        // Hide the rand indicator in case it's not hidden
        if self.randomWordIndicator.isHidden == false {
            self.randomWordIndicator.isHidden = true
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
       
        Alamofire.request(wordsURL, method: .get, parameters: nil, headers: headers).responseJSON { response in   // Words API ---------------------------------------
            
            if let responseArray = response.result.value as? NSDictionary {

                // If Random Word :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                if self.random == 1 {
                    if let randomWord = responseArray["word"] as? String {
                        
                        // Show the random word as the title
                        self.setTopTitleText(randomWord)

                        // Show random word indicator
                        self.randomWordIndicator.isHidden = false
                        
                        self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                        let wikiRand = self.removeSpecialCharsFromString(randomWord)
                        self.senderTextDirty = wikiRand
                        self.senderText = wikiRand.replacingOccurrences(of: " ", with: "")
                    } else {
                        print("404")
                        self.topHeaderLabel.text = "404"
                        self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                    }
                } else {
                    if self.topHeaderLabel.textColor != self.UIColorFromRGB(0x333333) {
                        self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                    }
                } // End If Random Word ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                self.random = 0

                if let results = responseArray["results"] as? [NSDictionary] {
                    
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
                                print("example count <= 0")
                            }
                        }

                        // Clean HTML strings
                        if definitionSave != "" {
                            definitionSave = definitionSave.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                            definitionSave = self.removeSpecialCharsFromStringWiki(definitionSave)
                        }
                        
                        if exampleSave != "" {
                            exampleSave = exampleSave.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                            exampleSave = self.removeSpecialCharsFromStringWiki(exampleSave)
                        }
                        
                        // Cache the data in a global array if the definition is not blank
                        if definitionSave != "" {
                            let dataToInsert = Definition(type: typeSave, definition: definitionSave, example: exampleSave)
                            self.definitions.append(dataToInsert)
                        }
                        

                    } // End for loop
                    
                    // Update UI
                    self.definitionTableView.reloadData()
                    self.callUrbanDictionaryAPI()
                } else {
                    self.definitionTableView.reloadData()
                    self.callUrbanDictionaryAPI()
                }
            } else {
                
                if self.random == 1 {
                    self.random = 0
                    print("warning ---> no random found!!! <--- starting another random search")
                    
                    // If no random found then restart the random search
                    self.handleRandTap()

                }
                
                if self.topHeaderLabel.textColor != self.UIColorFromRGB(0x333333) {
                    self.topHeaderLabel.textColor = self.UIColorFromRGB(0x333333)
                }
                
                self.definitionTableView.reloadData()
                self.callUrbanDictionaryAPI()
            }
        } // END Words API ----------------------------------
    }
    
    
    
    func callUrbanDictionaryAPI() {
        // URBAN DICTIONARY API ------------------------------------------------------------------------------
        
        let cleanString = self.senderText
        let urbanDictionaryURL = "http://api.urbandictionary.com/v0/define?term=\(cleanString)"
        
        Alamofire.request(urbanDictionaryURL, method: .get, parameters: nil, headers: nil)
            .responseJSON { response in
                
                if let res = response.result.value as? NSDictionary{

                    // TAGS
                    if let tags = res["tags"] as? NSArray {
                        for val in tags {
                            self.uDTags.append(val as! String)
                        }
                    } else {
                        print("Warning ---> No Urban Dictionary Tags Data Returned")
                    }
                    
                    // SOUNDS
                    if let sounds = res["sounds"] as? NSArray {
                        for val in sounds {
                            self.uDSounds.append(val as! String)
                            // If there are sounds, then show the sound image.
                            self.soundImage.isHidden = false
                            self.refreshTopTitleConstraint()
                        }
                    } else {
                        print("Warning ---> No Urban Dictionary Sounds Data Returned")
                    }
                    
                    // LIST
                    if let lists = res["list"] as? [NSDictionary] {
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
                        if self.uDLists.count > 1 {
                            self.uDLists.sort { $0.score > $1.score }
                        }

                    } else {
                        print("Warning ---> No Urban Dictionary List Data Returned")
                    }
                    
                    // Update UI
                    self.updatePrompt()

                } else {
                    // Update UI
                    self.updatePrompt()
                }
                
        } // End URBAN DICTIONARY API ------------------------------------------------------------------------------
    }
    
    

    
    // Synonyms API ------------------------------------------------------------------------------------------------
    // This will be called after all the others are completed and displayed ***
    func synonymsAPI() {
        let headers = ["X-Mashape-Key": "MHOVySweXOmsh65XEw8g4ZIbCooup10TJsMjsnK8rElAjjA3JJ"]
        let wordsURL = "https://wordsapiv1.p.mashape.com/words/\(self.senderText)/synonyms"
        Alamofire.request(wordsURL, method: .get, parameters: nil, headers: headers).responseJSON { response in
            if let responseArray = response.result.value as? NSDictionary {
                if let synArray = responseArray["synonyms"] as? NSArray {
                    self.synonymsArray = synArray as! Array // <----------------------------------------- SAVING SYNONYMS HERE!
                    // If no synonyms found the global self.synonymsArray will always default to []
                    
                    // Update UI
                    self.definitionTableView.reloadData()
                }
                else {
                    // Update UI
                    self.definitionTableView.reloadData()
                }
            } else {
                // Update UI
                self.definitionTableView.reloadData()
            }
        }
    } // End Synonyms API Call --------------------------------------------------------------------------------------
    
    
    
    
    
    
    // Similarily Spelled Words API (From IBM) ----------------------------------------------------------------------
    // This will be called after all the others are completed and displayed ***
    func simSpelledAPI() {
        
        // Remove special characters from url string and replace spaces with plus.
        var trimmedString = self.removeSpecialCharsFromString(self.senderTextDirty)
        trimmedString = trimmedString.replacingOccurrences(of: " ", with: "+")
        
        let headers = ["X-Mashape-Key": "MHOVySweXOmsh65XEw8g4ZIbCooup10TJsMjsnK8rElAjjA3JJ"]
        let wordsURL = "https://montanaflynn-spellcheck.p.mashape.com/check/?text=\(trimmedString)"
        
        Alamofire.request(wordsURL, method: .get, parameters: nil, headers: headers).responseJSON { response in
            if let responseArray = response.result.value as? NSDictionary {
                
                if let corrections = responseArray["corrections"] as? NSDictionary {
                
                    for (_, value) in corrections {
                        
                        // If there are suggestion words, save them.
                        var suggestions = [] as Array
                        if let valueArr = value as? NSArray {
                            suggestions = valueArr as Array
                        }
                        
                        if suggestions.count > 0 {

                            for dirtyWord in suggestions {
                                // Clean each word and then compare to trimmedString
                                var notSoDirtyWord = dirtyWord as! String
                                var compareString = trimmedString
                                    
                                // Make all characters lower case
                                notSoDirtyWord = notSoDirtyWord.lowercased()
                                compareString = compareString.lowercased()
                                
                                // Remove all special characters from string
                                notSoDirtyWord = self.removeSpecialCharsFromString(notSoDirtyWord)
                                    
                                // Remove Spaces
//                                notSoDirtyWord = notSoDirtyWord.stringByReplacingOccurrencesOfString(" ", withString: "")
                                
                                // Swift 3.0 version
                                notSoDirtyWord = notSoDirtyWord.trimmingCharacters(in: .whitespaces)
                                
                                
                                    
                                // Only add to the array if the word is different
                                if notSoDirtyWord != compareString {
                                    if var saveWord = dirtyWord as? String {
                                        saveWord = saveWord.lowercased()
                                        self.simSpelledArray.append(saveWord)
                                    }
                                }
                            } // End for loop
                        }
                    } // End for loop

                    if self.simSpelledArray.count == 0 {
                        self.noSimWords = 1
                    }

                    // Update UI
                    self.definitionTableView.reloadData()

                }
                else {
                    self.noSimWords = 1
                    print("no responseArray['corrections']")
                    // Update UI
                    self.definitionTableView.reloadData()
                }

            } else {
                self.noSimWords = 1
                print("no responseArray")
                // Update UI
                self.definitionTableView.reloadData()
            }
        }
    } // End Similarily Spelled Words API Call ----------------------------------------------------------------------
    
    
    
    
    
    
    
    
    
    
    // GHIPHY API test -----------
    func giphyAPI() {
        
        // Someday we'll add some gifs. Maybe..
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - View Did Load ----------------------------------------------------------------
    override func viewDidLoad() {
        

        super.viewDidLoad()
        

        // Motion detect for shake guesture
        self.becomeFirstResponder()
        self.showSimPrompt = 0
        
        
        self.definitionTableView.delegate = self
        self.definitionTableView.dataSource = self
       
        
        
        
        // Set original top constraints
        self.originalSearchIconTopConstraint = 15
        self.originalTopHeaderLabelTopConstraint = 5
        self.originalSoundIconTopConstraint = 17
        
        self.searchIconTopConstraint.constant = self.originalSearchIconTopConstraint
        self.topHeaderTopConstraint.constant = self.originalTopHeaderLabelTopConstraint
        self.soundImageTopConstraint.constant = self.originalSoundIconTopConstraint
        
        
        
        self.view.backgroundColor = UIColorFromRGB(0x00c860)
        
        
        
        // Rounded screen display corners
        self.view.layer.cornerRadius = 8
        self.topInfoBarBackgroundView.layer.cornerRadius = 8
        
        
        self.topHeaderLabel.textColor = UIColorFromRGB(0x333333)
        
        
        
        // Top header left constraint
        self.topHeaderLeftConstraint.constant = (self.view.frame.width / 2) - (self.topHeaderLabel.intrinsicContentSize.width / 2)
        
        
        // Table view styles
        self.definitionTableView.contentInset = UIEdgeInsetsMake(11, 0, 200, 0);
   
        // Hide sound image amoung other things on first load
        self.soundImage.isHidden = true
        self.xButton.isHidden = true
        self.searchIconDark.alpha = 1
        self.searchIcon.alpha = 0
        self.randomWordIndicator.isHidden = true
        
        
        
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
        self.searchTextField.returnKeyType = UIReturnKeyType.search
        self.searchTextField.layer.sublayerTransform = CATransform3DMakeTranslation(20, 2, 0)
        self.searchTextField.becomeFirstResponder()
        
        
        
        
        //Looks for single or multiple taps ----> Used to hide keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        tap.cancelsTouchesInView = false
        
        
        
        // Add guesture action to search icon
        let searchIconTap = UITapGestureRecognizer(target: self, action: #selector(self.handleSearchIconTap))
        self.searchIconTapZone.isUserInteractionEnabled = true
        self.searchIconTapZone.addGestureRecognizer(searchIconTap)
        
        
        // Add guesture action to Top Header Label
        let playSound = UITapGestureRecognizer(target: self, action: #selector(self.handleTopTitleLabelTap))
        self.topHeaderLabel.isUserInteractionEnabled = true
        self.topHeaderLabel.addGestureRecognizer(playSound)
        
        // Add guesture action to X Button
        let clearText = UITapGestureRecognizer(target: self, action: #selector(self.handleClearText))
        self.xButton.isUserInteractionEnabled = true
        self.xButton.addGestureRecognizer(clearText)

        // Add gesture to text field to sense text change
        self.searchTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        
        
        
        // Add guesture action to TOP RIGHT TAP ZONE
        let randomIconTap = UITapGestureRecognizer(target: self, action: #selector(self.handleRandomIconTap))
        self.topRightTapZone.isUserInteractionEnabled = true
        self.topRightTapZone.addGestureRecognizer(randomIconTap)

        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.linkViewBottomConstraint.constant = -400

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("My god.. The memory level on this app is over 9000!!! Quick, do something!")
    }

    // Allows shake gesture to be recognized
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    // Function that executes after shake is detected
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if(event!.subtype == UIEventSubtype.motionShake) {
            //            print("You shook me, now what")
            handleRandTap()
        }
    }
 

    
    
    
    
    
    
    
    // MARK: - Helper Functions ------------------------------------------------------------
    
    func condenseWhiteSpace(_ word: String) -> String {
        let components = word.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    
    
    // Send word data to API.
    func sendPostAPI() {
        let headers = ["secret": "robot"]
        let url = "http://www.worddapp.com/wordSearched"
        
        var wordSave = self.removeSpecialCharsFromString(self.senderTextDirty)
        wordSave = wordSave.lowercased()
        
        var defSave = 0
        var urbanSave = 0
        var bothSave = 0
        
        if self.definitions.count > 0 {
            defSave = 1
        }
        
        if self.uDLists.count > 0 {
            urbanSave = 1
        }
        
        if defSave == 1 && urbanSave == 1 {
            bothSave = 1
        }
        

        
        let parameters: [String: AnyObject] = [
            "word" : wordSave as AnyObject,
            "def" : defSave as AnyObject,
            "urban" : urbanSave as AnyObject,
            "both" : bothSave as AnyObject,
        ]
        
  
//        print(parameters)
        
        
        
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
//            switch(response.result) {
//            case .success(_):
//                if let data = response.result.value{
//                    print(data)
//                }
//                break
//                
//            case .failure(_):
//                print(response.result.error)
//                break
//                
//            }
            
        }
        
        
    }
    
    
    
    
    
    
    func cleanInputString(_ dirty: String) {

        // Move to the top of the table every time a new search is initiated
        self.definitionTableView.contentOffset = CGPoint(x: 0, y: 0 - self.definitionTableView.contentInset.top);
        
        
        
        self.verticalOffset = 0
        
        
        if self.isFirstLoad == 1 {
            self.isFirstLoad = 0
        }
        
        self.dismissKeyboard()
        
        
        self.animateSearchBox()
        
        // Reset searchFromRedirect variable
        self.searchFromRedirect = 0
        
        
        
        self.senderTextDirty = dirty.trimmingCharacters(in: CharacterSet.whitespaces)
        self.senderTextDirty = self.condenseWhiteSpace(self.senderTextDirty)
  
        
        // Clear definition variable
        self.definitions = [Definition]()
        self.uDTags = [String]()
        self.uDSounds = [String]()
        self.uDLists = [uDList]()
        self.promptLabel.isHidden = false
        self.promptLabel.text = "Searching..."
        self.shakeForRandView.isHidden = true
        
        
        self.totalRows = 0
        self.hasWiki = 0
        
        
        
        
        // Reset wikiExtract variable and synonyms array
        self.wikiExtract = ""
        self.synonymsArray = [String]()
        
        
        
        // Reset similarly spelled words variables
        self.simSpelledArray = [String]()
        self.showSimPrompt = 0
        self.noSimWords = 0
        
        
        
        // Reset synonym words variables
        self.hasSynonym = 0
        self.showSynonymPrompt = 0
        
        
        
        
        // Hide sound image on new api call
        self.soundImage.isHidden = true
        
        // Remove spaces from input and create the URL string.
        var trimmedString = dirty.replacingOccurrences(of: " ", with: "")
        
        
        
        
        
        // Set the top title text ::::::::::::::::::::::::::::::::::::::::::::::::
        
        
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
    
    // Default speech synthesizer (siri voice)
    func talkToMe(_ wordToSay: String) {
        
//        print("talking..")
        
        
        
        
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: wordToSay)
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
        
    }
    
    
    func setTopTitleText(_ word: String) {
        var wordToDisplay = word
        
        if word.characters.count > 25 {
            while wordToDisplay.characters.count > 15 {
                wordToDisplay.remove(at: wordToDisplay.characters.index(before: wordToDisplay.endIndex))
            }
            wordToDisplay += ".."
        }
        
        self.topHeaderLabel.text = wordToDisplay
        self.senderText = word
        
        // Cache the title lebel left constraint for future use
        self.topTitleLeftConstraint = (self.view.frame.width / 2) - (self.topHeaderLabel.intrinsicContentSize.width / 2) + 2
        
        // Update the title label left constraint
        self.topHeaderLeftConstraint.constant = self.topTitleLeftConstraint
        
        
    }
    
    
    func refreshTopTitleConstraint() {
        // Update the title label left constraint
        self.topHeaderLeftConstraint.constant = self.topTitleLeftConstraint - 8
        
        // Code to start animation
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.2, options: [UIViewAnimationOptions.allowUserInteraction], animations: {
            self.view.layoutIfNeeded()
        }) { (finished) in
            if finished {
                // Code to execute after animation...
            }
        }

    }
    
    
    
    func removeSpecialCharsFromString(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890 ".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    func removeSpecialCharsFromStringWiki(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890 ,.?!'<>=@/~#$%^&*()-+:;{}[]|`".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    
    func updatePrompt() {
        
        self.promptLabel.isHidden = true
        
        if self.definitions.count + self.uDLists.count == 0 && self.wikiExtract == "" && self.showSimPrompt == 0 {

            // No data to display. Show Similar words list instead.
            self.showSimPrompt = 1
            self.definitionTableView.reloadData()
            
            // Calling the similar word API because there were no results.
            self.simSpelledAPI()
            
        } else {
            if self.prevRand == 1 {
                // vibrate to alert the user some random content is found
//                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        
            if self.showSimPrompt == 0 {
                // There is data to show. Call synonyms API
                self.synonymsAPI()
                self.showSynonymPrompt = 1
            }
            
            self.definitionTableView.reloadData()
            

        }
        
        
        // Send API POST to mongo
        self.sendPostAPI()
    }
    
    
    
    
    // Helper function to set colors with Hex values
    func UIColorFromRGB(_ rgbValue: UInt) -> UIColor {
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
        
        // This is so that scroll down will work again to bring down the search bar
        self.verticalOffset = 0
        
        // Set transitions
        if self.topViewHeightConstraint.constant == 130 || self.random == 1 || self.searchFromRedirect == 1 {

            self.transitionToSearchIcon()
            self.searchTextField.alpha = 0
                
            // If the x button is not hidden, hide it.
            if self.xButton.isHidden == false {
                self.xButton.isHidden = true
            }

            self.topViewHeightConstraint.constant = 75

            self.searchIconTopConstraint.constant = self.originalSearchIconTopConstraint + 8  // <------ new constraint
            self.topHeaderTopConstraint.constant = self.originalTopHeaderLabelTopConstraint + 8
            self.soundImageTopConstraint.constant = self.originalSoundIconTopConstraint + 8
            
            self.randomIcon.alpha = 0
            dismissKeyboard()
            
            
                
        } else {
            self.searchIconTopConstraint.constant = self.originalSearchIconTopConstraint   // <------ new constraint
            self.topHeaderTopConstraint.constant = self.originalTopHeaderLabelTopConstraint
            self.soundImageTopConstraint.constant = self.originalSoundIconTopConstraint

            self.searchTextField.alpha = 1
            self.topViewHeightConstraint.constant = 130
            self.transitionToSearchIcon()
            self.searchTextField.text = ""
            self.randomIcon.alpha = 1
            self.searchTextField.becomeFirstResponder()
        }
     

        // Code to start animation
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.7, options: [UIViewAnimationOptions.allowUserInteraction], animations: {
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
   
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if self.definitions.count + self.uDLists.count == 0 && self.wikiExtract == "" && self.showSimPrompt == 1 {
            
            
            if (indexPath as NSIndexPath).row == 0 {
                return 200
            } else {
                return UITableViewAutomaticDimension
            }

        } else {
            return UITableViewAutomaticDimension
        }
        
        
    }
    
    
    
    
    
    
    // How many cells are we going to need?
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.definitions.count + self.uDLists.count == 0 && self.wikiExtract == "" && self.showSimPrompt == 1 {
            // No results found. Show similarly spelled words.
 
            if self.simSpelledArray.count > 0 {
                // Show similarly spelled words
                return self.simSpelledArray.count + 1
            } else {
                return 1
            }

        } else {
            // At least one result was found and will be displayed. Show synonyms list.
            var rowCount = 0
                
            if self.wikiExtract != "" {
                rowCount += 1
                self.hasWiki = 1
            }
                
            if self.synonymsArray.count > 0 {
                rowCount += synonymsArray.count
                self.hasSynonym = 1
            }

            self.totalRows = self.uDLists.count + self.definitions.count + rowCount
            
            if self.showSynonymPrompt == 1 {
                return self.totalRows + 1 // Add one for synonyms title cell
            } else {
                return self.totalRows
            }

        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // When the user clicks on a table view cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        print("touched")
        
        if self.definitions.count + self.uDLists.count == 0 && self.wikiExtract == "" && self.showSimPrompt == 1 {
            
            // Check to see if the user clicked a similarly spelled word (not the top prompt)
            if self.simSpelledArray.count > 0 && (indexPath as NSIndexPath).row > 0 {
                let index = (indexPath as NSIndexPath).row - 1
                
                if index < self.simSpelledArray.count {
                  
                    self.searchFromRedirect = 1
                    let wordToSearch = self.simSpelledArray[index]
                    
                    // Set top title text for this new input word
                    self.setTopTitleText(wordToSearch)
                    
                    // Clean the input string and then call the APIs
                    self.cleanInputString(wordToSearch)
                    
                } else {
                    print("error ------> index out of range <------ User clicked a similar word")
                }
            }
        } else if self.showSynonymPrompt == 1 && self.synonymsArray.count > 0 {
            
            // Check to see if the user clicked on a row with a synonym word
            if (indexPath as NSIndexPath).row > self.totalRows - self.synonymsArray.count {
              
                let index = (indexPath as NSIndexPath).row - self.definitions.count - self.hasWiki - self.uDLists.count - 1
                
                if index < self.synonymsArray.count {
                    self.searchFromRedirect = 1 // This hides the keyboard and search bar if it's not already hidden
                    let wordToSearch = self.synonymsArray[index]
                    
                    // Set top title text for this new input word
                    self.setTopTitleText(wordToSearch)
                    
                    // Clean the input string and then call the APIs
                    self.cleanInputString(wordToSearch)
                    
                }
            } else {
                print("error ------> index out of range <------ User clicked a synonym word")
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // How should I create each cell?
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        self.currentRow = (indexPath as NSIndexPath).row // Used for scrolling feature
        
        // This is the rare case that no info is found on the given word
        if self.definitions.count + self.uDLists.count == 0 && self.wikiExtract == "" && self.showSimPrompt == 1 {
            

            if (indexPath as NSIndexPath).row == 0 {
                
                // Title cell for the similar words list
                let cell = tableView.dequeueReusableCell(withIdentifier: "spellingTitleCell") as! CustomSpellingTitleCell
                
                // Custom Cell Styling
                cell.titleLabel.textColor = UIColorFromRGB(0x0c743e)
                cell.myContentView.backgroundColor = UIColorFromRGB(0x00c860)
                
                cell.topPromptContentLabel.text = "Perhaps one day '\(self.senderTextDirty)' will return some search results. Today is not that day.. Try another!"
                cell.topPromptContentLabel.textColor = UIColorFromRGB(0x0c743e)
                
                cell.shakeLabel.text = "Shake for Random Word"
                cell.shakeLabel.textColor = UIColorFromRGB(0x00c860)
                
                cell.shakeView.backgroundColor = UIColorFromRGB(0x0c743e)
                cell.shakeView.layer.cornerRadius = cell.shakeView.frame.height / 2

                
                if self.simSpelledArray.count == 0 && self.noSimWords == 0 {
                    cell.titleLabel.text = ""
                } else if self.simSpelledArray.count == 0 && self.noSimWords == 1 {
                    cell.titleLabel.text = "No Similar Words Found.."
                } else {
                    cell.titleLabel.text = "Similarly Spelled Words:"
                }
                
                return cell
                
                
                
            } else {
                
                // Word cell for the similar words list
                let cell = tableView.dequeueReusableCell(withIdentifier: "spellingCell") as! CustomSpellingCell
                
                let index = (indexPath as NSIndexPath).row - 1
                
                // Set table data
                if index < self.simSpelledArray.count {
                    cell.wordLabel.text = self.simSpelledArray[index]
                } else {
                    print("error ------> index out of range <------ Similar Word cell")
                    cell.wordLabel.text = "404"
                }
                
                // Set styling
                cell.wrapperView.layer.cornerRadius = cell.wrapperView.frame.height / 2
                cell.wrapperView.backgroundColor = UIColor.white
                
                // Set dynamic cell height
                self.definitionTableView.estimatedRowHeight = 80
                self.definitionTableView.rowHeight = UITableViewAutomaticDimension
                
                return cell
            }
            
            
            
            
            
            
            
        } else {
            
            
            
            
            
            
            // Info is found. Display the info in various cells.
            
            
            if (indexPath as NSIndexPath).row < self.definitions.count {
                
                // Create cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "myCell") as! CustomDefinitionCell
                
                // Set table data (use extra safeguards so index is never out of range)
                if (indexPath as NSIndexPath).row <= (self.definitions.count - 1) {
                    cell.typeLabel.text = self.definitions[(indexPath as NSIndexPath).row].type
                    cell.definitionLabel.text = self.definitions[(indexPath as NSIndexPath).row].definition
                    cell.exampleLabel.text = self.definitions[(indexPath as NSIndexPath).row].example
                } else {
                    print("error ------> index out of range <------ WordAPI cell")
                    cell.typeLabel.text = "404"
                    cell.definitionLabel.text = ""
                    cell.exampleLabel.text = ""
                }
                
                // Set Custom Definition Cell Styling ::::::::::::::::::::::::::::::::::::::::::
                cell.tableCellView.layer.cornerRadius = 20
                cell.exampleLabel.textColor = UIColorFromRGB(0x00c860)
                
                // Hide sections that have no data
                cell.staticExampleLabel.isHidden = false // Revert to default settings
                if cell.exampleLabel.text == "" {
                    cell.staticExampleLabel.isHidden = true
                }
                
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
                // Set Custom Definition Cell Styling ::::::::::::::::::::::::::::::::::::::: End
                
                return cell
                
            } else if self.wikiExtract != "" && (indexPath as NSIndexPath).row == self.definitions.count {
                
                // Wikipedia Extract Prototype Cells
                let cell = tableView.dequeueReusableCell(withIdentifier: "wikiCell") as! CustomWikiCell
                
                // Set custom table cell data
                cell.extractLabel.text = self.wikiExtract
                
                // Set custom table cell styles
                cell.wikiCellView.layer.cornerRadius = 20
                
                // Set dynamic cell height
                self.definitionTableView.estimatedRowHeight = 80
                self.definitionTableView.rowHeight = UITableViewAutomaticDimension
                
                return cell
                
            } else if (indexPath as NSIndexPath).row > self.definitions.count + self.hasWiki - 1 && (indexPath as NSIndexPath).row < self.totalRows - self.synonymsArray.count {
                
                // Urban Dictionary Prototype Cells
                let cell = tableView.dequeueReusableCell(withIdentifier: "urbanCell") as! CustomUrbanCell
                
                // Calculate the corresponding index/row for uDLists
                var index = -1
                if self.wikiExtract == "" {
                    if self.definitions.count > 0 {
                        index = (indexPath as NSIndexPath).row - self.definitions.count
                    } else {
                        index = (indexPath as NSIndexPath).row
                    }
                } else if self.wikiExtract != "" {
                    if self.definitions.count > 0 {
                        index = (indexPath as NSIndexPath).row - (self.definitions.count + 1)
                    } else {
                        index = (indexPath as NSIndexPath).row - 1
                    }
                }
                
                if index > -1 {
                    // Set custom cell data (using savefguards)
                    if index <= (self.uDLists.count - 1) {
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
                        
                    } else {
                        print("error ------> index out of range <------ Urban Dictionary cell -----> index over range")
                        cell.definitionLabel.text = "Normally a 404 error like this should have crashed the app"
                        cell.exampleLabel.text = "But hey, it didn't crash! :D"
                        cell.userLabel.text = "404"
                        cell.scoreLabel.text = "404"
                    }
                } else {
                    print("error ------> index out of range <------ Urban Dictionary cell ------> index under range")
                    cell.definitionLabel.text = "Normally a 404 error like this should have crashed the app"
                    cell.exampleLabel.text = "But hey, it didn't crash! :D"
                    cell.userLabel.text = "404"
                    cell.scoreLabel.text = "404"
                }
                
                // Set custom cell styles
                cell.urbanCellView.layer.cornerRadius = 20
                cell.exampleLabel.textColor = UIColorFromRGB(0x00c860)
                
                // Set dynamic cell height
                self.definitionTableView.estimatedRowHeight = 80
                self.definitionTableView.rowHeight = UITableViewAutomaticDimension
                
                return cell
                
                
                
            } else if (indexPath as NSIndexPath).row == self.totalRows - self.synonymsArray.count {
                // Synonyms title cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "synonymTitleCell") as! CustomSynonymTitleCell
                
                
                // Set table data
                if self.synonymsArray.count > 0 {
                    cell.titleLabel.text = "Synonyms:"
                } else {
                    cell.titleLabel.text = "No Synonyms Found.."
                }
                
                
                // Styles
                cell.titleLabel.textColor = UIColorFromRGB(0x0c743e)
                
                
                // Set dynamic cell height
                self.definitionTableView.estimatedRowHeight = 80
                self.definitionTableView.rowHeight = UITableViewAutomaticDimension
                
                
                return cell
                
            } else {
            
                // Word cell for the synonym words list
                let cell = tableView.dequeueReusableCell(withIdentifier: "spellingCell") as! CustomSpellingCell
                
                let index = (indexPath as NSIndexPath).row - self.definitions.count - self.hasWiki - self.uDLists.count - 1

                // Set table data
                if index < self.synonymsArray.count {
                    cell.wordLabel.text = self.synonymsArray[index]
                } else {
                    print("error ------> index out of range <------ Synonyms Word cell")
                    cell.wordLabel.text = "404"
                }
                
                // Set styling
                cell.wrapperView.layer.cornerRadius = cell.wrapperView.frame.height / 2
                cell.wrapperView.backgroundColor = UIColor.white
                
                // Set dynamic cell height
                self.definitionTableView.estimatedRowHeight = 80
                self.definitionTableView.rowHeight = UITableViewAutomaticDimension
                
                return cell
                
            }
            
            
            
        }
        
        
        
        
        
        
        
        
        
        
    }
    
    
    
    
    
    // MARK: - Detect SCROLL function -------------------------------------------------------------------------
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.lastContentOffset > scrollView.contentOffset.y && self.isFirstLoad != 1) {
 
            // If the view is scrolled all the way up and the user is still scrolling up. Bring down the search field.
            if scrollView.contentOffset.y < -100 && self.verticalOffset == 0 {

                // Change the verticalOffset variable so the following code does not get executed repeatedly
                self.verticalOffset = 1
              
                // Set changes tp be made in order to bring down search field
     
                
                self.searchIconTopConstraint.constant = self.originalSearchIconTopConstraint   // <------ new constraint
                self.topHeaderTopConstraint.constant = self.originalTopHeaderLabelTopConstraint
                self.soundImageTopConstraint.constant = self.originalSoundIconTopConstraint
                self.searchTextField.alpha = 1
                self.topViewHeightConstraint.constant = 130
                self.transitionToSearchIcon()
                self.searchTextField.text = ""
                
                self.randomIcon.alpha = 1
                

                // Code to start animation
                self.view.setNeedsLayout()
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.2, options: [UIViewAnimationOptions.allowUserInteraction], animations: {
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
            if self.lastContentOffset > 130 {
            
                // Hide the search text field only if its not already hidden
                if self.topViewHeightConstraint.constant != 75 {
                    
                    self.transitionToSearchIcon()
                    self.searchTextField.alpha = 0
                    
                    // If the x button is not hidden, hide it.
                    if self.xButton.isHidden == false {
                        self.xButton.isHidden = true
                    }
                    
                    self.topViewHeightConstraint.constant = 75
                    
                    self.searchIconTopConstraint.constant = self.originalSearchIconTopConstraint + 8  // <------ new constraint
                    self.topHeaderTopConstraint.constant = self.originalTopHeaderLabelTopConstraint + 8
                    self.soundImageTopConstraint.constant = self.originalSoundIconTopConstraint + 8
                    
                    self.randomIcon.alpha = 0
                    dismissKeyboard()
                    
                    
                    // This is so that scroll down will work again
                    self.verticalOffset = 0
                    
                    // Code to start animation
                    self.view.setNeedsLayout()
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [UIViewAnimationOptions.allowUserInteraction], animations: {
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

