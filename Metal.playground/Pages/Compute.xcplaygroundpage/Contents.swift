//
//  Compute.playground
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

//: [Previous](@previous)

import Foundation
import Cocoa
import Metal
import MetalKit

let context = MetalContext.shared
let library = context.makeLibary(name: "Compute")
let kernelFunction = library.makeFunction(name: "grayscale")!
let pipelineState = context.makeComputePipelineState(function: kernelFunction)

let inputImage = NSImage(named: "girl")!
let inTexture = texture(from: inputImage)

let width = inTexture.width, height = inTexture.height
let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                 width: width,
                                                                 height: height,
                                                                 mipmapped: false)
textureDescriptor.usage = .shaderWrite
let outTexture = context.makeTexture(descriptor: textureDescriptor)

// The number of threads per threadgroup
let threadsPerThreadgroup = MTLSize(width: pipelineState.threadExecutionWidth,
                                    height: pipelineState.maxTotalThreadsPerThreadgroup / pipelineState.threadExecutionWidth,
                                    depth: 1)
// The number of threadgroups per grid
let threadgroupsPerGrid = MTLSize(width: (width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                  height: (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                  depth: 1)

let commandBuffer = context.makeCommandBuffer()

let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
commandEncoder.setComputePipelineState(pipelineState)
commandEncoder.setTexture(inTexture, index: 0)
commandEncoder.setTexture(outTexture, index: 1)
commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
commandEncoder.endEncoding()

commandBuffer.commit()
commandBuffer.waitUntilCompleted()

image(from: outTexture)

//: [Next](@next)
