//
//  ViewController.swift
//  TestTask
//
//  Created by Nikita Kryuchkov on 17.09.2021.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    // MARK: - IB Outlets
    @IBOutlet var labelForBright: UILabel!
    @IBOutlet var takePicture: UIButton!
    @IBOutlet var textFieldForLevelBright: UITextField!
    
    private var takePhoto: Bool = false
    private var levelBright: Double = 40
    private let avSession = AVCaptureSession()
    private var camera: AVCaptureDevice?
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutputQueue = DispatchQueue(label: "com.testVideoQ")
    
    // MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        getCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
        view.addSubview(labelForBright)
        view.addSubview(takePicture)
        view.addSubview(textFieldForLevelBright)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        avSession.stopRunning()
    }
    
    @IBAction func takePicture(_ sender: Any) {
        takePhoto = true
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
}

// MARK: - AVFoundation Delegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let image = self.getImageFromSampleBuffer(buffer: sampleBuffer)
        if let image = image {
            DispatchQueue.main.async {
                self.labelForBright.text = (image.brightness > self.levelBright ? "" : "💡")
            }
            print(image.brightness)
            if takePhoto {
                takePhoto = false
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }
}

// MARK: - UIImage

extension CGImage {
    var brightness: Double {
        let imageData = self.dataProvider?.data
        let ptr = CFDataGetBytePtr(imageData)
        var x = 0
        var result: Double = 0
        for _ in 0..<self.height {
            for _ in 0..<self.width {
                let r = ptr![0]
                let g = ptr![1]
                let b = ptr![2]
                result += (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                x += 1
            }
        }
        let bright = result / Double(x)
        return bright
    }
}

extension UIImage {
    var brightness: Double {
        return (self.cgImage?.brightness)!
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
