//
//  SaveTripViewController.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 6/3/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import StarryStars

class SaveTripViewController: UIViewController {
    
    private let TAG = "SaveTripViewController"

    @IBOutlet weak var txtTripName: UITextField!    
    @IBOutlet weak var txtTripDescription: UITextField!
    @IBOutlet weak var txtPersonalNote: UITextField!
    @IBOutlet weak var buttonShareWith: UIButton!
    @IBOutlet weak var ratingStars: RatingView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet var editViewsCollection: [UIView] = [UIView]()
    @IBOutlet weak var promoteSwitch: UISwitch!
    
    var tripService: ITripRecordingService?
    var tripUuid: String?
    var trip: TripRecording?
    var activeTextField: UITextField? = nil
    var shareWith: (type: TripSharingType, description: String)?
    private lazy var media = [TripRecordingMedia]()
    
    let shareWithOptions: [(type: TripSharingType, description: String)] = [
        (.PRIVATE, "No one (keep private)"),
        (.FRIENDS_ONLY, "Friends only"),
        (.PUBLIC, "Everyone (make public)")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Save Trip"
        
        self.photoCollectionView.register(UINib(nibName: TripMediaCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TripMediaCollectionViewCell.cellIdentifier)
        
        self.tripService = ServiceFactory.getTripRecordingService()
        
        txtTripName.delegate = self
        txtTripDescription.delegate = self
        txtPersonalNote.delegate = self
        
        self.shareWith = shareWithOptions.first!
        self.updateShareWithButton()
        
        loadTrip()
        
        // Handle keyboard show/hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self.view.window)
    }
    
    // Close keyboard when tap the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func loadTrip() {
        if let tripService = self.tripService {
            do {
                guard let tripUuid = self.tripUuid else {
                    throw "tripUuid not set".toError()
                }
                guard let trip = try tripService.getTripByUUID(uuid: tripUuid) else {
                    throw "Trip \(tripUuid) not found".toError()
                }
                self.trip = trip
                self.txtTripName.text = trip.tripInfo.name
                self.txtTripDescription.text = trip.tripInfo.description
                self.media = trip.media
                
                self.shareWith =  self.shareWithOptions.first(where: { (o) -> Bool in
                    return o.type == trip.userInfo.sharingType
                })
                updateShareWithButton()
                
                self.ratingStars.rating = Float(trip.userInfo.userRating ?? 0)
                
                self.txtPersonalNote.text = trip.userInfo.personalNote
                
                self.txtTripName.becomeFirstResponder()
                
                self.photoCollectionView.reloadData()
                
                setUpNavBar()
                
                if !canEditTrip() {
                    self.editViewsCollection.forEach { (view) in
                        (view as? UIButton)?.isEnabled = false
                        view.isUserInteractionEnabled = false
                    }
                }
            }
            catch {
                showError(error)
            }
        }
    }

    func setUpNavBar() {
        
        // Right button
        if self.canEditTrip() {
            let buttonSave = UIBarButtonItem(title: "Save and Upload", style: .done, target: self, action: #selector(self.onSaveAndUploadClicked))
            buttonSave.tintColor = UIColor.Active
            self.navigationItem.rightBarButtonItem = buttonSave
        } else {
            let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.buttonCancelTapped))
            backButton.tintColor = UIColor.Active
            self.navigationItem.rightBarButtonItem = backButton
        }
        
        // Left button
        let actionButton = UIBarButtonItem(title: "≡", style: .done, target: self, action: #selector(self.buttonActionTapped))
        
        self.navigationItem.leftBarButtonItem = actionButton
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
            try service.deleteTrip(tripUuid: tripUuid)
            
            // Close this view controller
            self.dismiss(animated: true)
        } catch {
            showError(error)
        }
    }
    
    @objc func onSaveAndUploadClicked() {
        saveTrip(doUpload: true)
    }
    
    private func saveTrip(doUpload: Bool) {
        guard let shareWith = self.shareWith else {
            return
        }
        do {
            if let tripService = self.tripService, let trip = self.trip {
                let name = txtTripName?.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let description = txtTripDescription?.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let personalNote = txtPersonalNote?.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                let enumService = ServiceFactory.getEnumService()
                let campingType = try enumService.getCampingTypeByCode(SdkCampingType.DISPERSED.rawValue)
                
                let tripInfo = trip.tripInfo.copy(name: name, description: description, campingTypes: [campingType])
                let userInfo = trip.userInfo.copy(userRating: Double(self.ratingStars.rating), sharingType: shareWith.type, promoteToTrail: self.promoteSwitch.isOn, personalNote: personalNote)
                
                // Media
                let allMedia = SaveTripViewController.updatePositions(allMedia: media)
                
                if let trip = self.trip?.copy(info: tripInfo, userInfo: userInfo, media: allMedia) {
                    let _ = try tripService.updateTrip(trip: trip)
                    if doUpload {
                        try tripService.uploadTripToServer(tripUuid: trip.tripInfo.uuid)
                    }
                    self.dismiss(animated: true)
                }
                else {
                    showError("Could not save trip.".toError())
                }
            }
        }
        catch {
            Log.e(TAG, "Could not save trip. \(error.localizedDescription)")
            showError(error)
        }
    }
    
    /// This is not mandatory. Media position is an optional field. If not set, then media
    /// are ordered naturally in the same order as there were created.
    ///
    /// But it is possible to set the order of media to change the natural ordering.
    private static func updatePositions(allMedia: [TripRecordingMedia]) -> [TripRecordingMedia] {
        var position = 1
        var ordered = [TripRecordingMedia]()
        for media in allMedia {
            ordered.append(
                // Set the optional position value
                media.copy(position: position)
            )
            position += 1
        }
        return ordered
    }
    
    /// Adds captured photo into the POI
    private func addMedia(image: UIImage) throws {
        media.append(try TripRecordingMedia.buildFromData(image: image))
        
        self.photoCollectionView.reloadData()
    }

    private func deleteMedia(media: TripRecordingMedia) {
        self.media.removeAll { (it: TripRecordingMedia) -> Bool in it.pk == media.pk }
        self.photoCollectionView.reloadData()
    }
    
    private func canEditTrip() -> Bool {
        return self.trip?.isEditable() ?? false
    }

    private func shuffleMedia() {
        media.shuffle()
        self.photoCollectionView.reloadData()
    }

    @IBAction private func onAddImage() {
        let imagePicker = UIImagePickerController()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        } else {
            imagePicker.sourceType = .photoLibrary
        }
        imagePicker.delegate = self
        self.navigationController?.pushViewController(imagePicker, animated: true)
    }

    @IBAction private func onSelectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true)
    }
    
    @objc func buttonCancelTapped() {
        self.dismiss(animated: true)
    }
    
    @objc func buttonActionTapped() {
        let options = UIAlertController(title: "Trip", message: nil, preferredStyle: .actionSheet)
        
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
    
    @IBAction func buttonShareWithTapped(_ sender: Any) {
        view.endEditing(true)
        showShareWithOptions()
    }
    
    func showShareWithOptions() {
        let options = UIAlertController(title: "Share With", message: nil, preferredStyle: .actionSheet)
        
        for option in shareWithOptions {
            options.addAction(UIAlertAction(title: option.description, style: .default, handler: { (action) in
                self.shareWith = option
                self.updateShareWithButton()
            }))
        }
        
        options.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(options, animated: true)
        // prevent constraings bug in iOS
        options.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
          return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
        }.first?.isActive = false
    }
    
    func updateShareWithButton() {
        guard let shareWith = self.shareWith else {
            return
        }
        buttonShareWith.setTitle(shareWith.description, for: .normal)
    }
    
    // MARK: Keyboard delegate
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
          // if keyboard size is not available for some reason, dont do anything
          return
        }

        var shouldMoveViewUp = false

        // if active text field is not nil
        if let activeTextField = activeTextField {

          let bottomOfTextField = activeTextField.convert(activeTextField.bounds, to: self.view).maxY;
          
          let topOfKeyboard = self.view.frame.height - keyboardSize.height

          // if the bottom of Textfield is below the top of keyboard, move up
          if bottomOfTextField > topOfKeyboard {
            shouldMoveViewUp = true
          }
        }

        if(shouldMoveViewUp) {
          self.view.frame.origin.y = 0 - keyboardSize.height
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}

extension SaveTripViewController : UITextFieldDelegate {
    // when user select a textfield, this method will be called
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // set the activeTextField to the selected textfield
        self.activeTextField = textField
    }

    // when user click 'done' or dismiss the keyboard
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
    }
}

extension SaveTripViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TripMediaCollectionViewCell.cellIdentifier, for: indexPath) as! TripMediaCollectionViewCell
        cell.setup(media: media[indexPath.row], delegate: self)
        return cell
    }
}

extension SaveTripViewController : TripMediaCollectionViewCellDelegate {
    func tripMediaDeletePressed(media: TripRecordingMedia) {
        deleteMedia(media: media)
    }
    func canEditMedia() -> Bool {
        return canEditTrip()
    }
}

extension SaveTripViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        
        do {
            try addMedia(image: image)
        } catch {
            showError(error)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

