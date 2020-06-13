//
//  EditWaypointViewController.swift
//  Trax
//
//  Created by Dr. Andreas Plagens on 16.05.19.
//  Copyright © 2019 Dr. Andreas Plagens. All rights reserved.
//
//  Adapted to Swift 5

import UIKit

class EditWaypointViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        nameTextField.becomeFirstResponder()
    }
    
    var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }
    
    private func updateUI() {
        nameTextField?.text = waypointToEdit?.name
        infoTextField?.text = waypointToEdit?.info
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenToTextFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToTextFields()
    }
    
    override func viewWillLayoutSubviews() {
        super .viewWillLayoutSubviews()
        preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    
    private func stopListeningToTextFields() {
        if let observer = ntfObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = itfObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private var ntfObserver: NSObjectProtocol?
    private var itfObserver: NSObjectProtocol?

    private func listenToTextFields() {
        let center = NotificationCenter.default
        let queue = OperationQueue.main
        
        ntfObserver = center.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: nameTextField,
            queue: queue,
            using: {
                notification in
                    if let waypoint = self.waypointToEdit {
                        waypoint.name = self.nameTextField.text
                        }
                }
        )
        itfObserver = center.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: infoTextField,
            queue: queue,
            using: {
                notification in
                if let waypoint = self.waypointToEdit {
                    waypoint.info = self.infoTextField.text
                }
        }
        )
    }
    
    
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    @IBOutlet weak var infoTextField: UITextField! { didSet { infoTextField.delegate = self } }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
