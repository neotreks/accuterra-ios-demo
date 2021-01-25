//
//  MediaLoader.swift
//  DemoApp
//
//  Created by Rudolf Kopřiva on 07/09/2020.
//  Copyright © 2020 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import UIKit

protocol MediaLoader : class {
    func load(callback: @escaping (MediaLoader, UIImage?) -> Void)
}
