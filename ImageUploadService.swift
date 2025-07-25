//
//  ImageUploadService.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 25/7/2025.
//
//  ImageUploadService.swift
//  MyMarkBook
//

import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit
import Combine

// MARK: - Image Upload Service Protocol
protocol ImageUploadServiceProtocol {
    func uploadImageAndLinkToStudent(image: UIImage, student: Student) async throws -> String
    func uploadImage(_ image: UIImage, to path: String) async throws -> String
    func deleteImage(at url: String) async throws
    func downloadImage(from url: String) async throws -> UIImage
}

// MARK: - Firebase Image Upload Service
class ImageUploadService: ObservableObject, ImageUploadServiceProtocol {

    // MARK: - Properties
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var error: Error?

    private let storage = Storage.storage()
    private let studentRepository: StudentRepository

    // Storage paths
    private let assessmentsPath = "assessments"
    private let maxImageSize: Int = 10 * 1024 * 1024 // 10MB
    private let allowedImageTypes: Set<String> = ["image/jpeg", "image/png", "image/heic"]

    // MARK: - Initialization
    init(studentRepository: StudentRepository = StudentRepository()) {
        self.studentRepository = studentRepository
    }

    // MARK: - Public Methods

    /// Main method: Uploads image to Firebase Storage and links it to a student
    @MainActor
    func uploadImageAndLinkToStudent(image: UIImage, student: Student) async throws -> String {
        guard let studentId = student.id else {
            throw ImageUploadError.missingStudentID
        }

        isUploading = true
        uploadProgress = 0.0
        error = nil

        do {
            // Step 1: Compress and validate image
            guard let imageData = await compressImage(image) else {
                throw ImageUploadError.imageCompressionFailed
            }

            uploadProgress = 0.2

            // Step 2: Generate unique file path
            let fileName = generateFileName(for: studentId)
            let storagePath = "\(assessmentsPath)/\(studentId)/\(fileName)"

            uploadProgress = 0.3

            // Step 3: Upload to Firebase Storage
            let downloadURL = try await uploadImageData(imageData, to: storagePath)

            uploadProgress = 0.8

            // Step 4: Link to student record
            try await studentRepository.addImageURLToStudent(studentId: studentId, imageURL: downloadURL)

            uploadProgress = 1.0

            print("✅ Successfully uploaded and linked image for student: \(student.name)")
            return downloadURL

        } catch {
            print("❌ Error uploading image for student \(student.name): \(error)")
            self.error = error
            throw error
            isUploading = false
        }
    }

    /// Uploads an image to a specific path in Firebase Storage
    func uploadImage(_ image: UIImage, to path: String) async throws -> String {
        guard let imageData = await compressImage(image) else {
            throw ImageUploadError.imageCompressionFailed
        }

        return try await uploadImageData(imageData, to: path)
    }

    /// Deletes an image from Firebase Storage and removes from student record
    func deleteImage(at url: String) async throws {
        do {
            // Step 1: Delete from Firebase Storage
            let storageRef = storage.reference(forURL: url)
            try await storageRef.delete()

            // Step 2: Find and update student record
            if let student = findStudentByImageURL(url) {
                try await studentRepository.removeImageURLFromStudent(
                    studentId: student.id!,
                    imageURL: url
                )
            }

            print("✅ Successfully deleted image: \(url)")

        } catch {
            print("❌ Error deleting image: \(error)")
            throw ImageUploadError.deletionFailed(error)
        }
    }

    /// Downloads an image from Firebase Storage
    func downloadImage(from url: String) async throws -> UIImage {
        do {
            let storageRef = storage.reference(forURL: url)
            let data = try await storageRef.data(maxSize: Int64(maxImageSize))

            guard let image = UIImage(data: data) else {
                throw ImageUploadError.invalidImageData
            }

            return image

        } catch {
            print("❌ Error downloading image: \(error)")
            throw ImageUploadError.downloadFailed(error)
        }
    }

    // MARK: - Batch Operations

    /// Uploads multiple images for a student
    func uploadMultipleImages(_ images: [UIImage], for student: Student) async throws -> [String] {
        var uploadedURLs: [String] = []

        for (index, image) in images.enumerated() {
            do {
                let url = try await uploadImageAndLinkToStudent(image: image, student: student)
                uploadedURLs.append(url)

                // Update progress for multiple uploads
                await MainActor.run {
                    uploadProgress = Double(index + 1) / Double(images.count)
                }

            } catch {
                print("❌ Failed to upload image \(index + 1): \(error)")
                // Continue with remaining images
            }
        }

        return uploadedURLs
    }

    /// Deletes all images for a specific student
    func deleteAllImagesForStudent(_ student: Student) async throws {
        guard let studentId = student.id else {
            throw ImageUploadError.missingStudentID
        }

        for imageURL in student.imageURLs {
            do {
                try await deleteImage(at: imageURL)
            } catch {
                print("❌ Failed to delete image \(imageURL): \(error)")
                // Continue with remaining images
            }
        }
    }

    // MARK: - Utility Methods

    /// Gets storage usage statistics for a student
    func getStorageUsage(for student: Student) async throws -> StorageUsage {
        var totalSize: Int64 = 0
        var imageCount = student.imageURLs.count

        for imageURL in student.imageURLs {
            do {
                let storageRef = storage.reference(forURL: imageURL)
                let metadata = try await storageRef.getMetadata()
                totalSize += metadata.size
            } catch {
                print("⚠️ Could not get metadata for image: \(imageURL)")
            }
        }

        return StorageUsage(
            imageCount: imageCount,
            totalSizeBytes: totalSize,
            totalSizeMB: Double(totalSize) / (1024 * 1024)
        )
    }

    /// Validates image before upload
    func validateImage(_ image: UIImage) -> ValidationResult {
        var issues: [String] = []

        // Check image size
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return ValidationResult(isValid: false, issues: ["Could not process image data"])
        }

        if imageData.count > maxImageSize {
            issues.append("Image size exceeds \(maxImageSize / (1024 * 1024))MB limit")
        }

        // Check dimensions (optional - you can set limits)
        let maxDimension: CGFloat = 4096
        if image.size.width > maxDimension || image.size.height > maxDimension {
            issues.append("Image dimensions exceed \(Int(maxDimension))px limit")
        }

        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }

    // MARK: - Private Methods

    private func uploadImageData(_ data: Data, to path: String) async throws -> String {
        let storageRef = storage.reference().child(path)

        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uploadedBy": Auth.auth().currentUser?.uid ?? "unknown",
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "version": "1.0"
        ]

        do {
            // Upload with progress tracking
            let _ = try await storageRef.putDataAsync(data, metadata: metadata) { [weak self] progress in
                guard let self = self else { return }

                let progressValue = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

                Task { @MainActor in
                    self.uploadProgress = 0.3 + (progressValue * 0.5) // 30% to 80% of total progress
                }
            }

            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString

        } catch {
            throw ImageUploadError.uploadFailed(error)
        }
    }

    private func compressImage(_ image: UIImage) async -> Data? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Start with high quality and reduce if needed
                var compressionQuality: CGFloat = 0.8
                var imageData = image.jpegData(compressionQuality: compressionQuality)

                // Reduce quality until under size limit
                while let data = imageData, data.count > self.maxImageSize && compressionQuality > 0.1 {
                    compressionQuality -= 0.1
                    imageData = image.jpegData(compressionQuality: compressionQuality)
                }

                continuation.resume(returning: imageData)
            }
        }
    }

    private func generateFileName(for studentId: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "\(studentId)_\(timestamp)_\(uuid).jpg"
    }

    private func findStudentByImageURL(_ url: String) -> Student? {
        return studentRepository.students.first { student in
            student.imageURLs.contains(url)
        }
    }
}

// MARK: - Supporting Types

/// Storage usage information for a student
struct StorageUsage {
    let imageCount: Int
    let totalSizeBytes: Int64
    let totalSizeMB: Double

    var formattedSize: String {
        if totalSizeMB < 1.0 {
            return String(format: "%.1f KB", Double(totalSizeBytes) / 1024)
        } else {
            return String(format: "%.1f MB", totalSizeMB)
        }
    }
}

/// Image validation result
struct ValidationResult {
    let isValid: Bool
    let issues: [String]
}

/// Custom errors for image upload operations
enum ImageUploadError: LocalizedError {
    case missingStudentID
    case imageCompressionFailed
    case uploadFailed(Error)
    case deletionFailed(Error)
    case downloadFailed(Error)
    case invalidImageData
    case fileSizeExceedsLimit
    case unsupportedImageType
    case networkError
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .missingStudentID:
            return "Student ID is missing"
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .deletionFailed(let error):
            return "Deletion failed: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .invalidImageData:
            return "Invalid image data"
        case .fileSizeExceedsLimit:
            return "File size exceeds limit"
        case .unsupportedImageType:
            return "Unsupported image type"
        case .networkError:
            return "Network error occurred"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}

// MARK: - Firebase Storage Extensions
extension StorageReference {
    func putDataAsync(_ data: Data, metadata: StorageMetadata? = nil, onProgress: @escaping (Progress) -> Void) async throws -> StorageMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let metadata = metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: ImageUploadError.uploadFailed(NSError(domain: "Unknown error", code: -1)))
                }
            }

            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    onProgress(progress)
                }
            }
        }
    }
}
