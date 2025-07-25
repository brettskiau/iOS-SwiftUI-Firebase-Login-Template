//
//  UploadModels.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 25/7/2025.
//

// UploadModels.swift
import Foundation
import UIKit

// MARK: - Upload Stages
enum UploadStage {
    case idle
    case uploading
    case scanning
    case confirm
    case manualSelect
}

// MARK: - Upload State
struct UploadState {
    var stage: UploadStage = .idle
    var progress: Double = 0.0
    var detectedStudent: Student? = nil
    var selectedImage: UIImage? = nil
    var isActive: Bool = false
    var searchQuery: String = ""
}

// MARK: - Image Source Type
enum ImageSourceType {
    case camera
    case photoLibrary
    case file
}
