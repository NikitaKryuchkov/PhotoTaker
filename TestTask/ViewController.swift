//
//  ViewController.swift
//  TestTask
//
//  Created by Nikita Kryuchkov on 17.09.2021.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    let blurVC = BlurViewController()
    
    // MARK: - IB Outlets
    @IBOutlet var labelForBright: UILabel!
    @IBOutlet var takePicture: UIButton!
    @IBOutlet var textFieldForLevelBright: UITextField!
    @IBOutlet var ImgView: UIImageView!
    @IBOutlet var takePhotoOnRight: UIButton!
    @IBOutlet var takePhotoOnDown: UIButton!
    
    
    // MARK: - Private properties
    private var takePhoto: Bool = false
    private var levelBright: Double = 40
    
    private let avSession = AVCaptureSession() //vk
    private var camera: AVCaptureDevice?
    private var previewLayer: AVCaptureVideoPreviewLayer!//vk
    private let videoOutputQueue = DispatchQueue(label: "com.testVideoQ")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        getCamera()
        ImgView.alpha = 0.8
        ImgView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
        view.addSubview(labelForBright)
        view.addSubview(takePicture)
        view.addSubview(textFieldForLevelBright)
        view.addSubview(ImgView)
        view.addSubview(takePhotoOnRight)
        view.addSubview(takePhotoOnDown)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        avSession.stopRunning()
    }
    
    // MARK: - IBActions
    @IBAction func takePicture(_ sender: Any) {
        takePhoto = true
    }
    
    @IBAction func takePhotoOnRightBtn(_ sender: Any) {
        ImgView.frame.origin.x -= self.view.frame.size.width / 3 * 2
        ImgView.isHidden = false
    }
    
    @IBAction func TakePhotoOnDownBtn(_ sender: Any) {
        ImgView.frame.origin.y -= self.view.frame.size.height / 3 * 2
        ImgView.isHidden = false
    }
    
    // MARK: - Private Properties
    private func getCamera() {
        camera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInDualCamera,
                .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back)
            .devices
            .first
    }
    
    private func addCameraInput(to session: AVCaptureSession) {
        guard let camera = camera,
              let cameraInput = try? AVCaptureDeviceInput(device: camera) else { return }
        
        if avSession.canAddInput(cameraInput) {
            avSession.addInput(cameraInput)
        }
    }
    
    private func attachPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: avSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.bounds
    }
    
    private func addVideoOutput() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        if avSession.canAddOutput(videoDataOutput) {
            avSession.addOutput(videoDataOutput)
        }
    }
    
    private func startCamera() {
        AVCaptureDevice.requestAccess(for: .video) { _ in}
        
        addCameraInput(to: avSession)
        attachPreviewLayer()
        addVideoOutput()
        avSession.startRunning()
    }
    
    private func savePhoto(image: UIImage) {
        if takePhoto {
            takePhoto = false
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            DispatchQueue.main.async {
                self.ImgView.image = image
            }
        }
    }
    
    private func getImageFromSampleBuffer(buffer: CMSampleBuffer) -> UIImage? {
        
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        return nil
    }
    
    private func getCGImageFromSampleBuffer(buffer: CMSampleBuffer) -> CGImage? {
        
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

            let context = CIContext(options: nil)
                if context != nil {
                    return context.createCGImage(ciImage, from: ciImage.extent)
                }
        }
        return nil
    }
    
    private func getCGlmage(from image: UIImage) -> CGImage? {
        if let ciImage = CIImage(image: image){
            let context = CIContext(options: nil)
            if context != nil {
                return context.createCGImage(ciImage, from: ciImage.extent)
            }
        }
        return nil
    }
    
}

// MARK: - AVFoundation Delegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let image = self.getImageFromSampleBuffer(buffer: sampleBuffer)
        if let image = image {
            let result = (image.brightness > self.levelBright ? "" : "🔆")
            DispatchQueue.main.async {
                self.labelForBright.text = result
            }
            savePhoto(image: image)
            //print(image.brightness)
        }

//        let cgImage = self.getCGImageFromSampleBuffer(buffer: sampleBuffer)
//        if let cgImage = cgImage {
//            blurVC.getblur(image: cgImage)
//        }
        
        // detect blur test
//        guard let image = testImage else { return }
//        let cgImage = self.getCGlmage(from image: image)
//        if let cgImage = cgImage {
//        blurVC.getVarianceOf(image: cgImage)
//        }
        
    }
}


// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let keyboardToolbar = UIToolbar()
        textField.inputAccessoryView = keyboardToolbar
        keyboardToolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(textFieldShouldReturn(_:))
        )
        
        let flexBarButton = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        keyboardToolbar.items = [flexBarButton, doneButton]
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if let text = textField.text {
            levelBright = Double(text) ?? 40
        }
    }
}


