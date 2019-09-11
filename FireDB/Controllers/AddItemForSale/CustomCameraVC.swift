//
//  CustomCameraVC.swift
//  FireDB
//
//  Created by admin on 10/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit

class CustomCameraVC: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var viewCamera: UIView!
    @IBOutlet weak var viewCrop: UIView!
    
    
    let imagePickers = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.addCameraView()
        }
        // Do any additional setup after loading the view.
    }
    
    func addCameraView(){
        
        if UIImagePickerController.isCameraDeviceAvailable( UIImagePickerController.CameraDevice.front) {
            imagePickers.delegate = self
            imagePickers.sourceType = .camera
            imagePickers.cameraDevice = .rear
            //add as a childviewcontroller
            addChild(imagePickers)
            
            // Add the child's View as a subview
            self.viewCamera.addSubview((imagePickers.view)!)
            imagePickers.view.frame = viewCamera.bounds
            imagePickers.allowsEditing = true
            imagePickers.showsCameraControls = false
            imagePickers.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
    @IBAction func btnFlipCameraAction(_ sender : UIButton) {
        if self.imagePickers.cameraDevice == .rear {
            self.imagePickers.cameraDevice = .front
        }else {
            self.imagePickers.cameraDevice = .rear
        }
    }
    
    @IBAction func btnCaptureImageAction(_ sender : UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickers.takePicture()
        }
    }
    
    @IBAction func btnOpenPhotoLibraryAction(_ sender : UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func btnCloseAction(_ sender : UIButton) {
        if let tabVC = self.presentingViewController as? TabBarVC {
            self.dismiss(animated: false) {
                tabVC.selectedIndex = 0
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CustomCameraVC  {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImg : UIImage? = nil
        if let img = info[.editedImage] as? UIImage {
            selectedImg = img
        }else if let img = info[.originalImage] as? UIImage {
            selectedImg = img
            selectedImg = selectedImg?.resizeImage(targetSize: self.viewCamera.bounds.size)
            selectedImg = selectedImg?.cropToBounds(width: self.view.bounds.width, height: self.view.bounds.width, origin: CGPoint.init(x: 0.0, y: self.viewCrop.frame.origin.y - self.viewCamera.frame.origin.y))
        }
        if let img = selectedImg {
            if picker != self.imagePickers {
                picker.dismiss(animated: false, completion: {
                    self.showImageCropView(withImage: img)
                })
            }else {
                self.showImageCropView(withImage: img)
            }
        }
    }
    
    func showImageCropView(withImage img: UIImage) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CropImageVC") as! CropImageVC
        vc.imageToCrop = img
        self.present(vc, animated: false, completion: nil)
    }
}

extension UIImage {
    func cropToBounds(width: CGFloat, height: CGFloat, origin : CGPoint) -> UIImage {
        
        let cgimage = self.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = origin.x
        var posY: CGFloat = origin.y
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = cgimage.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        return image
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize.init(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize.init(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? UIImage()
    }
}
