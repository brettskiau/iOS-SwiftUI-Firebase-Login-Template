//
//  UploadAssessmentViewModel.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 25/7/2025.
//

//
//  UploadAssessmentViewModel.swift
//  MyMarkBook
//

import SwiftUI
import PhotosUI
import Vision
import UIKit
import FirebaseAuth
import Combine

// MARK: - Upload Assessment ViewModel
@MainActor
class UploadAssessmentViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var uploadState = UploadState()
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var showingImagePicker = false
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Published var errorMessage: String?
    @Published var showingError = false

    // Progress tracking
    @Published var overallProgress: Double = 0.0
    @Published var currentStage: String = ""

    // Dependencies
    let studentRepository: StudentRepository
    let imageUploadService: ImageUploadService
    let qrDetectionService: QRCodeDetectionService

    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        studentRepository: StudentRepository,
        imageUploadService: ImageUploadService,
        qrDetectionService: QRCodeDetectionService
    ) {
        self.studentRepository = studentRepository
        self.imageUploadService = imageUploadService
        self.qrDetectionService = qrDetectionService

        setupSubscriptions()
    }

    // MARK: - Public Methods

    /// Handles image source selection (camera, photo library, file)
    func selectImageSource(_ sourceType: ImageSourceType) {
        switch sourceType {
        case .camera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                showError("Camera is not available on this device")
                return
            }
            self.sourceType = .camera
            showingImagePicker = true

        case .photoLibrary:
            self.sourceType = .photoLibrary
            showingImagePicker = true

        case .file:
            // Future implementation for file picker
            showError("File upload will be available soon")
        }
    }

    /// Main method to process an uploaded image
    func processImage(_ image: UIImage) {
        // Reset state
        resetUploadState()

        // Validate image first
        let validation = imageUploadService.validateImage(image)
        guard validation.isValid else {
            showError("Image validation failed: \(validation.issues.joined(separator: ", "))")
            return
        }

        uploadState.selectedImage = image
        uploadState.isActive = true
        uploadState.stage = .uploading
        uploadState.progress = 0.0
        overallProgress = 0.0
        currentStage = "Preparing image..."

        Task {
            await performUploadFlow(image: image)
        }
    }

    /// Confirms assignment of image to detected student
    func confirmAssignment() {
        guard let student = uploadState.detectedStudent,
              let image = uploadState.selectedImage else {
            showError("Missing student or image data")
            return
        }

        uploadState.stage = .uploading
        currentStage = "Uploading to \(student.name)..."

        Task {
            await uploadImageToStudent(image: image, student: student)
        }
    }

    /// Selects a student manually when QR code detection fails
    func selectStudent(_ student: Student) {
        uploadState.detectedStudent = student
        uploadState.stage = .confirm
        currentStage = "Ready to upload to \(student.name)"
    }

    /// Cancels the current upload process
    func cancelUpload() {
        resetUploadState()
        currentStage = ""
        overallProgress = 0.0

        // Cancel any ongoing operations
        cancellables.removeAll()
    }

    /// Retries the upload process
    func retryUpload() {
        guard let image = uploadState.selectedImage else { return }
        processImage(image)
    }

    // MARK: - Private Upload Flow Methods

    private func performUploadFlow(image: UIImage) async {
        do {
            // Stage 1: Image preprocessing (10% of progress)
            await updateProgress(to: 0.1, stage: "Processing image...")

            // Small delay to show the processing stage
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Stage 2: QR Code detection (30% of progress)
            await updateProgress(to: 0.3, stage: "Scanning for QR code...")

            let qrCode = try await detectQRCode(in: image)

            // Stage 3: Student lookup (50% of progress)
            await updateProgress(to: 0.5, stage: "Looking up student...")

            if let qrCode = qrCode {
                // Try to find student by QR code
                if let student = studentRepository.findStudent(by: qrCode) {
                    // QR detected and matched
                    uploadState.detectedStudent = student
                    uploadState.stage = .confirm
                    await updateProgress(to: 1.0, stage: "Student found: \(student.name)")
                } else {
                    // QR detected but no matching student
                    uploadState.stage = .manualSelect
                    await updateProgress(to: 1.0, stage: "QR code detected but no matching student found")
                }
            } else {
                // No QR detected - manual selection required
                uploadState.stage = .manualSelect
                await updateProgress(to: 1.0, stage: "No QR code detected - manual selection required")
            }

        } catch {
            await handleUploadError(error)
        }
    }

    private func detectQRCode(in image: UIImage) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            qrDetectionService.detectQRCode(in: image) { qrCode in
                continuation.resume(returning: qrCode)
            }
        }
    }

    private func uploadImageToStudent(image: UIImage, student: Student) async {
        do {
            currentStage = "Uploading assessment..."
            overallProgress = 0.0

            // Monitor upload progress from the service
            let progressSubscription = imageUploadService.$uploadProgress
                .receive(on: DispatchQueue.main)
                .sink { [weak self] progress in
                    self?.overallProgress = progress
                }

            // Perform the upload
            let downloadURL = try await imageUploadService.uploadImageAndLinkToStudent(
                image: image,
                student: student
            )

            // Success!
            currentStage = "Upload completed successfully!"
            overallProgress = 1.0

            // Clean up
            progressSubscription.cancel()

            // Auto-dismiss after a short delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            resetUploadState()

            print("✅ Successfully uploaded assessment for \(student.name): \(downloadURL)")

        } catch {
            await handleUploadError(error)
        }
    }

    // MARK: - State Management

    private func updateProgress(to progress: Double, stage: String) async {
        uploadState.progress = progress
        overallProgress = progress
        currentStage = stage
    }

    private func resetUploadState() {
        uploadState = UploadState()
        errorMessage = nil
        showingError = false
    }

    private func handleUploadError(_ error: Error) async {
        print("❌ Upload error: \(error)")

        let message: String
        if let uploadError = error as? ImageUploadError {
            message = uploadError.localizedDescription
        } else if let repoError = error as? StudentRepositoryError {
            message = repoError.localizedDescription
        } else {
            message = "An unexpected error occurred: \(error.localizedDescription)"
        }

        errorMessage = message
        showingError = true
        currentStage = "Upload failed"

        // Reset upload state but keep error visible
        uploadState.isActive = false
        uploadState.stage = .idle
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        print("⚠️ UploadViewModel Error: \(message)")
    }

    // MARK: - Subscriptions Setup

    private func setupSubscriptions() {
        // Monitor selected photo changes
        $selectedPhoto
            .compactMap { $0 }
            .sink { [weak self] photoItem in
                Task { @MainActor in
                    await self?.loadAndProcessImage(from: photoItem)
                }
            }
            .store(in: &cancellables)

        // Monitor image upload service errors
        imageUploadService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                Task { @MainActor in
                    await self?.handleUploadError(error)
                }
            }
            .store(in: &cancellables)

        // Monitor student repository errors
        studentRepository.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                Task { @MainActor in
                    self?.showError("Student data error: \(error.localizedDescription)")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - PhotosPicker Integration

    private func loadAndProcessImage(from photoItem: PhotosPickerItem) async {
        do {
            currentStage = "Loading selected photo..."

            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                processImage(image)
            } else {
                showError("Failed to load selected photo")
            }

        } catch {
            showError("Error loading photo: \(error.localizedDescription)")
        }
    }

    // MARK: - Utility Methods

    /// Gets filtered students for manual selection
    func getFilteredStudents() -> [Student] {
        let query = uploadState.searchQuery.lowercased()

        if query.isEmpty {
            return studentRepository.students
        } else {
            return studentRepository.students.filter { student in
                student.name.lowercased().contains(query) ||
                student.studentID.lowercased().contains(query) ||
                student.classroom.lowercased().contains(query)
            }
        }
    }

    /// Checks if the upload process can be started
    var canStartUpload: Bool {
        return !imageUploadService.isUploading &&
               !studentRepository.isLoading &&
               uploadState.stage == .idle
    }

    /// Gets current upload status message
    var statusMessage: String {
        if imageUploadService.isUploading {
            return "Uploading..."
        } else if studentRepository.isLoading {
            return "Loading students..."
        } else if uploadState.isActive {
            return currentStage
        } else {
            return "Ready to upload"
        }
    }

    /// Gets the number of available students
    var availableStudentsCount: Int {
        return studentRepository.students.count
    }

    // MARK: - Debug and Development

    /// Loads sample students for development/testing
    func loadSampleStudents() {
        guard let teacherId = Auth.auth().currentUser?.uid else {
            showError("No authenticated teacher found")
            return
        }

        Task {
            do {
                try await studentRepository.seedMockData(for: teacherId)
                currentStage = "Sample students loaded"
            } catch {
                showError("Failed to load sample students: \(error.localizedDescription)")
            }
        }
    }

    /// Simulates QR code detection for testing
    func simulateQRDetection(for studentID: String) {
        if let student = studentRepository.students.first(where: { $0.studentID == studentID }) {
            uploadState.detectedStudent = student
            uploadState.stage = .confirm
            currentStage = "Simulated QR detection for \(student.name)"
        } else {
            showError("No student found with ID: \(studentID)")
        }
    }
}

// MARK: - Extensions for Convenience

extension UploadAssessmentViewModel {

    /// Convenience method to check if we're in a specific upload stage
    func isInStage(_ stage: UploadStage) -> Bool {
        return uploadState.stage == stage
    }

    /// Convenience method to get progress as a percentage string
    var progressPercentage: String {
        return "\(Int(overallProgress * 100))%"
    }

    /// Convenience method to check if manual selection is needed
    var needsManualSelection: Bool {
        return uploadState.stage == .manualSelect
    }

    /// Convenience method to check if confirmation is needed
    var needsConfirmation: Bool {
        return uploadState.stage == .confirm && uploadState.detectedStudent != nil
    }
}
