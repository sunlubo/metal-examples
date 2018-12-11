//
//  MetalContext.swift
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

import Foundation
import Metal

public final class MetalContext {
    public static let shared = MetalContext()
    
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    
    public init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
    }
    
    public func makeLibary(name: String) -> MTLLibrary {
        let resource = Bundle.main.url(forResource: name, withExtension: "metal")!
        do {
            return try device.makeLibrary(source: String(contentsOf: resource), options: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) -> MTLRenderPipelineState {
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func makeComputePipelineState(function: MTLFunction) -> MTLComputePipelineState {
        do {
            return try device.makeComputePipelineState(function: function)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func makeDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> MTLDepthStencilState {
        return device.makeDepthStencilState(descriptor: descriptor)!
    }
    
    public func makeCommandBuffer() -> MTLCommandBuffer {
        return commandQueue.makeCommandBuffer()!
    }
    
    public func makeTexture(descriptor: MTLTextureDescriptor) -> MTLTexture {
        return device.makeTexture(descriptor: descriptor)!
    }
    
    public func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MTLResourceOptions = []) -> MTLBuffer {
        return device.makeBuffer(bytes: bytes, length: length, options: options)!
    }
    
    public func makeBuffer(length: Int, options: MTLResourceOptions = []) -> MTLBuffer {
        return device.makeBuffer(length: length, options: options)!
    }
}
