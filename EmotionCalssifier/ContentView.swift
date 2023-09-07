//
//  ContentView.swift
//  EmotionCalssifier
//
//  Created by SALGARA, YESKENDIR on 06.09.23.
//

import CoreML
import SwiftUI

struct ContentView: View {
    
    let imageName: String = "sad"
    @State var answer: String = ""
    
    var body: some View {
        VStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 400, height: 400)
            HStack {
                Text("Emotion:")
                    .font(.largeTitle)
                Text(answer)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .onAppear {
            answer = predict(with: imageName)?.classLabel ?? "undefined"
        }
    }
    
    func predict(with imageName: String) -> EmotionClassifierOutput? {
        do {
            let config = MLModelConfiguration()
            let model = try EmotionClassifier(configuration: config)
            guard let image = UIImage(named: imageName) else { return nil }
            let pixelBuffer = pixelBufferFromImage(image: image)
            let prediction = try model.prediction(image: pixelBuffer)
            return prediction
        } catch {
            assertionFailure(error.localizedDescription)
        }
        return nil
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


func pixelBufferFromImage(image: UIImage) -> CVPixelBuffer {
    let ciimage = CIImage(image: image)
    //let cgimage = convertCIImageToCGImage(inputImage: ciimage!)
    let tmpcontext = CIContext(options: nil)
    let cgimage =  tmpcontext.createCGImage(ciimage!, from: ciimage!.extent)
    let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
    let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
    let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
    let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
    let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
    let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
    keysPointer.initialize(to: keys)
    valuesPointer.initialize(to: values)
    let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
    let width = cgimage!.width
    let height = cgimage!.height
    var pxbuffer: CVPixelBuffer?
    // if pxbuffer = nil, you will get status = -6661
    var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                     kCVPixelFormatType_32BGRA, options, &pxbuffer)
    status = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
    let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer!);
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer!)
    let context = CGContext(data: bufferAddress,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: bytesperrow,
                            space: rgbColorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue);
    context?.concatenate(CGAffineTransform(rotationAngle: 0))
    context?.concatenate(__CGAffineTransformMake( 1, 0, 0, -1, 0, CGFloat(height) )) //Flip Vertical
    //        context?.concatenate(__CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGFloat(width), 0.0)) //Flip Horizontal
    
    context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)));
    status = CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
    return pxbuffer!;
}
