//
//  UploadProgressOverlay.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 25/7/2025.
//

//
//  UploadProgressOverlay.swift
//  MyMarkBook
//

import SwiftUI

// MARK: - Main Upload Progress Overlay
struct UploadProgressOverlay: View {
    let uploadState: UploadState
    let students: [Student]
    @Binding var searchQuery: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onManualSelect: (Student) -> Void

    var filteredStudents: [Student] {
        if searchQuery.isEmpty {
            return students
        } else {
            return students.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
        }
    }

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow dismissal by tapping background
                    onCancel()
                }

            // Main content based on upload stage
            VStack(spacing: 20) {
                switch uploadState.stage {
                case .idle:
                    EmptyView()

                case .uploading:
                    UploadProgressCard(
                        title: "Processing Image",
                        message: "Preparing your assessment for upload...",
                        progress: uploadState.progress,
                        onCancel: onCancel
                    )

                case .scanning:
                    QRScanningCard(
                        title: "Scanning QR Code",
                        message: "Looking for QR code in the image...",
                        progress: uploadState.progress,
                        onCancel: onCancel
                    )

                case .confirm:
                    if let student = uploadState.detectedStudent {
                        StudentConfirmationCard(
                            student: student,
                            onConfirm: onConfirm,
                            onCancel: onCancel
                        )
                    }

                case .manualSelect:
                    ManualStudentSelectionCard(
                        students: filteredStudents,
                        searchQuery: $searchQuery,
                        onSelect: onManualSelect,
                        onCancel: onCancel
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: uploadState.stage)
    }
}

// MARK: - Upload Progress Card
struct UploadProgressCard: View {
    let title: String
    let message: String
    let progress: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
            }

            // Title and message
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(CustomProgressViewStyle())
                    .frame(width: 200)

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Cancel button
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.red)
            .font(.subheadline)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .frame(width: 300)
    }
}

// MARK: - QR Scanning Card
struct QRScanningCard: View {
    let title: String
    let message: String
    let progress: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Animated QR scanning icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.1)
                    .animation(.easeInOut(duration: 1).repeatForever(), value: progress)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Scanning animation
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 8, height: 20)
                            .scaleEffect(y: 0.5 + 0.5 * sin(Date().timeIntervalSince1970 * 3 + Double(index) * 0.5))
                            .animation(.easeInOut(duration: 0.6).repeatForever(), value: progress)
                    }
                }

                Text("Analyzing image...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.red)
            .font(.subheadline)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .frame(width: 300)
    }
}

// MARK: - Student Confirmation Card
struct StudentConfirmationCard: View {
    let student: Student
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 70, height: 70)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: student.id)

            VStack(spacing: 12) {
                Text("QR Code Detected!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Assign assessment to:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Student info card
                VStack(spacing: 8) {
                    HStack {
                        // Student avatar
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(student.initials)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(student.name)
                                .font(.headline)
                                .fontWeight(.semibold)

                            HStack(spacing: 8) {
                                Text("ID: \(student.studentID)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(student.classroom)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
            }

            // Action buttons
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("Cancel")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }

                Button(action: onConfirm) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Confirm")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .frame(width: 350)
    }
}

// MARK: - Manual Student Selection Card
struct ManualStudentSelectionCard: View {
    let students: [Student]
    @Binding var searchQuery: String
    let onSelect: (Student) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                }

                VStack(spacing: 6) {
                    Text("Select Student")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("QR code not detected. Please select a student manually.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.subheadline)

                TextField("Search students...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 4)

            // Student list
            ScrollView {
                LazyVStack(spacing: 8) {
                    if students.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)

                            Text(searchQuery.isEmpty ? "No students available" : "No students match your search")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(students) { student in
                            StudentSelectionRow(
                                student: student,
                                onSelect: { onSelect(student) }
                            )
                        }
                    }
                }
            }
            .frame(maxHeight: 250)

            // Cancel button
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.red)
            .font(.subheadline)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .frame(width: 380, height: 500)
    }
}

// MARK: - Student Selection Row
struct StudentSelectionRow: View {
    let student: Student
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Student avatar
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(student.initials)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )

                // Student info
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(student.studentID)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(student.classroom)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if student.totalAssessments > 0 {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(student.totalAssessments) assessments")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Custom Progress View Style
struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 8)

            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * 200, height: 8)
                .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
        }
    }
}

// MARK: - Preview
struct UploadProgressOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Progress state
            UploadProgressOverlay(
                uploadState: UploadState(stage: .uploading, progress: 0.6),
                students: Student.sampleStudents(for: "teacher123"),
                searchQuery: .constant(""),
                onConfirm: {},
                onCancel: {},
                onManualSelect: { _ in }
            )
            .previewDisplayName("Upload Progress")

            // Confirmation state
            UploadProgressOverlay(
                uploadState: UploadState(
                    stage: .confirm,
                    progress: 1.0,
                    detectedStudent: Student.sampleStudents(for: "teacher123").first
                ),
                students: Student.sampleStudents(for: "teacher123"),
                searchQuery: .constant(""),
                onConfirm: {},
                onCancel: {},
                onManualSelect: { _ in }
            )
            .previewDisplayName("Confirmation")

            // Manual selection state
            UploadProgressOverlay(
                uploadState: UploadState(stage: .manualSelect, progress: 1.0),
                students: Student.sampleStudents(for: "teacher123"),
                searchQuery: .constant(""),
                onConfirm: {},
                onCancel: {},
                onManualSelect: { _ in }
            )
            .previewDisplayName("Manual Selection")
        }
    }
}
