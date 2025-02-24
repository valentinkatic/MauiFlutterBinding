//
//  Binding.swift
//  Binding
//

import Flutter
import FlutterPluginRegistrant
import Foundation
import PDFKit
import SwiftUI

@objc(Binding)
public class SwiftBinding: NSObject {
    var callback: StringCallback?

    @objc
    public func async(parameters: [String], callback: @escaping StringCallback) {
        self.callback = callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.callback?("\(parameters[0]) \(parameters[1])")
        }
    }
    
    @objc
    public func getFlutterViewController() -> UIViewController {
        let flutterEngine = FlutterEngine(name: "my flutter engine")
        flutterEngine.run()
        
        // This is crucial - without this, plugins won't work
        GeneratedPluginRegistrant.register(with: flutterEngine)
        
        return FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    }
}
