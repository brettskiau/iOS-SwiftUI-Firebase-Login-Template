//
//  StudentRepository.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 25/7/2025.
//
//  StudentRepository.swift
//  MyMarkBook
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Student Repository Protocol
protocol StudentRepositoryProtocol {
    func loadStudents(for teacherId: String) async throws -> [Student]
    func findStudent(by qrCode: String) -> Student?
    func addStudent(_ student: Student) async throws -> Student
    func updateStudent(_ student: Student) async throws
    func deleteStudent(_ student: Student) async throws
    func addImageURLToStudent(studentId: String, imageURL: String) async throws
    func removeImageURLFromStudent(studentId: String, imageURL: String) async throws
    func searchStudents(query: String, teacherId: String) async throws -> [Student]
}

// MARK: - Firebase Student Repository
class StudentRepository: ObservableObject, StudentRepositoryProtocol {

    // MARK: - Properties
    @Published var students: [Student] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let db = Firestore.firestore()
    private let collection = "students"

    // Cache for quick QR code lookups
    private var qrCodeCache: [String: Student] = [:]

    // MARK: - Initialization
    init() {
        // Initialize cache when repository is created
//        updateCache()
    }

    // MARK: - Public Methods

    /// Loads all students for a specific teacher
    @MainActor
    func loadStudents(for teacherId: String) async throws -> [Student] {
        isLoading = true
        error = nil

        // ADD THIS: Use defer to ensure isLoading is always set to false
        defer {
            isLoading = false
        }

        do {
            print("🔄 Loading students for teacher: \(teacherId)")

            let query = db.collection(collection)
                .whereField("teacherId", isEqualTo: teacherId)
                .whereField("isActive", isEqualTo: true)
                .order(by: "name")

            let snapshot = try await query.getDocuments()

            let loadedStudents = snapshot.documents.compactMap { document -> Student? in
                do {
                    var student = try document.data(as: Student.self)
                    student.id = document.documentID
                    return student
                } catch {
                    print("❌ Error parsing student document \(document.documentID): \(error)")
                    return nil
                }
            }
            self.students = loadedStudents
            updateCache()

            print("✅ Loaded \(loadedStudents.count) students")
            return loadedStudents

        } catch {
            print("❌ Error loading students: \(error)")
            self.error = error
            throw error
        }
        // REMOVE THIS LINE: isLoading = false (it's now in defer block)
    }

    /// Finds a student by QR code (uses cache for performance)
    func findStudent(by qrCode: String) -> Student? {
        return qrCodeCache[qrCode] ?? students.first { $0.qrCode == qrCode }
    }

    /// Adds a new student to the database
@MainActor
    func addStudent(_ student: Student) async throws -> Student {
        do {
            // Validate student data
            guard student.isValid else {
                throw StudentRepositoryError.invalidStudentData(student.validationErrors)
            }

            // Check for duplicate student ID
            if await studentExists(studentID: student.studentID, teacherId: student.teacherId) {
                throw StudentRepositoryError.duplicateStudentID
            }

            print("📝 Adding new student: \(student.name)")

            var newStudent = student
            let documentRef = try db.collection(collection).addDocument(from: newStudent)
            newStudent.id = documentRef.documentID

            // Update local cache
            await MainActor.run {
                students.append(newStudent)
                qrCodeCache[newStudent.qrCode] = newStudent
            }

            print("✅ Student added successfully with ID: \(documentRef.documentID)")
            return newStudent

        } catch {
            print("❌ Error adding student: \(error)")
            throw error
        }
    }

    /// Updates an existing student in the database
    @MainActor
    func updateStudent(_ student: Student) async throws {
        guard let studentId = student.id else {
            throw StudentRepositoryError.missingStudentID
        }

        guard student.isValid else {
            throw StudentRepositoryError.invalidStudentData(student.validationErrors)
        }

        do {
            print("📝 Updating student: \(student.name)")

            try db.collection(collection).document(studentId).setData(from: student, merge: true)

            // Update local cache
            await MainActor.run {
                if let index = students.firstIndex(where: { $0.id == studentId }) {
                    students[index] = student
                }
                qrCodeCache[student.qrCode] = student
            }

            print("✅ Student updated successfully")

        } catch {
            print("❌ Error updating student: \(error)")
            throw error
        }
    }

    /// Soft deletes a student (marks as inactive)
    func deleteStudent(_ student: Student) async throws {
        guard let studentId = student.id else {
            throw StudentRepositoryError.missingStudentID
        }

        do {
            print("🗑️ Deactivating student: \(student.name)")

            var updatedStudent = student
            updatedStudent.deactivate()

            try await updateStudent(updatedStudent)

            // Remove from local cache
            await MainActor.run {
                students.removeAll { $0.id == studentId }
                qrCodeCache.removeValue(forKey: student.qrCode)
            }

            print("✅ Student deactivated successfully")

        } catch {
            print("❌ Error deactivating student: \(error)")
            throw error
        }
    }

    /// Adds an image URL to a student's assessment collection
    func addImageURLToStudent(studentId: String, imageURL: String) async throws {
        do {
            print("📎 Adding image URL to student: \(studentId)")

            // Update in Firestore
            try await db.collection(collection).document(studentId).updateData([
                "imageURLs": FieldValue.arrayUnion([imageURL]),
                "totalAssessments": FieldValue.increment(Int64(1)),
                "lastAssessmentDate": Date()
            ])

            // Update local cache
            await MainActor.run {
                if let index = students.firstIndex(where: { $0.id == studentId }) {
                    students[index].addImageURL(imageURL)
                    qrCodeCache[students[index].qrCode] = students[index]
                }
            }

            print("✅ Image URL added successfully")

        } catch {
            print("❌ Error adding image URL: \(error)")
            throw error
        }
    }

    /// Removes an image URL from a student's assessment collection
    func removeImageURLFromStudent(studentId: String, imageURL: String) async throws {
        do {
            print("🗑️ Removing image URL from student: \(studentId)")

            // Update in Firestore
            try await db.collection(collection).document(studentId).updateData([
                "imageURLs": FieldValue.arrayRemove([imageURL]),
                "totalAssessments": FieldValue.increment(Int64(-1))
            ])

            // Update local cache
            await MainActor.run {
                if let index = students.firstIndex(where: { $0.id == studentId }) {
                    students[index].removeImageURL(imageURL)
                    qrCodeCache[students[index].qrCode] = students[index]
                }
            }

            print("✅ Image URL removed successfully")

        } catch {
            print("❌ Error removing image URL: \(error)")
            throw error
        }
    }

    /// Searches students by name, student ID, or classroom
    func searchStudents(query: String, teacherId: String) async throws -> [Student] {
        if query.isEmpty {
            return students
        }

        let lowercaseQuery = query.lowercased()

        return students.filter { student in
            student.name.lowercased().contains(lowercaseQuery) ||
            student.studentID.lowercased().contains(lowercaseQuery) ||
            student.classroom.lowercased().contains(lowercaseQuery)
        }
    }

    // MARK: - Batch Operations

    /// Adds multiple students in a batch operation
    @MainActor
    func addStudents(_ students: [Student]) async throws -> [Student] {
        let batch = db.batch()
        var addedStudents: [Student] = []

        do {
            print("📝 Adding \(students.count) students in batch")

            for var student in students {
                guard student.isValid else {
                    throw StudentRepositoryError.invalidStudentData(student.validationErrors)
                }

                let documentRef = db.collection(collection).document()
                student.id = documentRef.documentID
                try batch.setData(from: student, forDocument: documentRef)
                addedStudents.append(student)
            }

            try await batch.commit()

            // Update local cache
            await MainActor.run {
                self.students.append(contentsOf: addedStudents)
                updateCache()
            }

            print("✅ Batch add completed successfully")
            return addedStudents

        } catch {
            print("❌ Error in batch add: \(error)")
            throw error
        }
    }

    /// Gets students by classroom
    func getStudentsByClassroom(_ classroom: String, teacherId: String) async throws -> [Student] {
        do {
            let query = db.collection(collection)
                .whereField("teacherId", isEqualTo: teacherId)
                .whereField("classroom", isEqualTo: classroom)
                .whereField("isActive", isEqualTo: true)
                .order(by: "name")

            let snapshot = try await query.getDocuments()

            return try snapshot.documents.compactMap { document in
                var student = try document.data(as: Student.self)
                student.id = document.documentID
                return student
            }

        } catch {
            print("❌ Error getting students by classroom: \(error)")
            throw error
        }
    }

    /// Gets statistics for a teacher's students
    func getStudentStatistics(for teacherId: String) async throws -> StudentStatistics {
        let allStudents = try await loadStudents(for: teacherId)

        let totalStudents = allStudents.count
        let studentsWithAssessments = allStudents.filter { $0.totalAssessments > 0 }.count
        let totalAssessments = allStudents.reduce(0) { $0 + $1.totalAssessments }
        let recentActivityCount = allStudents.filter { $0.hasRecentActivity }.count

        let classrooms = Set(allStudents.map { $0.classroom }).sorted()
        let grades = Set(allStudents.map { $0.grade }).sorted()

        return StudentStatistics(
            totalStudents: totalStudents,
            studentsWithAssessments: studentsWithAssessments,
            totalAssessments: totalAssessments,
            recentActivityCount: recentActivityCount,
            classrooms: classrooms,
            grades: grades
        )
    }

    // MARK: - Mock Data for Development

    /// Seeds the database with mock students for development/testing
    func seedMockData(for teacherId: String) async throws {
        let mockStudents = Student.sampleStudents(for: teacherId)
        _ = try await addStudents(mockStudents)
        print("✅ Mock data seeded successfully")
    }

    // MARK: - Private Methods
    @MainActor
    private func updateCache() {
        qrCodeCache = Dictionary(uniqueKeysWithValues: students.map { ($0.qrCode, $0) })
    }

    private func studentExists(studentID: String, teacherId: String) async -> Bool {
        do {
            let query = db.collection(collection)
                .whereField("studentID", isEqualTo: studentID)
                .whereField("teacherId", isEqualTo: teacherId)
                .limit(to: 1)

            let snapshot = try await query.getDocuments()
            return !snapshot.documents.isEmpty
        } catch {
            print("❌ Error checking student existence: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Types

/// Statistics about a teacher's students
struct StudentStatistics {
    let totalStudents: Int
    let studentsWithAssessments: Int
    let totalAssessments: Int
    let recentActivityCount: Int
    let classrooms: [String]
    let grades: [String]

    var assessmentRate: Double {
        guard totalStudents > 0 else { return 0.0 }
        return Double(studentsWithAssessments) / Double(totalStudents)
    }

    var averageAssessmentsPerStudent: Double {
        guard totalStudents > 0 else { return 0.0 }
        return Double(totalAssessments) / Double(totalStudents)
    }
}

/// Custom errors for student repository operations
enum StudentRepositoryError: LocalizedError {
    case invalidStudentData([String])
    case duplicateStudentID
    case missingStudentID
    case studentNotFound
    case networkError(Error)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidStudentData(let errors):
            return "Invalid student data: \(errors.joined(separator: ", "))"
        case .duplicateStudentID:
            return "A student with this ID already exists"
        case .missingStudentID:
            return "Student ID is missing"
        case .studentNotFound:
            return "Student not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}
