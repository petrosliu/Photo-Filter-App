//
//  ViewController.swift
//  Filterer
//
//  Created by Jack on 2015-09-22.
//  Copyright © 2015 UofT. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var filteredImage: UIImage?
    var originalImage: UIImage?
    var processor: ImageProcessor?
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var fadeView: UIImageView!
    
    @IBOutlet var secondaryMenu: UIView!
    @IBOutlet var slideMenu: UIView!
    @IBOutlet var bottomMenu: UIView!
    @IBOutlet var overButtom: UIButton!
    
    @IBOutlet var filterBottom: UIButton!
    @IBOutlet var compareBottom: UIButton!
    
    @IBOutlet var editBottom: UIButton!
    @IBOutlet var brightnessBotttom: UIButton!
    @IBOutlet var contrastBottom: UIButton!
    @IBOutlet var grayBottom: UIButton!
    @IBOutlet var noiseBottom: UIButton!
    @IBOutlet var inverseBottom: UIButton!
    
    @IBOutlet var originalLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        secondaryMenu.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        secondaryMenu.translatesAutoresizingMaskIntoConstraints = false
        slideMenu.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        slideMenu.translatesAutoresizingMaskIntoConstraints = false
        
        originalImage = UIImage(named: "scenery")
        processor=ImageProcessor(img: originalImage!)
        filteredImage=originalImage
        imageView.image=originalImage
        compareBottom.enabled = false
        editBottom.enabled = false
    }

    @IBAction func onBrightness(sender: UIButton) {
        processor!.addFilter("brightness")
        filteredImage = processor!.getImage()
        showfadeView()
        hidefadeView()
    }
    @IBAction func onContrast(sender: UIButton) {
        processor!.addFilter("contrast")
        filteredImage = processor!.getImage()
        showfadeView()
        hidefadeView()
    }
    @IBAction func onGray(sender: UIButton) {
        processor!.addFilter("gray")
        filteredImage = processor!.getImage()
        showfadeView()
        hidefadeView()
    }
    @IBAction func onNoise(sender: UIButton) {
        processor!.addFilter("noise")
        filteredImage = processor!.getImage()
        showfadeView()
        hidefadeView()
    }
    @IBAction func onInverse(sender: UIButton) {
        processor!.addFilter("inverse")
        filteredImage = processor!.getImage()
        showfadeView()
        hidefadeView()
    }
    
    // MARK: Share
    @IBAction func onShare(sender: AnyObject) {
        let activityController = UIActivityViewController(activityItems: ["Check out our really cool app", imageView.image!], applicationActivities: nil)
        presentViewController(activityController, animated: true, completion: nil)
    }
    
    // MARK: New Photo
    @IBAction func onNewPhoto(sender: AnyObject) {
        let actionSheet = UIAlertController(title: "New Photo", message: nil, preferredStyle: .ActionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { action in
            self.showCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Album", style: .Default, handler: { action in
            self.showAlbum()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func showCamera() {
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .Camera
        
        presentViewController(cameraPicker, animated: true, completion: nil)
    }
    
    func showAlbum() {
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .PhotoLibrary
        
        presentViewController(cameraPicker, animated: true, completion: nil)
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = image
            originalImage = image
            filteredImage = image
            processor = ImageProcessor(img:originalImage!)
            compareBottom.enabled = false
            compareBottom.selected = false
            originalLabel.hidden = true
            editBottom.enabled = false
            editBottom.selected = false
            hideSlideMenu()
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Filter Menu
    @IBAction func onFilter(sender: UIButton) {
        if (sender.selected) {
            hideSecondaryMenu()
            sender.selected = false
        } else {
            showSecondaryMenu()
            sender.selected = true
        }
    }
    
    @IBAction func onEdit(sender: UIButton) {
        if (sender.selected) {
            hideSlideMenu()
            sender.selected = false
        } else {
            showSlideMenu()
            sender.selected = true
        }
    }
    
    func showSlideMenu() {
        if(filterBottom.selected){
            hideSecondaryMenu()
            filterBottom.selected = false
        }
        
        view.addSubview(slideMenu)
        
        let bottomConstraint = slideMenu.bottomAnchor.constraintEqualToAnchor(bottomMenu.topAnchor)
        let leftConstraint = slideMenu.leftAnchor.constraintEqualToAnchor(view.leftAnchor)
        let rightConstraint = slideMenu.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        let heightConstraint = slideMenu.heightAnchor.constraintEqualToConstant(68)
        
        NSLayoutConstraint.activateConstraints([bottomConstraint, leftConstraint, rightConstraint, heightConstraint])
        view.layoutIfNeeded()
        
        self.slideMenu.alpha = 0
        UIView.animateWithDuration(0.4) {
            self.slideMenu.alpha = 1.0
        }

    }
    
    func hideSlideMenu() {
        UIView.animateWithDuration(0.4, animations: {
            self.slideMenu.alpha = 0
            }) { completed in
                if completed == true {
                    self.slideMenu.removeFromSuperview()
                }
        }
    }
    
    
    @IBAction func onSlide(sender: UISlider) {
        imageView.image = filteredImage
        compareBottom.selected = false
        originalLabel.hidden = true
        let c=Double(sender.value)
        processor!.resetCoeff(c)
        filteredImage = processor!.getImage()
        imageView.image=filteredImage
        compareBottom.enabled = true
        editBottom.enabled = true
    }
    
    
    @IBAction func onCompare(sender: UIButton) {
        if (sender.selected) {
            imageView.image = filteredImage
            sender.selected = false
            originalLabel.hidden = true
        } else {
            imageView.image = originalImage
            sender.selected = true
            originalLabel.hidden = false
        }
    }
    
    @IBAction func onOverDown(sender: UIButton) {
        if (compareBottom.selected) {
            imageView.image = filteredImage
            compareBottom.selected = false
            originalLabel.hidden = true
        } else {
            imageView.image = originalImage
            compareBottom.selected = true
            originalLabel.hidden = false
        }
    }
    @IBAction func onOverUp(sender: AnyObject) {
        if (compareBottom.selected) {
            imageView.image = filteredImage
            compareBottom.selected = false
            originalLabel.hidden = true
        } else {
            imageView.image = originalImage
            compareBottom.selected = true
            originalLabel.hidden = false
        }
    }
    
    func showfadeView() {
        fadeView.image=imageView.image
        fadeView.alpha = 0
        UIView.animateWithDuration(0.4) {
            self.fadeView.alpha = 1.0
        }
    }
    func hidefadeView() {
        imageView.image=filteredImage
        compareBottom.enabled = true
        editBottom.enabled = true
        originalLabel.hidden = true
        fadeView.alpha = 1.0
        UIView.animateWithDuration(0.6) {
            self.fadeView.alpha = 0
        }
    }
    
    
    func showSecondaryMenu() {
        if(editBottom.selected){
            hideSlideMenu()
            editBottom.selected = false
        }
        
        view.addSubview(secondaryMenu)
        
        let bottomConstraint = secondaryMenu.bottomAnchor.constraintEqualToAnchor(bottomMenu.topAnchor)
        let leftConstraint = secondaryMenu.leftAnchor.constraintEqualToAnchor(view.leftAnchor)
        let rightConstraint = secondaryMenu.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        let heightConstraint = secondaryMenu.heightAnchor.constraintEqualToConstant(68)
        
        NSLayoutConstraint.activateConstraints([bottomConstraint, leftConstraint, rightConstraint, heightConstraint])
        view.layoutIfNeeded()
        
        self.secondaryMenu.alpha = 0
        UIView.animateWithDuration(0.4) {
            self.secondaryMenu.alpha = 1.0
        }
    }

    func hideSecondaryMenu() {
        UIView.animateWithDuration(0.4, animations: {
            self.secondaryMenu.alpha = 0
            }) { completed in
                if completed == true {
                    self.secondaryMenu.removeFromSuperview()
                }
        }
        
    }

}

