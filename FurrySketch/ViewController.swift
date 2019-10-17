//
//  ViewController.swift
//  FurrySketch
//
//  Created by Simon Gladman on 25/11/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//


import UIKit

class ViewController: UIViewController
{
    
    let halfPi = CGFloat.pi / 2
    let imageView = UIImageView()
    let compositeFilter = CIFilter(name: "CISourceOverCompositing")!
    
    let slider = UISlider()
    var hue = CGFloat(0)
    
    lazy var imageAccumulator: CIImageAccumulator =
    {
        [unowned self] in
        return CIImageAccumulator(extent: self.view.frame, format: .ARGB8)!
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        slider.maximumValue = 1
        slider.addTarget(self, action: #selector(sliderChangeHandler), for: .valueChanged)
        
        view.addSubview(imageView)
        view.addSubview(slider)
        
        view.backgroundColor =  .black
        
        sliderChangeHandler()
    }
    
    @objc func sliderChangeHandler()
    {
        hue = CGFloat(slider.value)
        
        slider.minimumTrackTintColor = color
        slider.maximumTrackTintColor = color
        slider.thumbTintColor = color
    }
    
    var color: UIColor
        {
            return UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        if motion == .motionShake
        {
            imageAccumulator.clear()
            imageAccumulator.setImage(CIImage(color: CIColor(string: "00000000")))
            
            imageView.image = nil
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first,
            let coalescedTouces = event?.coalescedTouches(for: touch),
            touch.type == .stylus else
        {
            return
        }
        
        UIGraphicsBeginImageContext(view.frame.size)
        
        let cgContext = UIGraphicsGetCurrentContext()!
        
        cgContext.setLineWidth(1)
        
        cgContext.setStrokeColor(self.color.withAlphaComponent(0.025).cgColor)
        
        for coalescedTouch in coalescedTouces
        {
            let touchLocation = coalescedTouch.location(in: view)
            
            let normalisedAlititudeAngle =  (halfPi - touch.altitudeAngle) / halfPi
            let dx = coalescedTouch.azimuthUnitVector(in: view).dx * 20 * normalisedAlititudeAngle
            let dy = coalescedTouch.azimuthUnitVector(in: view).dy * 20 * normalisedAlititudeAngle
            
            let count = 10 + Int((coalescedTouch.force / coalescedTouch.maximumPossibleForce) * 100)
            
            for _ in 0 ... count
            {
                let randomAngle = drand48() * .pi * 2
                
                let innerRandomRadius = drand48() * 20
                let innerRandomX = CGFloat(sin(randomAngle) * innerRandomRadius)
                let innerRandomY = CGFloat(cos(randomAngle) * innerRandomRadius)
                            
                let outerRandomRadius = innerRandomRadius + drand48() * 40 * Double(normalisedAlititudeAngle)
                let outerRandomX = CGFloat(sin(randomAngle) * outerRandomRadius) - dx
                let outerRandomY = CGFloat(cos(randomAngle) * outerRandomRadius) - dy

                cgContext.move(to: CGPoint(x: touchLocation.x + innerRandomX, y: touchLocation.y + innerRandomY))
    
                cgContext.addLine(to: CGPoint(x: touchLocation.x + outerRandomX, y: touchLocation.y + outerRandomY))
    
                cgContext.strokePath()
            }
        }
        
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        guard let image = drawnImage else { return }

        compositeFilter.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        compositeFilter.setValue(imageAccumulator.image(), forKey: kCIInputBackgroundImageKey)
        
        imageAccumulator.setImage(compositeFilter.value(forKey: kCIOutputImageKey) as! CIImage)
        
        imageView.image = UIImage(ciImage: imageAccumulator.image())
    }
    
    override func viewDidLayoutSubviews()
    {
        imageView.frame = view.bounds
        
        slider.frame = CGRect(x: 0,
                              y: view.frame.height - slider.intrinsicContentSize.height - 20,
                              width: view.frame.width,
                              height: slider.intrinsicContentSize.height).insetBy(dx: 20, dy: 0)
    }
}
