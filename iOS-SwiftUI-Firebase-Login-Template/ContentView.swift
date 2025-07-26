//
//  ContentView.swift
//  MyMarkBook
//

import SwiftUI
import FirebaseAuth
import PhotosUI  // ADD THIS IMPORT
import Vision    // ADD THIS IMPORT

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var sidebarWidth: CGFloat = 0.4 // Start at 40%
    @State private var showMainContent: Bool = false
    @State private var selectedView: String = "Summary" // Add navigation state

    // This will check if we have a persisted login
    private var isPersistedLogin: Bool {
        UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    private var isAuthenticated: Bool {
        authViewModel.state == .signedIn || (isPersistedLogin && authViewModel.currentUser != nil)
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if isAuthenticated {
                    // Authenticated Layout with Animation
                    HStack(spacing: 0) {
                        // Left Sidebar - animated width with your custom design
                        Group {
                            if showMainContent {
                                AuthenticatedSidebarView(selectedView: $selectedView)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: geometry.size.width * sidebarWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color(hex: "FFF6E2"))

                        // Right Content - animated width with your custom design
                        Group {
                            if showMainContent {
                                AuthenticatedMainContentView(selectedView: selectedView)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: geometry.size.width * (1 - sidebarWidth))
                        .frame(maxHeight: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                    .onAppear {
                        // Trigger animation when authenticated
                        withAnimation(.easeInOut(duration: 0.8)) {
                            sidebarWidth = 0.3 // Shrink to 30%
                        }

                        // Show main content after sidebar animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showMainContent = true
                            }
                        }
                    }
                } else {
                    // Login Layout
                    NavigationStack {
                        Login()
                    }
                    .onAppear {
                        // Reset animation state when showing login
                        sidebarWidth = 0.4
                        showMainContent = false
                        selectedView = "Summary"
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isAuthenticated)
        }
        .background(Color(hex: "FFF6E2"))
        .overlay {
            // Show loading indicator when ViewModel is loading
            if authViewModel.isLoading {
                LoadingView()
            }
        }
        .alert(item: errorBinding) { authError in
            Alert(
                title: Text("Error"),
                message: Text(authError.errorDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // Map AuthError to an Identifiable error for alerts
    private var errorBinding: Binding<IdentifiableError?> {
        Binding<IdentifiableError?>(
            get: {
                guard let error = authViewModel.error else { return nil }
                return IdentifiableError(error: error)
            },
            set: { _ in authViewModel.error = nil }
        )
    }
}

// MARK: - Authenticated Main Content View
struct AuthenticatedMainContentView: View {
    let selectedView: String

    // Create a shared view model at this level
    @StateObject private var uploadViewModel = UploadAssessmentViewModel(
        studentRepository: StudentRepository(),
        imageUploadService: ImageUploadService(),
        qrDetectionService: QRCodeDetectionService()
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // FIXED TOP SECTION - Same for all views
            VStack(alignment: .leading, spacing: 32) {
                // Fixed top spacer - ensures consistent starting position
                Spacer()
                    .frame(height: 60)

                // Title - same position for all views
                Text(selectedView)
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)

            // CONTENT SECTION - Scrollable and flexible
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Content based on selection
                    switch selectedView {
                    case "Summary":
                        AuthenticatedSummaryContentView(uploadViewModel: uploadViewModel)
                    case "Students":
                        PlaceholderContentView(viewName: "Students")
                    case "Classes":
                        PlaceholderContentView(viewName: "Classes")
                    default:
                        PlaceholderContentView(viewName: selectedView)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32) // Bottom padding for scroll
            }

            // BOTTOM SPACER - Ensures consistent bottom spacing
            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill entire area
        .background(Color(hex: "FFF6E2"))
        // Move the overlay here - covers the entire main content area
        .overlay {
            if uploadViewModel.uploadState.isActive {
                UploadProgressOverlay(
                    uploadState: uploadViewModel.uploadState,
                    students: uploadViewModel.studentRepository.students,
                    searchQuery: $uploadViewModel.uploadState.searchQuery,
                    onConfirm: uploadViewModel.confirmAssignment,
                    onCancel: uploadViewModel.cancelUpload,
                    onManualSelect: uploadViewModel.selectStudent
                )
            }
        }
    }
}

// MARK: - Authenticated Summary Content View
struct AuthenticatedSummaryContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    // Accept the upload view model from parent
    @ObservedObject var uploadViewModel: UploadAssessmentViewModel

    // Mock data - this will be replaced with real data later
    private let favouriteClasses = [
        FavouriteClass(name: "Year 3A", studentsEnrolled: 24),
        FavouriteClass(name: "Year 4C - Maths", studentsEnrolled: 24)
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Quick Stats with authenticated user data
            HStack(spacing: 24) {
                StatCard(title: "Recent Activity", value: "5 new assessments", color: .blue)
                StatCard(title: "Total Students", value: "48", color: .blue)
                // Pass the view model to the upload card
                UploadAssessmentCard(viewModel: uploadViewModel)
            }

            // Main Summary Card
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "DBD0B7"))
                .frame(maxWidth: 900, minHeight: 300)
                .overlay(
                    VStack(spacing: 24) {
                        // Illustration placeholder
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)

                        Text("Your teaching dashboard")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Welcome to MyMarkBook, \(userName)!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                )
                .shadow(color: .black.opacity(0.05), radius: 8)

            // Favourites Section
            FavouritesSection(classes: favouriteClasses)
        }
    }

    // Computed properties for authenticated user data
    private var userName: String {
        if let displayName = authViewModel.currentUser?.displayName, !displayName.isEmpty {
            return displayName
        } else {
            return "Teacher"
        }
    }

    private var userSchool: String {
        // TODO: Get this from TeacherProfile when we implement profile loading
        return "Your School"
    }
}

// MARK: - Reusable Components

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
}

struct UploadAssessmentCard: View {
    // Accept the view model from parent instead of creating it
    @ObservedObject var viewModel: UploadAssessmentViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        Menu {
            Button(action: {
                viewModel.selectImageSource(.photoLibrary)
            }) {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }

            Button(action: {
                viewModel.selectImageSource(.camera)
            }) {
                Label("Take Photo", systemImage: "camera")
            }

            Button(action: {
                viewModel.selectImageSource(.file)
            }) {
                Label("Upload File", systemImage: "doc")
            }

            Divider()

            Button(action: {
                // Future: Add note functionality
            }) {
                Label("Add Note", systemImage: "note.text")
            }

            // Development helpers
            #if DEBUG
            Divider()

            Button(action: {
                viewModel.loadSampleStudents()
            }) {
                Label("Load Sample Data", systemImage: "person.3.fill")
            }
            #endif

        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)

                Text("Upload an assessment")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Show status when uploading
                if viewModel.imageUploadService.isUploading {
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4)
            )
            .opacity(viewModel.canStartUpload ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!viewModel.canStartUpload)
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(sourceType: viewModel.sourceType) { image in
                viewModel.processImage(image)
            }
        }
        .alert("Upload Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.showingError = false
            }

            if let error = viewModel.errorMessage, error.contains("validation") {
                Button("Retry") {
                    viewModel.retryUpload()
                }
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Load students when the card appears
            if let teacherId = authViewModel.currentUser?.uid {
                Task {
                    try await viewModel.studentRepository.loadStudents(for: teacherId)
                }
            }
        }
    }
}

struct FavouritesSection: View {
    let classes: [FavouriteClass]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favourites")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 8)

            // 2-column grid in scroll view
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(classes) { classItem in
                        FavouriteClassCard(classItem: classItem)
                    }
                }
                .padding(.horizontal, 6)
            }
            .frame(maxHeight: 300)
        }
        .padding(.top, 24)
    }
}

struct FavouriteClassCard: View {
    let classItem: FavouriteClass

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(classItem.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }

            Text("\(classItem.studentsEnrolled) students enrolled")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.7))

            Rectangle()
                .fill(Color.black.opacity(0.4))
                .frame(height: 4)
                .cornerRadius(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.9))
        )
        .frame(minHeight: 100)
    }
}

struct PlaceholderContentView: View {
    let viewName: String

    var body: some View {
        VStack(spacing: 32) {
            // Ensure consistent height for all placeholder views
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .frame(maxWidth: .infinity, maxHeight: 400) // FIXED HEIGHT
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("\(viewName) View")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("This section will be implemented soon!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                )
                .shadow(color: .black.opacity(0.05), radius: 8)

            // Add some additional content to make it feel complete
            HStack(spacing: 24) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)
                        .overlay(
                            VStack {
                                Image(systemName: "doc.text")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Feature \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
        }
    }
}

// MARK: - Data Models
struct FavouriteClass: Identifiable {
    let id = UUID()
    let name: String
    let studentsEnrolled: Int
}

// Helper for making errors identifiable for alerts
struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: AuthError

    var errorDescription: String? {
        error.localizedDescription
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationViewModel(
                authRepository: FirebaseAuthRepository()
            ))
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad Pro")
    }
}
