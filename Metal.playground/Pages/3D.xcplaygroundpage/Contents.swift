//
//  3D.playground
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

//: [Previous](@previous)

import Foundation
import Cocoa
import Metal
import MetalKit
import simd
import PlaygroundSupport

struct Vertex {
    let position: float4
    let color: float4
}

struct Uniforms {
    let modelViewProjectionMatrix: float4x4
}

final class Render: NSObject, MTKViewDelegate {
    let vertices = [
        Vertex(position: float4(-1, 1, 1, 1), color: vector_float4(0, 1, 1, 1)),
        Vertex(position: float4(-1, -1, 1, 1), color: vector_float4(0, 0, 1, 1)),
        Vertex(position: float4(1, -1, 1, 1), color: vector_float4(1, 0, 1, 1)),
        Vertex(position: float4(1, 1, 1, 1), color: vector_float4(1, 1, 1, 1)),
        Vertex(position: float4(-1, 1, -1, 1), color: vector_float4(0, 1, 0, 1)),
        Vertex(position: float4(-1, -1, -1, 1), color: vector_float4(0, 0, 0, 1)),
        Vertex(position: float4(1, -1, -1, 1), color: vector_float4(1, 0, 0, 1)),
        Vertex(position: float4(1, 1, -1, 1), color: vector_float4(1, 1, 0, 1))
    ]
    let indices = [
        3, 2, 6, 6, 7, 3,
        4, 5, 1, 1, 0, 4,
        4, 0, 3, 3, 7, 4,
        1, 5, 6, 6, 2, 1,
        0, 1, 2, 2, 3, 0,
        7, 6, 5, 5, 4, 7
    ] as [UInt16]
    
    let context = MetalContext.shared
    let mtkView: MTKView
    let library: MTLLibrary
    let displaySemaphore: DispatchSemaphore
    var renderPipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    var bufferIndex = 0
    var rotationX = 0 as Float
    var rotationY = 0 as Float
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        self.library = context.makeLibary(name: "3D")
        self.displaySemaphore = DispatchSemaphore(value: 3)
        super.init()
        
        mtkView.device = context.device
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        buildRenderPipeline()
        buildDepthStencilState()
        buildBuffer()
    }
    
    func buildRenderPipeline() {
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderPipelineState = context.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func buildDepthStencilState() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = context.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func buildBuffer() {
        vertexBuffer = context.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.size * vertices.count)
        indexBuffer = context.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.size * indices.count)
        uniformBuffer = context.makeBuffer(length: MemoryLayout<Uniforms>.size * 3)
    }
    
    func updateUniforms(duration: Float) {
        rotationX += duration * (.pi / 2)
        rotationY += duration * (.pi / 3)
        let scaleFactor = 1 as Float
        let xAxis = float3(1, 0, 0)
        let yAxis = float3(0, 1, 0)
        let xRot = float4x4(rotationAbout: xAxis, by: rotationX)
        let yRot = float4x4(rotationAbout: yAxis, by: rotationY)
        let scale = float4x4(scaleBy: scaleFactor)
        let modelMatrix = xRot * yRot * scale
        
        let cameraTranslation = float3(0, 0, -5)
        let viewMatrix = float4x4(translationBy: cameraTranslation)
        
        let drawableSize = mtkView.drawableSize
        let aspect = Float(drawableSize.width) / Float(drawableSize.height)
        let fov = (2 * Float.pi) / 5
        let near = 1 as Float
        let far = 100 as Float
        let projectionMatrix = float4x4(perspectiveProjectionFov: fov, aspectRatio: aspect, nearZ: near, farZ: far)
        
        var uniforms = Uniforms(modelViewProjectionMatrix: projectionMatrix * viewMatrix * modelMatrix)
        uniformBuffer.contents().advanced(by: MemoryLayout<Uniforms>.size * bufferIndex).copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.size)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        displaySemaphore.wait()
        
        updateUniforms(duration: 1 / Float(mtkView.preferredFramesPerSecond))
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable else {
            return
        }
        
        let commandBuffer = context.makeCommandBuffer()
        
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(renderPipelineState)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise) // clockwise: 顺时针 counter clockwise: 逆时针
        commandEncoder.setCullMode(.back)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: MemoryLayout<Uniforms>.size * bufferIndex, index: 1)
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        commandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { [unowned self] buffer in
            self.bufferIndex = (self.bufferIndex + 1) % 3
            self.displaySemaphore.signal()
        }
        commandBuffer.commit()
    }
}

let mtkView = MTKView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
let render = Render(mtkView: mtkView)
render.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
mtkView.delegate = render

PlaygroundPage.current.liveView = mtkView

//: [Next](@next)
