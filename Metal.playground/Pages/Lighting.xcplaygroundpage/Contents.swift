//
//  Lighting.playground
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

//: [Previous](@previous)

import Foundation
import Cocoa
import Metal
import MetalKit
import ModelIO
import simd
import PlaygroundSupport

struct Uniforms {
    let modelMatrix: float4x4
    let viewProjectionMatrix: float4x4
    let normalMatrix: float3x3
}

final class Render: NSObject, MTKViewDelegate {
    let context = MetalContext.shared
    let mtkView: MTKView
    let device: MTLDevice
    let library: MTLLibrary
    var vertexDescriptor: MDLVertexDescriptor!
    var renderPipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var samplerState: MTLSamplerState!
    var meshes: [MTKMesh] = []
    var time: Float = 0
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        self.device = context.device
        self.library = context.makeLibary(name: "Lighting")
        super.init()
        
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
        buildVertexDescriptor()
        loadResources()
        buildRenderPipeline()
        buildDepthStencilState()
    }
    
    func buildVertexDescriptor() {
        vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
    }
    
    func loadResources() {
        let modelURL = Bundle.main.url(forResource: "teapot", withExtension: "obj")!
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        do {
            (_, meshes) = try MTKMesh.newMeshes(asset: asset, device: device)
        } catch {
            fatalError("Could not extract meshes from Model I/O asset.")
        }
    }
    
    func buildRenderPipeline() {
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        renderPipelineState = context.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func buildDepthStencilState() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = context.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable else {
            return
        }
        
        let commandBuffer = context.makeCommandBuffer()
        
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(renderPipelineState)
        commandEncoder.setDepthStencilState(depthStencilState)
        
        time += 1 / Float(mtkView.preferredFramesPerSecond)
        let angle = -time
        let modelMatrix = float4x4(rotationAbout: float3(0, 1, 0), by: angle) * float4x4(scaleBy: 2)
        
        let viewMatrix = float4x4(translationBy: float3(0, 0, -2))
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        let projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        
        var uniforms = Uniforms(modelMatrix: modelMatrix, viewProjectionMatrix: viewProjectionMatrix, normalMatrix: modelMatrix.normalMatrix)
        commandEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        
        for mesh in meshes {
            let vertexBuffer = mesh.vertexBuffers.first!
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        
        commandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

let mtkView = MTKView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
let render = Render(mtkView: mtkView)
render.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
mtkView.delegate = render

PlaygroundPage.current.liveView = mtkView

//: [Next](@next)
