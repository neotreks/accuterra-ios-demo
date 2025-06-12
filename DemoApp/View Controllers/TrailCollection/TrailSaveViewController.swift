//
//  TrailSaveViewController.swift
//  DemoApp(Develop)
//
//  Created by Rudolf Kopriva on 3/29/21.
//  Copyright © 2021 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import StarryStars
import AlignedCollectionViewFlowLayout

class TrailSaveViewController: UIViewController {

    // MARK:- Outlets
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var trailNameTextField: UITextField!
    @IBOutlet weak var trailDescriptionTextView: UITextView!
    @IBOutlet weak var difficultyRatingButton: UIButton!
    @IBOutlet weak var difficultyRatingTextView: UITextView!
    @IBOutlet weak var tripTagsCollectionView: UICollectionView!
    @IBOutlet weak var showMoreButton: UIButton!
    @IBOutlet weak var moreView: UIView!
    @IBOutlet weak var highlightsTextField: UITextField!
    @IBOutlet weak var historyTextField: UITextField!
    @IBOutlet weak var campingOptionsTextField: UITextField!
    @IBOutlet weak var permitRequiredSwitch: UISwitch!
    @IBOutlet weak var permitInformationTextField: UITextField!
    @IBOutlet weak var permitInformationLinkTextField: UITextField!
    @IBOutlet weak var accessIssueTextField: UITextField!
    @IBOutlet weak var accessIssueLinkTextField: UITextField!
    @IBOutlet weak var seasonRecommendationTextField: UITextField!
    @IBOutlet weak var seasonRecommendationReasonTextField: UITextField!
    @IBOutlet weak var seasonSpringTextField: UITextField!
    @IBOutlet weak var seasonSummerTextField: UITextField!
    @IBOutlet weak var seasonFallTextField: UITextField!
    @IBOutlet weak var seasonWinterTextField: UITextField!
    @IBOutlet weak var accessConcernCollectionView: UICollectionView!
    @IBOutlet weak var recommendedClearanceTextField: UITextField!
    @IBOutlet weak var bestDirectionTextField: UITextField!
    @IBOutlet weak var privateNoteTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var moreHeightConstraint: NSLayoutConstraint!
    @IBOutlet var inputCollection: [UIView] = [UIView]()
    @IBOutlet var permitControls: [UIView] = [UIView]()

    // MARK:- Properties
    private let TAG = LogTag(subsystem: "ATDemoApp", category: "TrailSaveViewController")
    private var tripService: ITripRecordingService?
    var tripUuid: String?
    private var trip: TripRecording?
    private lazy var poiMedia = [TripRecordingMedia]()
    private lazy var tripMedia = [TripRecordingMedia]()
    private var allMedia: [TripRecordingMedia] {
        get {
            return tripMedia + poiMedia
        }
    }
    private lazy var allTags = [TrailTag]()
    private lazy var selectedTags = Set<TrailTag>()
    private lazy var selectedTagsFromPois = Set<TrailTag>()
    private lazy var poiTags = Set<PoiTag>()
    private lazy var allAccessConcerns = [AccessConcern]()
    private lazy var selectedConcerns = Set<AccessConcern>()
    private var fullScrollHeight: CGFloat = 0
    private var moreViewHeight: CGFloat = 0
    private var techRating: TechnicalRating?
    private var preferredImageUuid: String?
    private lazy var technicalRatings = [TechnicalRating]()
    private var isKeyboardPresent = false
    private var savingTrailDialog: BlockingProgressViewController?
    
    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Save Trail"
        
        self.photoCollectionView.register(UINib(nibName: TripRecordingMediaCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TripRecordingMediaCollectionViewCell.cellIdentifier)
        
        self.tripService = ServiceFactory.getTripRecordingService()
        
        fullScrollHeight = scrollHeightConstraint.constant
        moreViewHeight = moreHeightConstraint.constant
        
        moreHeightConstraint.constant = 0
        scrollHeightConstraint.constant = fullScrollHeight - moreViewHeight
        
        // Handle keyboard show/hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.trailDescriptionTextView.extendToolbar()
        self.difficultyRatingTextView.extendToolbar()
        self.difficultyRatingTextView.text = ""
        
        if let tagsLayout = (tripTagsCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout) {
            tagsLayout.horizontalAlignment = .left
            // Enable automatic cell-sizing with Auto Layout:
            tagsLayout.estimatedItemSize = .init(width: 100, height: 20)
        }
        
        if let concernsLayout = (accessConcernCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout) {
            concernsLayout.horizontalAlignment = .left
            // Enable automatic cell-sizing with Auto Layout:
            concernsLayout.estimatedItemSize = .init(width: 100, height: 20)
        }
        
        setupInputTextFields()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.trip == nil {
            loadTrip()
            tryOrShowError {
                try loadTrailToForm()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK:- Actions

    @IBAction func saveAndUploadPressed() {
        saveTrip(doUpload: true)
    }
    
    @IBAction func permitSwitchChanged() {
        permitControls.forEach { (v) in
            if let c = v as? UITextField {
                c.isEnabled = permitRequiredSwitch.isOn
            } else {
                v.alpha = permitRequiredSwitch.isOn ? 1.0 : 0.5
            }
        }
    }
    
    @IBAction func difficultyRatingPressed() {
        
        tryOrShowError {
            let options = UIAlertController(title: "Difficulty Rating", message: nil, preferredStyle: .actionSheet)
            
            technicalRatings.sorted(by: { (t1, t2) -> Bool in
                t1.level < t2.level
            }).forEach { (t) in
                options.addAction(UIAlertAction(title: "\(t.level): \(t.name)", style: .default, handler: { (action) in
                    self.techRating = t
                    self.difficultyRatingButton.setTitle(t.name, for: .normal)
                }))
            }
            
            options.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(options, animated: false)
            // prevent constraings bug in iOS
            options.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
                return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
            }.first?.isActive = false
        }
    }
    
    @IBAction func showMorePressed() {
        if showMoreButton.isSelected {
            moreHeightConstraint.constant = 0
            scrollHeightConstraint.constant -= moreViewHeight
            showMoreButton.isSelected = false
        } else {
            moreHeightConstraint.constant = moreViewHeight
            scrollHeightConstraint.constant += moreViewHeight
            showMoreButton.isSelected = true
        }
    }
    
    // Close keyboard when tap the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    @objc func onSaveAndUploadClicked() {
        saveTrip(doUpload: true)
    }

    @objc func buttonCancelTapped() {
        self.dismiss(animated: true)
    }

    @objc func buttonActionTapped() {
        let options = UIAlertController(title: "Trail", message: nil, preferredStyle: .actionSheet)

        if canEditTrip() {
            options.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
                self.saveTrip(doUpload: false)
            }))
            options.addAction(UIAlertAction(title: "Save and Upload", style: .default, handler: { (action) in
                self.saveTrip(doUpload: true)
            }))
        }
        options.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action) in
            AlertUtils.showPrompt(viewController: self, title: "Do you really want to delete the trip?", message: "") {
                self.deleteTrip()
            }
        }))
        options.addAction(UIAlertAction(title: "Close without saving", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))


        options.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(options, animated: false)
        // prevent constraings bug in iOS
        options.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
            return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
        }.first?.isActive = false
    }

    // MARK: Keyboard delegate
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }
        if !isKeyboardPresent {
            isKeyboardPresent = true
            scrollHeightConstraint.constant += keyboardSize.height
            scrollView.layoutIfNeeded()
        }

        if let firstResponder = inputCollection.first(where: { (v) -> Bool in
            v.isFirstResponder
        }) {
            scrollView.contentOffset = getScrollOffset(inputControl: firstResponder)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }

        if isKeyboardPresent {
            isKeyboardPresent = false
            scrollHeightConstraint.constant -= keyboardSize.height
            scrollView.layoutIfNeeded()
        }
    }

    // MARK:- IBActions

    @IBAction private func onAddImage() {
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        } else {
            imagePicker.sourceType = .photoLibrary
        }
        imagePicker.delegate = self
        self.present(imagePicker, animated: true)
    }

    @IBAction private func onSelectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true)
    }

    // MARK:- Loaders
    func loadTrip() {
        if let tripService = self.tripService {
            do {
                guard let tripUuid = self.tripUuid else {
                    throw "tripUuid not set".toError()
                }
                guard let trip = try tripService.getTripRecordingByUUID(uuid: tripUuid) else {
                    throw "Trip \(tripUuid) not found".toError()
                }
                self.trip = trip
                self.trailNameTextField.text = trip.tripInfo.name
                self.trailDescriptionTextView.text = trip.tripInfo.description
                self.tripMedia = trip.media
                let tripPois = try tripService.getTripRecordingPOIs(uuid: trip.tripInfo.uuid)
                tripPois.forEach { (poi) in
                    poiMedia.append(contentsOf: poi.media)
                }
                self.technicalRatings = try ServiceFactory.getEnumService().getTechRatings()
                
                setUpNavBar()
            }
            catch {
                showError(error)
            }
        }
    }
    
    private func loadAccessConcerns() {
        tryOrShowError {
            // Load all concerns
            self.allAccessConcerns = try ServiceFactory.getEnumService().getAccessConcerns()
            self.selectedConcerns.removeAll()
        }
    }
    
    private func loadTags() {
        guard let trip = self.trip, let tripService = self.tripService else {
            return
        }
        let enumService = ServiceFactory.getEnumService()
        tryOrShowError {
            // Load all tags
            self.allTags = try enumService.getTrailTags()
            self.selectedTags.removeAll()
            self.selectedTagsFromPois.removeAll()
            trip.tripInfo.tags.forEach({ (tag) in
                self.selectedTags.insert(tag)
            })
            poiTags.removeAll()
            let tripPois = try tripService.getTripRecordingPOIs(uuid: trip.tripInfo.uuid)
            try tripPois.forEach { (poi) in
                try poi.tags.forEach { (tag) in
                    if let corespondingTrailTag = try enumService.getCorrespondingTrailTag(poiTag: tag), corespondingTrailTag.type == .TRIP_AND_TRAIL {
                        self.selectedTags.insert(corespondingTrailTag)
                        self.selectedTagsFromPois.insert(corespondingTrailTag)
                    }
                }
            }
        }
    }

    // MARK:-
    func setUpNavBar() {
        
        // Right button
        if self.canEditTrip() {
            let buttonSave = UIBarButtonItem(image: UIImage(named: "context.menu"), style: .done, target: self, action: #selector(self.buttonActionTapped))
            buttonSave.tintColor = UIColor.Active
            self.navigationItem.rightBarButtonItem = buttonSave
        }
        
        // Left button
        let actionButton = UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .done, target: self, action: #selector(self.buttonActionTapped))
        
        self.navigationItem.leftBarButtonItem = actionButton
    }
    
    private func setupInputTextFields(){
        let capSentences = UITextAutocapitalizationType.sentences
        
        self.trailNameTextField.autocapitalizationType = capSentences
        self.trailDescriptionTextView.autocapitalizationType = capSentences
        self.difficultyRatingTextView.autocapitalizationType = capSentences
        self.highlightsTextField.autocapitalizationType = capSentences
        self.historyTextField.autocapitalizationType = capSentences
        self.campingOptionsTextField.autocapitalizationType = capSentences
        self.permitInformationTextField.autocapitalizationType = capSentences
        self.permitInformationLinkTextField.autocapitalizationType = capSentences
        self.accessIssueTextField.autocapitalizationType = capSentences
        self.accessIssueLinkTextField.autocapitalizationType = capSentences
        self.seasonRecommendationTextField.autocapitalizationType = capSentences
        self.seasonRecommendationReasonTextField.autocapitalizationType = capSentences
        self.seasonSummerTextField.autocapitalizationType = capSentences
        self.seasonFallTextField.autocapitalizationType = capSentences
        self.seasonWinterTextField.autocapitalizationType = capSentences
        self.recommendedClearanceTextField.autocapitalizationType = capSentences
        self.bestDirectionTextField.autocapitalizationType = capSentences
        self.privateNoteTextField.autocapitalizationType = capSentences
    }
    
    private func deleteTrip() {
        do {
            guard let tripUuid = trip?.tripInfo.uuid else {
                throw "Cannot get the trip UUID".toError()
            }
            
            // It is recommended to use the [ITripService.deleteTrip] method.
            // In case the trip is actually recoded, it is possible to use
            // also the [ITripRecorder.deleteTrip] method.
            let service = ServiceFactory.getTripRecordingService()
            try service.deleteTripRecording(uuid: tripUuid)
            
            // Close this view controller
            self.dismiss(animated: true)
        } catch {
            showError(error)
        }
    }
    
    private func showTrailSavingDialog() {
        if let dialog = AlertUtils.buildBlockingProgressValueDialog() {
            dialog.title = "Saving trail..."
            dialog.style = .loadingIndicator
            self.present(dialog, animated: false, completion: nil)
            savingTrailDialog = dialog
        }
    }
    
    private func saveTrip(doUpload: Bool) {
        guard var trip = self.trip, let tripService = self.tripService else {
            return
        }
        
        guard validateForm() else {
            return
        }
        
        showTrailSavingDialog()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.handleTrailUploadAndSave(doUpload: doUpload, trip: &trip, tripService: tripService)
        }
    }
    
    private func requestNotificationAuthorization(handler: @escaping ((Bool)->Void)) {
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.requestAuthorization(options: authOptions) { (success, error) in
            DispatchQueue.main.async {
                handler(error == nil)
            }
        }
    }
    
    private func handleTrailUploadAndSave(doUpload: Bool, trip: inout TripRecording, tripService: ITripRecordingService) {
        do {
            // Load one for the camping types
            let enumService = ServiceFactory.getEnumService()
            let campingType = try enumService.getCampingTypeByCode(SdkCampingType.DISPERSED.rawValue)
            
            // Update the trip with gathered data
            trip.tripInfo.name = trailNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            trip.tripInfo.description = trailDescriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            trip.tripInfo.campingTypes = [campingType]
            trip.tripInfo.tags = Array(selectedTags)
            if let techRating = techRating, let technicalRating = technicalRatings.filter({ $0.level == techRating.level }).first {
                trip.tripInfo.technicalRating = TripTechRating(low: nil, high: technicalRating, summary: technicalRating.description)
            }
            
            // Add dummy data for now
            let rating: Float? = nil
            let sharingType = TripSharingType.PRIVATE
            let promote = true
            
            trip.userInfo.userRating = rating
            trip.userInfo.sharingType = sharingType
            trip.userInfo.promoteToTrail = promote
            
            guard let trailCollectionData = buildTrailCollectionData() else {
                throw "Could not build trail collection data".toError()
            }

            // Media
            let tripMedia = ApkMediaUtil.updatePositions(allMedia: self.tripMedia)
            
            // Copy gathered data
            trip.media = tripMedia
            trip.extProperties = try ExtPropertiesBuilder.buildList(value: trailCollectionData)

            // Safe Trip Data into the DB
            
            trip = try tripService.updateTripRecording(tripRecording: trip)
            
            savingTrailDialog?.dismiss(animated: false, completion: {[weak self] in
                self?.savingTrailDialog = nil
            })
            
            let tripUUid = trip.tripInfo.uuid
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if doUpload {
                    self.requestNotificationAuthorization(handler: {_ in
                        // Upload the recorded trip to the server
                        try? self.uploadTrail(uuid: tripUUid, handler: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    })
                }
                else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        catch {
            Log.e(TAG, "Could not save trail. \(error.localizedDescription)")
            savingTrailDialog?.dismiss(animated: false, completion: {[weak self] in
                self?.savingTrailDialog = nil
                self?.showError(error)
            })
        }
    }
    
    private func uploadTrail(uuid: String, handler: @escaping (()->Void)) throws {
        guard let service = self.tripService else {
            return
        }
        try service.uploadTripRecordingToServer(uuid: uuid)
        if NetworkUtils.shared.isOnline() {
            showInfo("The collected trail was saved on device and will be uploaded to the server. Please keep the application running.", handler)
        }
        else {
            showInfo("The collected trail was saved on device and will be uploaded to the server when internet connection is available.", handler)
        }
    }
    
    /// Adds captured photo into the POI
    private func addMedia(image: UIImage) throws {
        tripMedia.append(try TripRecordingMedia.buildFromData(image: image))
        
        self.photoCollectionView.reloadData()
    }

    private func deleteMedia(media: TripRecordingMedia, index: Int) {
        if index != -1 && index < tripMedia.count {
            tripMedia.remove(at: index)
        }
        photoCollectionView.reloadData()
    }
    
    private func canEditTrip() -> Bool {
        return self.trip?.isEditable() ?? false
    }
    
    private func loadTrailToForm() throws {
        guard let trip = self.trip else {
            return
        }
        // Load access concern spinner
        loadAccessConcerns()
        loadTags()
        // Bind values
        trailNameTextField.text = trip.tripInfo.name
        trailDescriptionTextView.text = trip.tripInfo.description
        
        
        if let data = trip.extProperties.first?.data, let trailCollectionData: TrailCollectionData = try data.decode() {
            // Main Custom data
            // For Trail collection we define just one value
            let techRatingLow = trailCollectionData.difficultyRating ?? 1
            techRating = technicalRatings.first(where: { (t) -> Bool in
                return t.level == techRatingLow
            })
            
            if let ratingName = techRating?.name {
                difficultyRatingButton.setTitle(ratingName, for: .normal)
            }
            
            difficultyRatingTextView.text = trailCollectionData.difficultyDescription
            
            // Optional: Basic
            highlightsTextField.text = trailCollectionData.highlights
            historyTextField.text = trailCollectionData.history
            campingOptionsTextField.text = trailCollectionData.campingOptions
            
            // Optional: Permit
            permitRequiredSwitch.isOn = trailCollectionData.permitRequired
            
            permitSwitchChanged()
            
            permitInformationTextField.text = trailCollectionData.permitInformation
            permitInformationLinkTextField.text = trailCollectionData.permitInformationLink
            accessIssueTextField.text = trailCollectionData.accessIssue
            accessIssueLinkTextField.text = trailCollectionData.accessIssueLink
            
            // Optional: Season
            seasonRecommendationTextField.text = trailCollectionData.seasonalityRecommendation
            seasonRecommendationReasonTextField.text = trailCollectionData.seasonalityRecommendationReason
            seasonSpringTextField.text = trailCollectionData.seasonSpring
            seasonSummerTextField.text = trailCollectionData.seasonSummer
            seasonFallTextField.text = trailCollectionData.seasonFall
            seasonWinterTextField.text = trailCollectionData.seasonWinter
            
            // Optional: Other
            selectedConcerns.removeAll()
            for concernCode in trailCollectionData.accessConcernCodes {
                if let entry = allAccessConcerns.first(where: { (a) -> Bool in
                    return a.code == concernCode
                }) {
                    selectedConcerns.insert(entry)
                } else {
                    let knownCodes = allAccessConcerns.map { (t) -> String in
                        t.code
                    }
                    throw "Cannot find concern code: \(concernCode), known codes: \(knownCodes)".toError()
                }
                
                if let clearance = trailCollectionData.recommendedClearance {
                    recommendedClearanceTextField.text = "\(clearance.fromMetersToInches())"
                }
                
                bestDirectionTextField.text = trailCollectionData.bestDirection
                // Preferred image
                preferredImageUuid = trailCollectionData.preferredImageUuid
            }
        }
        
        photoCollectionView.reloadData()
        tripTagsCollectionView.reloadData()
        accessConcernCollectionView.reloadData()
    }
    
    private func buildTrailCollectionData() -> TrailCollectionData? {
        guard let technicalRating = self.techRating else {
            return nil
        }
        let permitOn = permitRequiredSwitch.isOn
        var recommendedClearance: Float? = nil
        if let recommendedClearanceValue = recommendedClearanceTextField.text {
            recommendedClearance = Float(recommendedClearanceValue)?.fromInchesToMeters()
        }
        
        return TrailCollectionData(
            // Mandatory
            // For Trail collection we gather just one value and not low/high values
            difficultyRating: technicalRating.level,
            difficultyDescription: difficultyRatingTextView.text,
            // Optional: Basic
            highlights: highlightsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            history: historyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            campingOptions: campingOptionsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            // Optional: Permit
            permitRequired: permitOn,
            permitInformation: permitOn ? permitInformationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            permitInformationLink: permitOn ? permitInformationLinkTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            accessIssue: permitOn ? accessIssueTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            accessIssueLink: permitOn ? accessIssueLinkTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            // Optional: Other
            accessConcernCodes: selectedConcerns.map({ (a) -> String in
                return a.code
            }),
            recommendedClearance: recommendedClearance,
            bestDirection: bestDirectionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            // Optional: Season
            seasonalityRecommendation: seasonRecommendationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            seasonalityRecommendationReason: seasonRecommendationReasonTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            seasonSpring: seasonSpringTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            seasonSummer: seasonSummerTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            seasonFall: seasonFallTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            seasonWinter: seasonWinterTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            preferredImageUuid: preferredImageUuid)
    }
    
    private func validateForm() -> Bool {
        let trailCollectionData = buildTrailCollectionData()
        
        if trailNameTextField.text?.count ?? 0 < 3 {
            showError("Please provide a trail name of at least 3 character long.".toError())
            scrollToControl(inputControl: self.trailNameTextField)
            return false
        }
        else if trailDescriptionTextView.text.count < 10 {
            showError("Please provide a description text of at least 10 characters long.".toError())
            scrollToControl(inputControl: self.trailDescriptionTextView)
            return false
        } else if techRating == nil {
            showError("Please select difficulty rating.".toError())
            scrollToControl(inputControl: self.difficultyRatingButton)
            return false
        } else if trailCollectionData == nil {
            showError("cannot load trail collection data.".toError())
            return false
        } else if difficultyRatingTextView.text?.count ?? 0 < 10 {
            showError("Please provide a description text of at least 10 characters long.".toError())
            scrollToControl(inputControl: self.difficultyRatingTextView)
            return false
        } else if let seasonalityRecommendationText = self.seasonRecommendationTextField.text, !seasonalityRecommendationText.isEmpty, seasonalityRecommendationText.count != 12 {
            showError("Seasson recommendation must have exactly 12 characters (0 or 1).".toError())
            scrollToControl(inputControl: self.seasonRecommendationTextField)
            return false
        }

        return true
    }
    
    private func scrollToControl(inputControl: UIView) {
        scrollView.setContentOffset(getScrollOffset(inputControl: inputControl), animated: true)
    }
    
    private func getScrollOffset(inputControl: UIView) -> CGPoint {
        let maxScrollOffset = scrollView.contentSize.height - scrollView.frame.height
        
        var offset = inputControl.frame.minY
        var superView = inputControl.superview
        while superView != nil && superView! != self.scrollView {
            offset += superView!.frame.minY
            superView = superView?.superview
        }
        offset -= 40
        return CGPoint(x: 0, y: max(0, min(offset, maxScrollOffset)))
    }
}

extension TrailSaveViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == photoCollectionView {
            return allMedia.count
        } else if collectionView == tripTagsCollectionView {
            return allTags.count
        } else if collectionView == accessConcernCollectionView {
            return allAccessConcerns.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == photoCollectionView {
            let media = allMedia[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TripRecordingMediaCollectionViewCell.cellIdentifier, for: indexPath) as! TripRecordingMediaCollectionViewCell
            cell.bindView(media: media, mediaIndex: indexPath.row, isPreferred: media.uuid == self.preferredImageUuid, delegate: self)
            return cell
        } else if collectionView == tripTagsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "poiTagCell", for: indexPath) as! PoiTagCollectionViewCell
            let tag = self.allTags[indexPath.row]
            let selected = self.selectedTags.contains { (t) -> Bool in
                return t.code == tag.code
            }
            cell.bindView(tag: tag, selected: selected)
            return cell
        } else if collectionView == accessConcernCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "accessConcernCell", for: indexPath) as! AccessConcernCollectionViewCell
            let concern = self.allAccessConcerns[indexPath.row]
            let selected = self.selectedConcerns.contains { (c) -> Bool in
                return c.code == concern.code
            }
            cell.bindView(concern: concern, selected: selected)
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.photoCollectionView {
            let media = self.allMedia[indexPath.row]
            if let preferredImageUuid = self.preferredImageUuid, media.uuid == preferredImageUuid {
                self.preferredImageUuid = nil
            } else {
                self.preferredImageUuid = media.uuid
            }
            photoCollectionView.reloadData()
        }
        else if collectionView == self.tripTagsCollectionView {
            let tag = self.allTags[indexPath.row]
            if selectedTagsFromPois.contains(tag) {
                // Ignore tags that we selected on poi screen
                return
            }
            
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
            
            collectionView.reloadData()
        } else if collectionView == self.accessConcernCollectionView {
            let accessConcern = self.allAccessConcerns[indexPath.row]
            
            if selectedConcerns.contains(accessConcern) {
                selectedConcerns.remove(accessConcern)
            } else {
                selectedConcerns.insert(accessConcern)
            }
            
            collectionView.reloadData()
        }
    }
}

extension TrailSaveViewController : TripRecordingMediaCollectionViewCellDelegate {
    func tripMediaDeletePressed(media: TripRecordingMedia, index: Int) {
        deleteMedia(media: media, index: index)
    }
    
    func canEditMedia(media: TripRecordingMedia) -> Bool {
        return canEditTrip() && tripMedia.contains(where: { (m) -> Bool in
            return m.uuid == media.uuid
        })
    }
}

extension TrailSaveViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        
        if picker.sourceType == .camera {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        
        do {
            try addMedia(image: image)
        } catch {
            showError(error)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

extension TrailSaveViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField.returnKeyType == .next, let nextControl = textField.superview?.viewWithTag(textField.tag + 1), nextControl.canBecomeFirstResponder {
            nextControl.becomeFirstResponder()
        }
        return true
    }
}


extension TrailSaveViewController: UITextViewDelegate {
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if let nextControl = textView.superview?.viewWithTag(textView.tag + 1), nextControl.canBecomeFirstResponder {
                nextControl.becomeFirstResponder()
            }
        }
        return true
    }
}
