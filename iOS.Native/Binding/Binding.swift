//
//  Binding.swift
//  Binding
//

import Flutter
import Foundation
import PDFKit
import SwiftUI

@objc(Binding)
public class SwiftBinding: NSObject {
    @objc
    public func getFlutterViewController() -> UIViewController {
        let flutterEngine = FlutterEngine(name: "my flutter engine")
        flutterEngine.run()
        return FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    }
}
