//
//  TrailCollectionViewController.swift
//  DemoApp(Develop)
//
//  Created by Carlos Torres on 6/1/20.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import UIKit
import AccuTerraSDK
import Mapbox
import CoreLocation
import AlignedCollectionViewFlowLayout
import Combine

class TrailCollectionViewController: BaseTripRecordingViewController {
    
    // MARK:- Properties
    private lazy var poiTypes = [PointType]()
    @Published private var poiMedia = [TripRecordingMedia]()
    private lazy var poiTags = [PoiTag]()
    private lazy var poiTypeTags = [PoiTag]()
    private var editingPoi: TripRecordingPoi?
    private var selectedPoiType: PointType?
    private var backedTrackingMode: TrackingOption?
    private var cancellable: Cancellable?
    
    // MARK:- Outlets
    @IBOutlet weak var trailCollectionStatusLabel: UILabel!
    @IBOutlet weak var poiViewHeaderLabel: UILabel!
    @IBOutlet weak var trailCollectionCrossHairImageView: UIImageView!
    @IBOutlet weak var statsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var poiView: UIView!
    @IBOutlet weak var poiViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var poiTypeButton: UIButton!
    @IBOutlet weak var poiTagsCollectionView: UICollectionView!
    @IBOutlet weak var poiPhotosCollectionView: UICollectionView!
    @IBOutlet weak var poiNameTitle: UILabel!
    @IBOutlet weak var poiNameTextField: UITextField!
    @IBOutlet weak var poiDescriptionTitle: UILabel!
    @IBOutlet weak var poiDescriptionTextView: UITextView!
    @IBOutlet weak var poiScrollView: UIScrollView!
    @IBOutlet var inputControls: [UIView] = [UIView]()
    @IBOutlet weak var poiDeleteButton: UIButton!
    @IBOutlet weak var poiImagesCollectionViewHeightConstraint: NSLayoutConstraint!
    
    // MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rightItem = UIBarButtonItem(image: UIImage.contextMenuImage, landscapeImagePhone: nil, style: .plain, target: self, action: #selector(contextMenuButtonPressed))

        self.navigationItem.rightBarButtonItem = rightItem
        
        let leftItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))

        self.navigationItem.leftBarButtonItem = leftItem
        
        self.poiPhotosCollectionView.register(UINib(nibName: TripRecordingMediaCollectionViewCell.cellXibName, bundle: nil), forCellWithReuseIdentifier: TripRecordingMediaCollectionViewCell.cellIdentifier)
        
        self.closePoiDialog()
        
        setupMap()
        
        // Handle keyboard show/hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        poiDescriptionTextView.extendToolbar()
        
        self.tripRecorder.addObserver(observer: self)
        
        if let layout = (poiTagsCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout) {
            layout.horizontalAlignment = .left
            // Enable automatic cell-sizing with Auto Layout:
            layout.estimatedItemSize = .init(width: 100, height: 20)
        }
            
        updateStatusLabel()
        cancellable = $poiMedia
            .sink { completion in
            } receiveValue: { val in
                self.poiImagesCollectionViewHeightConstraint.constant = val.isEmpty ? 0 : 100
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.poiPhotosCollectionView.reloadData()
                }
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let capSentences = UITextAutocapitalizationType.sentences
        self.poiNameTextField.autocapitalizationType = capSentences
        self.poiDescriptionTextView.autocapitalizationType = capSentences
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK:- Actions
    @objc func close() {
        guard !tripRecorder.hasActiveTripRecording() else {
            cancelRecordingButtonPressed()
            return
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func infoButtonPressed() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrailCollectionGuideVC")
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func cancelRecordingButtonPressed() {
        AlertUtils.showPrompt(viewController: self, title: "Cancel recording", message: "Do you want to cancel trip recording?") {
            try? self.tripRecorder.cancelTripRecording()
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction func poiSaveButtonPressed() {
        guard validateForm() else {
            return
        }
        
        let mapCenter = mapView.centerCoordinate
        let mapLocation = MapLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)
        
        do {
            let enumService = ServiceFactory.getEnumService()

            // Gather POI data
            let name = poiNameTextField.text ?? "Trip POI"
            let description = poiDescriptionTextView.text
            let selectedPointType = poiTypes.first(where: { (t:PointType) -> Bool in
                return t.name == poiTypeButton.currentTitle!
            })!
            let pointType = selectedPointType
            let poiTagsFiltered = self.poiTags.filter { (t) -> Bool in
                return t.pointTypeCode == pointType.code
            }

            if let existingPoi = self.editingPoi {
                // Update existing Poi
                let poi = existingPoi.copy(
                    name: name,
                    mapLocation: mapLocation,
                    description: description,
                    descriptionShort: nil,
                    pointType: pointType,
                    tags: poiTagsFiltered,
                    media: ApkMediaUtil.updatePositions(allMedia: poiMedia)
                )
                // Update POI
                try updatePoi(poi: poi)
            } else {
                
                // Build the new POI
                let poi = try TripRecordingPoi.buildNewPoi(
                    name: name,
                    mapLocation: mapLocation,
                    pointTypeCode: pointType.code,
                    enumService: enumService,
                    description: description,
                    descriptionShort: nil,
                    media: ApkMediaUtil.updatePositions(allMedia: poiMedia),
                    tags: poiTagsFiltered
                )
                
                // Add the newly created POI to the trip recording
                try addPoi(poi: poi)
            }

            // Close the dialog
            closePoiDialog()
        } catch {
            showError(error)
        }
    }
    
    @IBAction func poiDeleteButtonPressed(_ sender: Any) {
        if let poi = self.editingPoi {
            do {
                try deletePOI(poi: poi)
                // Close the dialog
                closePoiDialog()
            }
            catch {
                showError(error)
            }
        }
    }
    
    /// Add the newly created POI to the trip recording
    private func addPoi(poi: TripRecordingPoi) throws {
        let recorder = try ServiceFactory.getTripRecorder()
        let _ = try recorder.addPoi(poi: poi)
    }
    
    /// Update existing POI in the trip recording
    private func updatePoi(poi: TripRecordingPoi) throws {
        let recorder = try ServiceFactory.getTripRecorder()
        let _ = try recorder.updatePoi(poi: poi)
    }
    
    /// Deletes existing poi
    private func deletePOI(poi: TripRecordingPoi) throws {
        let recorder = try ServiceFactory.getTripRecorder()
        let _ = try recorder.deletePoi(poiUuid: poi.uuid)
    }
    
    @IBAction func poiCancelButtonPressed() {
        AlertUtils.showPrompt(viewController: self, title: "Close POI Editing?", message: "There are unsaved changes. Do you want to close the from anyway?") {
            self.closePoiDialog()
        } cancelHandler: {
        }
    }
    
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
    
    @IBAction func poiTypeButtonPressed() {
        view.endEditing(true)
        showTypeOptions()
    }
    
    @objc func contextMenuButtonPressed() {
        let options = UIAlertController(title: self.title, message: nil, preferredStyle: .actionSheet)

        options.addAction(UIAlertAction(title: "Show Guide", style: .default, handler: { (action) in
            self.infoButtonPressed()
        }))

        options.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(options, animated: true)
        // prevent constraings bug in iOS
        options.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
            return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
        }.first?.isActive = false
    }
    
    @IBAction override func onAddPoiClicked(_ sender: Any) {
        guard self.poiView.isHidden else {
            return
        }
        
        guard tripRecorder.hasActiveTripRecording() else {
            showError("Start trip recording first".toError())
            return
        }
        
        tryOrShowError {
            self.poiMedia.removeAll()
            self.poiTags.removeAll()
            self.showPoiDialog()
        }
    }
    
    override func onEditPoiClicked(poiUuid: String) throws {
        guard let poi = try ServiceFactory.getTripRecordingService().getTripRecordingPoiByUuid(uuid: poiUuid) else {
            throw "No POI \(poiUuid) found".toError()
        }
        showPoiDialog(editPoi: poi)
    }
    
    override func openSaveTripView(tripUuid: String, completion: (() -> Void)?) {
        if let vc = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "TrailSaveVC") as? TrailSaveViewController {
            vc.tripUuid = tripUuid
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: completion)
        }
    }
    
    override func getExtProperties() -> [ExtProperties]? {
        return ExtPropertiesBuilder.buildList(value: TrailCollectionData())
    }
    
    private func validateForm() -> Bool {
        // Check mandatory values
        if (poiNameTextField.text?.count ?? 0) < 3 {
            showError("Please provide a POI name of at least 3 character long.".toError())
            return false
        } else if poiDescriptionTextView.text.count < 10 {
            showError("Please provide a description text of at least 10 characters long.".toError())
            return false
        } else if poiMedia.count < 1 {
            showError("Please provide at least 1 photo.".toError())
            return false
        } else if poiTags.count == 0 {
            showError("Please select at least 1 tag.".toError())
            return false
        } else {
            // Everything OK
            return true
        }
    }
    
    private func showPoiDialog(editPoi: TripRecordingPoi? = nil) {
        do {
            let enumService = ServiceFactory.getEnumService()
            let types = try enumService.getPointTypes()
            self.poiTypes = Array(types.sorted { (a, b) -> Bool in
                a.name.compare(b.name) == ComparisonResult.orderedAscending
            })
            
            guard self.poiTypes.count > 0 else {
                throw "Could not find any POI types".toError()
            }
            
            if selectedPoiType == nil {
                selectedPoiType = self.poiTypes.first
            }
        } catch {
            showError(error)
            return
        }
        self.trailCollectionCrossHairImageView.isHidden = false
        self.editingPoi = editPoi
        self.poiMedia.removeAll()
        self.poiTags.removeAll()
        self.poiView.isHidden = false
        self.statsViewHeightConstraint.constant = 500
        self.poiViewHeightConstraint.constant = 500
        self.poiScrollView.contentOffset = CGPoint(x: 0, y: 0)
        
        if let editPoi = editPoi {
            self.poiNameTextField.text = editPoi.name
            self.poiDescriptionTextView.text = editPoi.description
            self.selectedPoiType = self.poiTypes.first(where: { (t) -> Bool in
                return t.code == editPoi.pointType.code
            })
            self.poiMedia = editPoi.media
            self.poiTags.append(contentsOf: editPoi.tags)
            poiViewHeaderLabel.text = "Edit POI"
            poiDeleteButton.isHidden = false
        } else {
            self.poiNameTextField.text = nil
            self.poiDescriptionTextView.text = nil
            poiViewHeaderLabel.text = "Add New POI"
            poiDeleteButton.isHidden = true
        }
        self.poiPhotosCollectionView.reloadData()
        
        updateTags()
        self.backedTrackingMode = self.currentTracking
        exitDrivingMode()
        if let lastLocation = self.lastLocation, editPoi == nil {
            mapView.setCenter(lastLocation.coordinate, animated: false)
        }
        else if let editPoi = editPoi {
            mapView.setCenter(CLLocationCoordinate2D(latitude: editPoi.mapLocation.latitude, longitude: editPoi.mapLocation.longitude), animated: true)
        }
    }
    
    private func updateTags() {
        tryOrShowError {
            let enumService = ServiceFactory.getEnumService()
            
            if let selectedPoiType = self.selectedPoiType {
                self.poiTypeButton.setTitle(selectedPoiType.name, for: .normal)
                self.poiTypeTags.removeAll()
                self.poiTypeTags.append(contentsOf: try enumService.getPoiTags(pointType: selectedPoiType))
            } else {
                self.poiTypeTags.removeAll()
            }
            poiTagsCollectionView.reloadData()
            if self.poiTypeTags.count > 0 {
                poiTagsCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
    
    private func closePoiDialog() {
        self.poiMedia.removeAll()
        self.poiTags.removeAll()
        self.poiView.isHidden = true
        self.trailCollectionCrossHairImageView.isHidden = true
        self.statsViewHeightConstraint.constant = 220
        
        // Restore previous tracking mode
        if let backedTrackingMode = self.backedTrackingMode {
            setLocationTracking(trackingOption: backedTrackingMode)
            self.backedTrackingMode = nil
        }
    }
    
    // MARK:- Media

    /// Adds captured photo into the POI
    private func addMedia(image: UIImage) throws {
        let mapCenter = mapView.centerCoordinate
        let mapLocation = MapLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)
        poiMedia.append(try TripRecordingMedia.buildFromData(image: image, location: mapLocation))

        self.poiPhotosCollectionView.reloadData()
    }

    private func deleteMedia(media: TripRecordingMedia, index: Int) {
        if index != -1 && index < poiMedia.count {
            poiMedia.remove(at: index)
        }
        poiPhotosCollectionView.reloadData()
    }
}

// MARK:- POI extensions
extension TrailCollectionViewController {
    func showTypeOptions() {
        let options = UIAlertController(title: "POI Type", message: nil, preferredStyle: .actionSheet)

        for option in poiTypes {
            options.addAction(UIAlertAction(title: option.name, style: .default, handler: { (action) in
                self.selectedPoiType = option
                self.updateTags()
            }))
        }

        options.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(options, animated: true)
        // prevent constraings bug in iOS
        options.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
            return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
        }.first?.isActive = false
    }
}

// MARK:- Map extension
extension TrailCollectionViewController {
    override func onMapLoaded() {
        super.onMapLoaded()
        do {
            try setupRecordingAfterOnAccuTerraMapViewReady()
        } catch {
            showError(error)
        }
        setLocationTracking(trackingOption: .LOCATION)
    }
}

// MARK:- UITextFieldDelegate extension
extension TrailCollectionViewController : UITextFieldDelegate, UITextViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField.returnKeyType == .next, let nextControl = textField.superview?.viewWithTag(textField.tag + 1), nextControl.canBecomeFirstResponder {
            nextControl.becomeFirstResponder()
        }
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        if let nextControl = textView.superview?.viewWithTag(textView.tag + 1), nextControl.canBecomeFirstResponder {
            nextControl.becomeFirstResponder()
        }
        return true
    }
}

// MARK:- UICollectionViewDelegate extension
extension TrailCollectionViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.poiPhotosCollectionView {
            return poiMedia.count
        } else {
            return poiTypeTags.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.poiPhotosCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TripRecordingMediaCollectionViewCell.cellIdentifier, for: indexPath) as! TripRecordingMediaCollectionViewCell
            cell.bindView(media: poiMedia[indexPath.row], mediaIndex: indexPath.row, delegate: self)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "poiTagCell", for: indexPath) as! PoiTagCollectionViewCell
            let tag = self.poiTypeTags[indexPath.row]
            let selected = self.poiTags.contains { (t) -> Bool in
                return t.code == tag.code
            }
            cell.bindView(tag: tag, selected: selected)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.poiTagsCollectionView {
            let tag = self.poiTypeTags[indexPath.row]
            if let selectedIndex = self.poiTags.firstIndex(where: { (t) -> Bool in
                return t.code == tag.code
            }) {
                self.poiTags.remove(at: selectedIndex)
            } else {
                self.poiTags.append(tag)
            }
            collectionView.reloadData()
        }
    }
}

// MARK:- TripRecordingMediaCollectionViewCellDelegate extension
extension TrailCollectionViewController : TripRecordingMediaCollectionViewCellDelegate {
    func tripMediaDeletePressed(media: TripRecordingMedia, index: Int) {
        deleteMedia(media: media, index: index)
    }

    func canEditMedia(media: TripRecordingMedia) -> Bool {
        return true
    }
}

// MARK:- UIImagePickerControllerDelegate extension
extension TrailCollectionViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

// MARK: - Keyboard extensions
private extension TrailCollectionViewController {
    @objc func keyboardWillShow(notification: NSNotification) {
        guard nil != (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }
        
        let maxScrollOffset = poiScrollView.contentSize.height - poiScrollView.frame.height
        
        var scrollOffset: CGFloat = 0
        if poiNameTextField.isFirstResponder {
            scrollOffset = poiNameTextField.frame.minY
        } else if poiDescriptionTextView.isFirstResponder {
            scrollOffset = poiDescriptionTextView.frame.minY - 30
        } else {
            scrollOffset = self.poiScrollView.contentOffset.y - 30
        }
        
        poiScrollView.contentOffset = CGPoint(x: 0, y: min(scrollOffset, maxScrollOffset))
    }
}

extension TrailCollectionViewController : TripRecorderDelegate {
    func onLocationAdded(location: CLLocation) {
        // nothing to do
    }
    
    func onPoiAdded(tripPoi: TripRecordingPoi) {
        // nothing to do
    }
    
    func onPoiUpdated(tripPoi: TripRecordingPoi) {
        // nothing to do
    }
    
    func onPoiDeleted(poiUuid: String) {
        // nothing to do
    }
    
    func onRecentLocationBufferChanged(newLocation: CLLocation, bufferFlushed: Bool) {
        // nothing to do
    }
    
    func onStatusChanged(status: TripRecorderStatus) {
        updateStatusLabel()
    }
    
    func updateStatusLabel() {
        switch tripRecorder.getStatus() {
        case .FINISHED:
            self.trailCollectionStatusLabel.isHidden = true
        case .INACTIVE:
            self.trailCollectionStatusLabel.isHidden = true
        case .PAUSED:
            self.trailCollectionStatusLabel.isHidden = false
            self.trailCollectionStatusLabel.text = "Recording Paused"
            self.trailCollectionStatusLabel.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
            self.trailCollectionStatusLabel.textColor = UIColor.white
        case .RECORDING:
            self.trailCollectionStatusLabel.isHidden = false
            self.trailCollectionStatusLabel.text = "Recording Track"
            self.trailCollectionStatusLabel.backgroundColor = UIColor.Active?.withAlphaComponent(0.5)
            self.trailCollectionStatusLabel.textColor = UIColor.white
        }
    }
}
