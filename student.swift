//
//  student.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 25/7/2025.
//

import Foundation
import FirebaseFirestore

// MARK: - Student Model
struct Student: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let studentID: String
    let qrCode: String
    let classroom: String
    let teacher: String
    let grade: String
    let createdAt: Date
    var imageURLs: [String]

    // Authentication and organization fields
    let teacherId: String        // Links student to authenticated teacher
    let schoolId: String?        // Optional: for multi-school scenarios
    let academicYear: String     // e.g., "2024-2025"

    // Additional student information
    let email: String?           // Student email (optional)
    let parentEmail: String?     // Parent/guardian email (optional)
    let dateOfBirth: Date?       // Student's birth date (optional)
    let enrollmentDate: Date     // When student was enrolled

    // Assessment tracking
    var totalAssessments: Int    // Total number of assessments uploaded
    var lastAssessmentDate: Date? // Date of most recent assessment

    // Status and flags
    var isActive: Bool           // Whether student is currently active
    var notes: String?           // Teacher notes about student

    // MARK: - Initializers

    /// Primary initializer for creating new students
    init(
        name: String,
        studentID: String,
        qrCode: String,
        classroom: String,
        teacher: String,
        grade: String,
        teacherId: String,
        schoolId: String? = nil,
        academicYear: String = "2024-2025",
        email: String? = nil,
        parentEmail: String? = nil,
        dateOfBirth: Date? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.studentID = studentID
        self.qrCode = qrCode
        self.classroom = classroom
        self.teacher = teacher
        self.grade = grade
        self.teacherId = teacherId
        self.schoolId = schoolId
        self.academicYear = academicYear
        self.email = email
        self.parentEmail = parentEmail
        self.dateOfBirth = dateOfBirth
        self.notes = notes

        // Auto-generated fields
        self.createdAt = Date()
        self.enrollmentDate = Date()
        self.imageURLs = []
        self.totalAssessments = 0
        self.lastAssessmentDate = nil
        self.isActive = true
    }

    /// Convenience initializer for quick student creation
    init(
        name: String,
        studentID: String,
        classroom: String,
        teacher: String,
        grade: String,
        teacherId: String
    ) {
        self.init(
            name: name,
            studentID: studentID,
            qrCode: Student.generateQRCode(for: studentID),
            classroom: classroom,
            teacher: teacher,
            grade: grade,
            teacherId: teacherId
        )
    }
}

// MARK: - Student Extensions
extension Student {

    /// Generates a unique QR code string for a student ID
    static func generateQRCode(for studentID: String) -> String {
        return "STUDENT_\(studentID)_\(Date().timeIntervalSince1970)"
    }

    /// Returns the student's display name (formatted)
    var displayName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the student's initials for avatars
    var initials: String {
        let components = name.components(separatedBy: .whitespaces)
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }

    /// Returns formatted grade for display
    var formattedGrade: String {
        if grade.lowercased().contains("year") {
            return grade
        } else {
            return "Year \(grade)"
        }
    }

    /// Returns age if date of birth is available
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year
    }

    /// Returns time since last assessment
    var daysSinceLastAssessment: Int? {
        guard let lastDate = lastAssessmentDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: lastDate, to: Date()).day
        return days
    }

    /// Returns whether student has recent activity (within 30 days)
    var hasRecentActivity: Bool {
        guard let days = daysSinceLastAssessment else { return false }
        return days <= 30
    }
}

// MARK: - Assessment Management
extension Student {

    /// Adds an image URL to the student's assessment collection
    mutating func addImageURL(_ url: String) {
        imageURLs.append(url)
        totalAssessments += 1
        lastAssessmentDate = Date()
    }

    /// Removes an image URL from the student's collection
    mutating func removeImageURL(_ url: String) {
        imageURLs.removeAll { $0 == url }
        totalAssessments = max(0, totalAssessments - 1)

        // Update last assessment date if this was the most recent
        if imageURLs.isEmpty {
            lastAssessmentDate = nil
        }
    }

    /// Updates student notes
    mutating func updateNotes(_ newNotes: String?) {
        notes = newNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Deactivates the student
    mutating func deactivate() {
        isActive = false
    }

    /// Reactivates the student
    mutating func reactivate() {
        isActive = true
    }
}

// MARK: - Validation
extension Student {

    /// Validates that all required fields are properly filled
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !studentID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !qrCode.isEmpty &&
               !teacherId.isEmpty &&
               !classroom.isEmpty &&
               !teacher.isEmpty &&
               !grade.isEmpty
    }

    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name is required")
        }

        if studentID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Student ID is required")
        }

        if qrCode.isEmpty {
            errors.append("QR Code is required")
        }

        if teacherId.isEmpty {
            errors.append("Teacher ID is required")
        }

        if classroom.isEmpty {
            errors.append("Classroom is required")
        }

        if teacher.isEmpty {
            errors.append("Teacher name is required")
        }

        if grade.isEmpty {
            errors.append("Grade is required")
        }

        return errors
    }
}

// MARK: - Sample Data for Testing
extension Student {

    /// Creates sample students for testing/preview purposes
    static func sampleStudents(for teacherId: String) -> [Student] {
        return [
            Student(
                name: "Emma Thompson",
                studentID: "ST001",
                classroom: "3A",
                teacher: "Ms. Johnson",
                grade: "3",
                teacherId: teacherId
            ),
            Student(
                name: "Liam Chen",
                studentID: "ST002",
                classroom: "3A",
                teacher: "Ms. Johnson",
                grade: "3",
                teacherId: teacherId
            ),
            Student(
                name: "Sophia Rodriguez",
                studentID: "ST003",
                classroom: "3B",
                teacher: "Mr. Davis",
                grade: "3",
                teacherId: teacherId
            ),
            Student(
                name: "Noah Williams",
                studentID: "ST004",
                classroom: "4A",
                teacher: "Mrs. Smith",
                grade: "4",
                teacherId: teacherId
            ),
            Student(
                name: "Ava Johnson",
                studentID: "ST005",
                classroom: "4A",
                teacher: "Mrs. Smith",
                grade: "4",
                teacherId: teacherId
            )
        ]
    }
}

// MARK: - Hashable Conformance
extension Student: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(studentID)
        hasher.combine(qrCode)
    }
}

// MARK: - Equatable Conformance
extension Student: Equatable {
    static func == (lhs: Student, rhs: Student) -> Bool {
        return lhs.id == rhs.id &&
               lhs.studentID == rhs.studentID &&
               lhs.qrCode == rhs.qrCode
    }
}
