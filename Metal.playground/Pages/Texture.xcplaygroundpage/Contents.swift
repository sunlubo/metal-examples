//
//  Texture.playground
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

func texture(from image: CGImage) -> MTLTexture? {
    let width = image.width, height = image.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerRow * height)
    rawData.initialize(to: 0)
    defer {
        rawData.deallocate()
    }
    let context = CGContext(data: rawData,
                            width: width,
                            height: height,
                            bitsPerComponent: bitsPerComponent,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
    // Flip the context so the positive Y axis points down
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: false)
    let texture = MetalContext.shared.device.makeTexture(descriptor: textureDescriptor)
    texture?.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
    return texture
}

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
    var samplerState: MTLSamplerState!
    var renderPipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var meshes: [MTKMesh] = []
    var baseColorTexture: MTLTexture?
    var time: Float = 0
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        self.device = context.device
        self.library = context.makeLibary(name: "Texture")
        super.init()
        
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
        buildVertexDescriptor()
        buildSamplerState()
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
    
    func buildSamplerState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)!
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
        
        let textureLoader = MTKTextureLoader(device: context.device)
        let options = [.generateMipmaps: true, .SRGB: true] as [MTKTextureLoader.Option: Any]
        baseColorTexture = try? textureLoader.newTexture(URL: Bundle.main.url(forResource: "tiles_baseColor", withExtension: "jpg")!, options: options)
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
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
        
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
