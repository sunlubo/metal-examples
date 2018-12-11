//
//  2D.playground
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

//: [Previous](@previous)

import Foundation
import Cocoa
import Metal
import simd
import PlaygroundSupport

struct Vertex {
    let position: float4
    let color: float4
}

class MetalView: NSView {
    let vertices = [
        Vertex(position: float4(0, 0.5, 0, 1), color: vector_float4(1, 0, 0, 1)),
        Vertex(position: float4(-0.5, -0.5, 0, 1), color: vector_float4(0, 1, 0, 1)),
        Vertex(position: float4(0.5, -0.5, 0, 1), color: vector_float4(0, 0, 1, 1))
    ]
    
    let context = MetalContext.shared
    let library: MTLLibrary
    var renderPipelineState: MTLRenderPipelineState!
    
    var metalLayer: CAMetalLayer {
        return layer as! CAMetalLayer
    }
    
    override init(frame: CGRect) {
        self.library = context.makeLibary(name: "2D")
        super.init(frame: frame)
        
        buildRenderPipeline()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildRenderPipeline() {
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineState = context.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    override func makeBackingLayer() -> CALayer {
        let metalLayer = CAMetalLayer()
        metalLayer.device = context.device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.drawableSize = CGSize(width: bounds.width * 2, height: bounds.height * 2)
        return metalLayer
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        redraw()
    }
    
    func redraw() {
        guard let drawable = metalLayer.nextDrawable() else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = context.makeCommandBuffer()
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBytes(vertices, length: MemoryLayout<Vertex>.size * vertices.count, index: 0)
        renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderCommandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

let metalView = MetalView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
metalView.wantsLayer = true
PlaygroundPage.current.liveView = metalView

//: [Next](@next)
