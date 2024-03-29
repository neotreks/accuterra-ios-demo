//
//  TripPoiViewController.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 16/10/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import CoreLocation
import AccuTerraSDK

class TripPoiViewController: UIViewController {

    // MARK:- Properties
    private let TAG = "TripPoiViewController"
    private var mapLocation: MapLocation?
    private var trip: TripRecording?
    private lazy var media = [TripRecordingMedia]()
    private lazy var types = [PointType]()
    private var poi: TripRecordingPoi?

    // MARK:- Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var poiTypeButton: UIButton!

    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.photoCollectionView.register(UINib(nibName: TripRecordingMediaCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TripRecordingMediaCollectionViewCell.cellIdentifier)
        
        setupTextFields()
        
        if let loadedPoi = self.poi {
            self.title = "Edit POI"
            var rightBarButtons = [UIBarButtonItem]()
            rightBarButtons.append(UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(onSaveClicked)))
            if trip?.isEditable() ?? false {
                rightBarButtons.append(UIBarButtonItem(title: "Delete", style: .done, target: self, action: #selector(onPoiDeleteClicked)))
            }
            self.navigationItem.rightBarButtonItems = rightBarButtons
            
            self.nameTextField.text = loadedPoi.name
            self.descriptionTextView.text = loadedPoi.description
            let type = self.types.first { (it: PointType) -> Bool in
                return it.code == loadedPoi.pointType.code
            }
            self.poiTypeButton.setTitle(type?.name, for: .normal)
            
            self.photoCollectionView.reloadData()
        } else {
            poiTypeButton.setTitle(self.types.first!.name, for: .normal)
            self.title = "Add POI"
            self.nameTextField.text = "Trip POI"
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(onSaveClicked))
        }
    }

    // MARK:- Loaders
    func createNewWithLocation(location: CLLocation) throws {
        let tripService = try ServiceFactory.getTripRecorder()
        guard let trip = try tripService.getActiveTripRecording() else {
            throw "There is no currently recorded trip!".toError()
        }
        self.mapLocation = MapLocation(latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude)
        self.trip = trip
        
        let enumService = ServiceFactory.getEnumService()
        let types = try enumService.getPointTypes()
        self.types = Array(types.sorted { (a, b) -> Bool in
            a.name.compare(b.name) == ComparisonResult.orderedAscending
        })
    }
    
    func loadSaved(poiUuid: String) throws {
        let tripService = ServiceFactory.getTripRecordingService()
        guard let loadedPoi = try tripService.getTripRecordingPoiByUuid(uuid: poiUuid) else {
            throw "Cannot find POI by uuid: \(poiUuid)".toError()
        }
        
        self.poi = loadedPoi
        self.mapLocation = loadedPoi.mapLocation
        
        // Init also the `this.media` for easier manipulation
        media = loadedPoi.media
        // Load trip to get it's status
        self.trip = try tripService.getTripRecordingByPoiUuid(uuid: poiUuid)
        
        let enumService = ServiceFactory.getEnumService()
        let types = try enumService.getPointTypes()
        self.types = Array(types.sorted { (a, b) -> Bool in
            a.name.compare(b.name) == ComparisonResult.orderedAscending
        })
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

    @IBAction func buttonPoiTypeTapped(_ sender: Any) {
        view.endEditing(true)
        showTypeOptions()
    }

    // MARK:- Actions
    @objc private func onSaveClicked() {

        guard let mapLocation = self.mapLocation else {
            return
        }

        do {
            let enumService = ServiceFactory.getEnumService()

            // Gather POI data
            let name = nameTextField.text ?? "Trip POI"
            let description = descriptionTextView.text
            let selectedPointType = types.first(where: { (t:PointType) -> Bool in
                return t.name == poiTypeButton.currentTitle!
            })!
            let pointType = selectedPointType

            if let existingPoi = self.poi {
                // Update existing Poi
                media = ApkMediaUtil.updatePositions(allMedia: media)
                let poi = existingPoi.copy(
                    name: name,
                    description: description,
                    descriptionShort: nil,
                    pointType: pointType,
                    media: media
                )
                // Update POI
                try self.updatePoi(poi: poi)
            } else {
                // Build the new POI
                let poi = try TripRecordingPoi.buildNewPoi(
                    name: name,
                    mapLocation: mapLocation,
                    pointTypeCode: pointType.code,
                    enumService: enumService,
                    description: description,
                    descriptionShort: nil,
                    media: self.media
                )

                // Add the newly created POI to the trip recording
                try addPoi(poi: poi)
            }

            // Close the dialog
            self.navigationController?.popViewController(animated: true)
        } catch {
            showError(error)
        }
    }

    @objc private func onPoiDeleteClicked() {
        AlertUtils.showPrompt(viewController: self, title: "Delete POI", message: "Do you really want to delete this POI?") {
            do {
                let tripRecorder = try ServiceFactory.getTripRecorder()
                try tripRecorder.deletePoi(poiUuid: self.poi!.uuid)
                // Close the dialog and return
                self.navigationController?.popViewController(animated: true)
            } catch {
                self.showError(error)
            }
        } cancelHandler: {
        }
    }

    /// Add the newly created POI to the trip recording
    private func addPoi(poi: TripRecordingPoi) throws {
        let recorder = try ServiceFactory.getTripRecorder()
        let _ = try recorder.addPoi(poi: poi)
    }
    
    private func setupTextFields() {
        let capSentences = UITextAutocapitalizationType.sentences
        self.nameTextField.autocapitalizationType = capSentences
        self.descriptionTextView.autocapitalizationType = capSentences
    }

    // MARK:- POI

    /// Update existing POI in the trip recording
    private func updatePoi(poi: TripRecordingPoi) throws {
        let recorder = try ServiceFactory.getTripRecorder()
        let _ = try recorder.updatePoi(poi: poi)
    }

    func showTypeOptions() {
        let options = UIAlertController(title: "POI Type", message: nil, preferredStyle: .actionSheet)

        for option in types {
            options.addAction(UIAlertAction(title: option.name, style: .default, handler: { (action) in
                self.poiTypeButton.setTitle(option.name, for: .normal)
            }))
        }

        options.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(options, animated: true)
        // prevent constraings bug in iOS
        options.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
            return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
        }.first?.isActive = false
    }

    // MARK:- Media

    /// Adds captured photo into the POI
    private func addMedia(image: UIImage) throws {
        media.append(try TripRecordingMedia.buildFromData(image: image, location: mapLocation))

        self.photoCollectionView.reloadData()
    }

    private func deleteMedia(media: TripRecordingMedia, index: Int) {
        if index != -1 && index < self.media.count {
            self.media.remove(at: index)
        }
        photoCollectionView.reloadData()
    }
}

// MARK:- UITextFieldDelegate extension
extension TripPoiViewController : UITextFieldDelegate, UITextViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
    }
}

// MARK:- UICollectionViewDelegate extension
extension TripPoiViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TripRecordingMediaCollectionViewCell.cellIdentifier, for: indexPath) as! TripRecordingMediaCollectionViewCell
        cell.bindView(media: media[indexPath.row], mediaIndex: indexPath.row, delegate: self)
        return cell
    }
}

// MARK:- TripRecordingMediaCollectionViewCellDelegate extension
extension TripPoiViewController : TripRecordingMediaCollectionViewCellDelegate {
    func tripMediaDeletePressed(media: TripRecordingMedia, index: Int) {
        deleteMedia(media: media, index: index)
    }
    
    func canEditMedia(media: TripRecordingMedia) -> Bool {
        return true
    }
}

// MARK:- UIImagePickerControllerDelegate extension
extension TripPoiViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
