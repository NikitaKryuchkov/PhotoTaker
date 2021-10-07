//
//  Blur.swift
//  TestTask
//
//  Created by Nikita Kryuchkov on 20.09.2021.
//

import Foundation
import Metal
import MetalPerformanceShaders
import MetalKit

class BlurViewController: UIViewController {
    
    var mtlDevice: MTLDevice!
    var mtlCommandQueue: MTLCommandQueue!
    
override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func InitializeMTL(){
        self.mtlDevice = MTLCreateSystemDefaultDevice()
        self.mtlCommandQueue = mtlDevice?.makeCommandQueue()
    }
    
    private func getSourceTextureFrom(image: CGImage) -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self.mtlDevice)
        let sourceTexture = try! textureLoader.newTexture(cgImage: image, options: nil)
        return sourceTexture
    }
    
    private func textureFormatting(sourceTexture: MTLTexture) -> MTLTexture {
        let lapDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        lapDesc.usage = [.shaderWrite, .shaderRead]
        let lapTex = self.mtlDevice.makeTexture(descriptor: lapDesc)!
        return lapTex
    }
    
    private func getTextureForStoringVariance(from sourceTexture: MTLTexture) -> MTLTexture {
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let varianceTexture = self.mtlDevice.makeTexture(descriptor: varianceTextureDescriptor)!
        return varianceTexture
    }
    
    
     func getVarianceOf(image: CGImage) -> Int {
        InitializeMTL()
        
        let laplacian = MPSImageLaplacian(device: self.mtlDevice)
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: self.mtlDevice)
        let sourceTexture = getSourceTextureFrom(image: image)
        let lapTex = textureFormatting(sourceTexture: sourceTexture)
        let commandBuffer = self.mtlCommandQueue.makeCommandBuffer()!
        let varianceTexture = getTextureForStoringVariance(from: sourceTexture)
        let region = MTLRegionMake2D(0, 0, 2, 1)
        var result = [Int8](repeatElement(0, count: 2))
        
        laplacian.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: lapTex)
        meanAndVariance.encode(commandBuffer: commandBuffer, sourceTexture: lapTex, destinationTexture: varianceTexture)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        varianceTexture.getBytes(&result, bytesPerRow: 1 * 2 * 4, from: region, mipmapLevel: 0)
        
        guard let result = result.last else { return 0 }
        return Int(result)
    }
}
