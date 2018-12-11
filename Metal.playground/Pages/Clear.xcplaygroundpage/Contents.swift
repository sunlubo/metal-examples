//
//  Clear.playground
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

//: [Previous](@previous)

import Foundation
import Cocoa
import Metal
import simd
import PlaygroundSupport

final class MetalView: NSView {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var metalLayer: CAMetalLayer {
        return layer as! CAMetalLayer
    }
    
    override init(frame: CGRect) {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func makeBackingLayer() -> CALayer {
        let metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.drawableSize = frame.size
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
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 0, 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

let metalView = MetalView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
metalView.wantsLayer = true
PlaygroundPage.current.liveView = metalView

//: [Next](@next)
