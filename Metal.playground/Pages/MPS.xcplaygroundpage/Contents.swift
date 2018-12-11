//
//  MPS.playground
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

//: [Previous](@previous)

import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders

let context = MetalContext.shared

let inputImage = NSImage(named: "girl")!
let inTexture = texture(from: inputImage)

// https://forums.developer.apple.com/thread/72037
let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                 width: inTexture.width,
                                                                 height: inTexture.height,
                                                                 mipmapped: false)
textureDescriptor.usage = .shaderWrite
let outTexture = context.device.makeTexture(descriptor: textureDescriptor)!

let commandBuffer = context.makeCommandBuffer()

let blurFilter = MPSImageGaussianBlur(device: context.device, sigma: 10)
blurFilter.encode(commandBuffer: commandBuffer, sourceTexture: inTexture, destinationTexture: outTexture)

commandBuffer.commit()
commandBuffer.waitUntilCompleted()

image(from: outTexture)

//: [Next](@next)
