import UIKit

public struct Pixel {
    public var value: UInt32
    
    public var red: UInt8 {
        get {
            return UInt8(value & 0xFF)
        }
        set {
            value = UInt32(newValue) | (value & 0xFFFFFF00)
        }
    }

    public var green: UInt8 {
        get {
            return UInt8((value >> 8) & 0xFF)
        }
        set {
            value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF)
        }
    }
    
    public var blue: UInt8 {
        get {
            return UInt8((value >> 16) & 0xFF)
        }
        set {
            value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF)
        }
    }
    
    public var alpha: UInt8 {
        get {
            return UInt8((value >> 24) & 0xFF)
        }
        set {
            value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF)
        }
    }
}

public struct RGBAImage {
    public var pixels: UnsafeMutableBufferPointer<Pixel>
    
    public var width: Int
    public var height: Int
    
    public init?(image: UIImage) {
        guard let cgImage = image.CGImage else { return nil }
        
        // Redraw image for correct pixel format
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
        
        width = Int(image.size.width)
        height = Int(image.size.height)
        let bytesPerRow = width * 4
        
        let imageData = UnsafeMutablePointer<Pixel>.alloc(width * height)
        
        guard let imageContext = CGBitmapContextCreate(imageData, width, height, 8, bytesPerRow, colorSpace, bitmapInfo) else { return nil }
        CGContextDrawImage(imageContext, CGRect(origin: CGPointZero, size: image.size), cgImage)

        pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
    }
    
    public func toUIImage() -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
        
        let bytesPerRow = width * 4

        let imageContext = CGBitmapContextCreateWithData(pixels.baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo, nil, nil)
        
        guard let cgImage = CGBitmapContextCreateImage(imageContext) else {return nil}
        let image = UIImage(CGImage: cgImage)
        
        return image
    }
}


class ImageProcessor {
    var coeff:Double? = nil
    var image:UIImage? = nil
    var cache:RGBAImage?=nil
    var output:UIImage? = nil
    var method:((Pixel) -> Pixel)?=nil
    var mean:Double?=nil
    var property:String?=nil
    
    init(img:UIImage){
        self.method=nil
        self.image=img
        self.cache = RGBAImage(image: self.image!)
        self.updateMean()
    }
    
    func addFilter(property:String,coeff:Double?=nil){
        self.coeff=coeff
        self.property=property
        self.methodChoose(property)
        self.applyFilter()
    }
    
    func resetCoeff(coeff:Double){
        var c=coeff
        if(c<0.001){c=0.001}
        switch(self.property!){
        case "gray":
            self.coeff=c*100
        case "brightness":
            self.coeff=c*100
        case "contrast":
            self.coeff=c*3
        case "inverse":
            self.coeff=c
        case "noise":
            self.coeff=c*50
        default:
            self.coeff=nil
        }
        self.methodChoose(self.property!)
        self.applyFilter()
    }
    
    func methodChoose(property:String){
        switch(property){
        case "gray":
            if(self.coeff==nil){self.coeff=50}
            let s:Double=self.coeff!/100*255/self.mean!
            func gray(var p:Pixel)->Pixel{
                let m=(Double(p.red)+Double(p.green)+Double(p.blue))/3
                return assignPixel(p, r: m*s,g: m*s,b: m*s)
            }
            self.method=gray            
        case "brightness":
            if(self.coeff==nil){self.coeff=50}
            if(self.coeff<0||self.coeff>100){
                self.printUsage()
                break
            }
            let s:Double=self.coeff!/100*255/self.mean!
            func brightness(var p:Pixel)->Pixel{
                let b=Double(p.blue)*s
                let r=Double(p.red)*s
                let g=Double(p.green)*s
                return assignPixel(p, r: r, g: g, b: b)
            }
            self.method=brightness
            
        case "contrast":
            if(self.coeff==nil){self.coeff=2}
            if(self.coeff==nil||self.coeff<0||self.coeff>10){
                self.printUsage()
                break
            }
            func contrast(var p:Pixel)->Pixel{
                let b=self.mean!+(Double(p.blue)-self.mean!)*self.coeff!
                let r=self.mean!+(Double(p.red)-self.mean!)*self.coeff!
                let g=self.mean!+(Double(p.green)-self.mean!)*self.coeff!
                return assignPixel(p, r: r, g: g, b: b)
            }
            self.method=contrast
            
        case "inverse":
            if(self.coeff==nil){self.coeff=1}
            func inverse(var p:Pixel)->Pixel{
                let r=Double(p.red)+(255-Double(p.red)*2)*self.coeff!
                let g=Double(p.green)+(255-Double(p.green)*2)*self.coeff!
                let b=Double(p.blue)+(255-Double(p.blue)*2)*self.coeff!
                return assignPixel(p, r: r, g: g, b: b)
            }
            self.method=inverse
        case "noise":
            if(self.coeff==nil){self.coeff=50}
            if(self.coeff==nil||self.coeff<0||self.coeff>200){
                self.printUsage()
                break
            }
            func noise(var p:Pixel)->Pixel{
                let n=Double(arc4random_uniform(UInt32(self.coeff!*2))) - self.coeff!
                return assignPixel(p, r: Double(p.red)+Double(n), g: Double(p.green)+Double(n), b: Double(p.blue)+Double(n))
            }
            self.method=noise
            
        default:
            self.method=nil
            self.printUsage()
        }
    }
    
    func assignPixel(var p:Pixel,r:Double,g:Double,b:Double)->Pixel{
        func range(a:Double)->UInt8{
            if(a<1) {return 1}
            if(a>255) {return 255}
            return UInt8(a)
        }
        p.green=range(g)
        p.red=range(r)
        p.blue=range(b)
        return p
    }
    
    func updateMean(){
        var m:Double=0
        for i in 0..<cache!.width*cache!.height{
            let pixel=cache!.pixels[i]
            m=m+Double(pixel.red)+Double(pixel.green)+Double(pixel.blue)
        }
        m=m/3/Double(cache!.width)/Double(cache!.height)
        self.mean=m
    }
    
    func applyFilter(){
        
        if((self.method) != nil){self.loop()}
        self.method=nil
    }
    
    func loop(){
        self.cache = RGBAImage(image: self.image!)
        for i in 0..<cache!.width*cache!.height{
            let pixel=cache!.pixels[i]
            cache!.pixels[i]=method!(pixel)
        }
    }
    
    func getImage()->UIImage?{
        self.output=self.cache!.toUIImage()!
        return self.output!
    }
    
    func printUsage(){
    }
}
