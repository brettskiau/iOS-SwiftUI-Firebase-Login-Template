//
//  Login.swift
//
//

import SwiftUI
import AuthenticationServices
import FirebaseCore
import Firebase
import FirebaseFirestore

struct TeacherProfile: Identifiable, Codable {
    var id: String?
    let email: String
    let fullName: String
    let firstName: String
    let lastName: String
    let schoolName: String
    let department: String?  // areaOfTeaching
    let gradeLevel: String   // joined gradeLevels array
    let gradeLevels: [String] // keep the array too
    let title: String        // Mr, Mrs, etc.
    let createdAt: Date
    let isActive: Bool

    init(email: String, firstName: String, lastName: String, schoolName: String, department: String? = nil, gradeLevel: String, gradeLevels: [String], title: String = "Mr") {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = "\(firstName) \(lastName)"
        self.schoolName = schoolName
        self.department = department
        self.gradeLevel = gradeLevel
        self.gradeLevels = gradeLevels
        self.title = title
        self.createdAt = Date()
        self.isActive = true
    }
}


struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.02, blue: 0.08), // almost black
                Color(red: 0.08, green: 0.00, blue: 0.20), // dark purple hint
                Color(red: 0.12, green: 0.00, blue: 0.25)  // subtle top-right lift
            ]),
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
        .ignoresSafeArea()
    }
}

struct Login: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showResetPasswordAlert: Bool = false
    @State private var resetPasswordEmail: String = ""
    @State private var showPasswordResetConfirmation: Bool = false
    @FocusState private var emailIsFocused: Bool
    @FocusState private var passwordIsFocused: Bool
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showSignUpForm: Bool = false
    @State private var isSigningUp: Bool = false
    @State private var teacherProfile = TeacherSignUpData(
        firstName: "",
        lastName: "",
        schoolName: "",
        areaOfTeaching: "",
        gradeLevels: [],
        email: "",
        password: "",
        confirmPassword: ""
    )


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Layout
                HStack(spacing: 0) {
                    // Left Sidebar (dimmed when signup form is shown)
                    VStack(spacing: 0) {
                        Spacer()

                        // Logo and Title (smaller for sidebar)
                        VStack(spacing: 5) {
                            Image("MarkBookIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)

                            Text("Sign In")
                                .foregroundColor(.Orange)
                                .font(.system(size: 24))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 30)

                        // Form Fields
                        VStack(spacing: 0) {
                            TextField("Email Address", text: $email)
                                .withLoginStyles()
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .submitLabel(.next)
                                .focused($emailIsFocused)
                                .onSubmit {
                                    emailIsFocused = false
                                    passwordIsFocused = true
                                }

                            SecureField("Password", text: $password)
                                .withSecureFieldStyles()
                                .submitLabel(.go)
                                .focused($passwordIsFocused)
                                .onSubmit {
                                    signIn()
                                }

                            // Forgot Password Link
                            HStack {
                                Spacer()
                                Button {
                                    showResetPasswordAlert = true
                                } label: {
                                    Text("Forgot Password?")
                                        .foregroundColor(.Orange)
                                        .font(.footnote)
                                }
                            }
                            .padding(.bottom, 20)

                            // Error Display
                            if let error = authViewModel.error {
                                Text(error.localizedDescription)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .padding(.bottom, 12)
                                    .transition(.opacity)
                            }

                            // Sign In Button
                            Button(action: signIn) {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.Orange)
                                        .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: 180)
                            .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                            .padding(.bottom, 15)

                            // Updated Sign Up Button
                            Button(action: {
                                print("🔘 Sign Up button tapped!")
                                showSignUpForm = true
                            }) {
                                Text("Sign Up")
                                    .frame(maxWidth: 250)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.Orange)
                                    .cornerRadius(10)
                            }
                            .frame(maxWidth: 180)
                        }
                        .padding(.horizontal, 20)

                        // OR Divider (smaller)
                        HStack {
                            VStack { Divider() }
                            Text("OR")
                                .font(.footnote)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                            VStack { Divider() }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)

                        // Social Login Options (compact)
                        VStack(spacing: 10) {
                            SocialLogins()
                        }
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                    .frame(width: geometry.size.width * 0.4)
                    .background(GradientBackground())
//                    .background(Color.gray.opacity(0.05))
                    .opacity(showSignUpForm ? 0.3 : 1.0) // Dim sidebar when signup form is shown
                    .disabled(showSignUpForm) // Disable sidebar interaction
                    .animation(.easeInOut(duration: 0.3), value: showSignUpForm)

                    // Right Side - Welcome Content OR Signup Form
                    Group {
                        if showSignUpForm {
                            SignUpFormView(
                                teacherProfile: $teacherProfile,
                                isSigningUp: $isSigningUp,
                                onSubmit: {
                                    performSignUp(teacherProfile: teacherProfile)
                                },
                                onCancel: {
                                    showSignUpForm = false
                                }
                            )
                        } else {
                            WelcomeContentView()
                        }
                    }
                    .frame(width: geometry.size.width * 0.6)
                    .animation(.easeInOut(duration: 0.3), value: showSignUpForm)
                }
            }
            // Keep all your existing alert modifiers here...
        }
    }

    // Helper methods
    private func signIn() {
        Task {
            await authViewModel.login(with: .emailAndPassword(
                email: email,
                password: password
            ))
        }
    }

    private func performSignUp(teacherProfile: TeacherSignUpData) {
        print("🚀 Starting signup process...")
            print("📧 Email: \(teacherProfile.email)")
            print("👤 Name: \(teacherProfile.firstName) \(teacherProfile.lastName)")

        isSigningUp = true

        Task {
            do {
                print("🔐 Creating Firebase Auth account...")
                // Step 1: Create Firebase Auth account
                try await authViewModel.signUp(
                    email: teacherProfile.email,
                    password: teacherProfile.password
                )
                print("✅ Firebase Auth account created successfully!")
                            print("🆔 User ID: \(authViewModel.currentUser?.uid ?? "NO UID")")

                // Step 2: Save teacher profile to Firestore
                let profile = TeacherProfile(
                    email: teacherProfile.email,
                    firstName: teacherProfile.firstName,        // Fixed: use firstName
                    lastName: teacherProfile.lastName,          // Fixed: use lastName
                    schoolName: teacherProfile.schoolName,
                    department: teacherProfile.areaOfTeaching,
                    gradeLevel: teacherProfile.gradeLevels.joined(separator: ", "),
                    gradeLevels: teacherProfile.gradeLevels,    // Fixed: add gradeLevels array
//                    title: selectedTitle                        // You'll need to pass this
                )

                print("💾 Attempting to save teacher profile to Firestore...")
                            // Save to the "teachers" collection
                            try await saveTeacherProfile(profile)

                            print("✅ Teacher account created and profile saved!")
                            showSignUpForm = false

            } catch {
                print("❌ Signup error: \(error)")
            }

            isSigningUp = false
        }
    }


    // Add this function to save the profile
    private func saveTeacherProfile(_ profile: TeacherProfile) async throws {
        print("💾 saveTeacherProfile called...")

        guard let userId = authViewModel.currentUser?.uid else {
            print("❌ No authenticated user found!")
            throw NSError(domain: "NoUser", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }

        print("🆔 Saving profile for user ID: \(userId)")

        let db = Firestore.firestore()
        var profileWithId = profile
        profileWithId.id = userId

        print("🗄️ Firestore reference created, attempting to save...")

        // Save to "teachers" collection with document ID = user's Firebase Auth UID
        try db.collection("teachers").document(userId).setData(from: profileWithId)

        print("✅ Teacher profile saved to Firestore: teachers/\(userId)")
    }

}

// Helper View for Feature Items
struct FeatureItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.Orange)
                .frame(width: 25)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Teacher Sign Up Form
//struct TeacherSignUpFormView: View {
//    @Binding var isSigningUp: Bool
//    let onCancel: () -> Void
//    let onSignUp: (TeacherSignUpData) -> Void
//
//    @State private var email: String = ""
//    @State private var password: String = ""
//    @State private var confirmPassword: String = ""
//    @State private var firstName: String = ""
//    @State private var lastName: String = ""
//    @State private var schoolName: String = ""
//    @State private var gradeLevel: String = ""
//    @State private var department: String = ""
//
//    let gradeLevels = ["Foundation", "Year 1", "Year 2", "Year 3", "Year 4", "Year 5", "Year 6", "Year 7", "Year 8", "Year 9", "Year 10", "Year 11", "Year 12", "Other"]
//
//    var isFormValid: Bool {
//        !firstName.isEmpty &&
//        !lastName.isEmpty &&
//        !email.isEmpty &&
//        !password.isEmpty &&
//        !confirmPassword.isEmpty &&
//        !schoolName.isEmpty &&
//        !gradeLevel.isEmpty &&
//        password == confirmPassword &&
//        password.count >= 6 &&
//        email.contains("@")
//    }
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 30) {
//                // Header
//                VStack(spacing: 16) {
//                    Image(systemName: "person.badge.plus")
//                        .font(.system(size: 60))
//                        .foregroundColor(.Orange)
//
//                    Text("Create Teacher Account")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//
//                    Text("Join MyMarkBook and start managing your assessments")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//
//                // Form
//                VStack(spacing: 20) {
//                    // Account Information
//                    VStack(alignment: .leading, spacing: 15) {
//                        Text("Account Information")
//                            .font(.title3)
//                            .fontWeight(.semibold)
//
//                        TextField("Email Address", text: $email)
//                            .withLoginStyles()
//                            .keyboardType(.emailAddress)
//                            .autocapitalization(.none)
//
//                        SecureField("Password (min 6 characters)", text: $password)
//                            .withSecureFieldStyles()
//
//                        SecureField("Confirm Password", text: $confirmPassword)
//                            .withSecureFieldStyles()
//
//                        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
//                            Text("Passwords do not match")
//                                .font(.caption)
//                                .foregroundColor(.red)
//                        }
//                    }
//
//                    // Teacher Information
//                    VStack(alignment: .leading, spacing: 15) {
//                        Text("Teacher Information")
//                            .font(.title3)
//                            .fontWeight(.semibold)
//
//                        HStack(spacing: 16) {
//                            TextField("First Name", text: $firstName)
//                                .withLoginStyles()
//                                .toolbar {
//                                        ToolbarItemGroup(placement: .keyboard) {
//                                            Button("Previous") { /* focus previous field */ }
//                                            Button("Next") { /* focus next field */ }
//                                            Spacer()
//                                            Button("Done") { /* dismiss keyboard */ }
//                                        }
//                                    }
//
//                            TextField("Last Name", text: $lastName)
//                                .withLoginStyles()
//                                .toolbar {
//                                        ToolbarItemGroup(placement: .keyboard) {
//                                            Button("Previous") { /* focus previous field */ }
//                                            Button("Next") { /* focus next field */ }
//                                            Spacer()
//                                            Button("Done") { /* dismiss keyboard */ }
//                                        }
//                                    }
//                        }
//
//
//                        TextField("School Name", text: $schoolName)
//                            .withLoginStyles()
//                            .toolbar {
//                                    ToolbarItemGroup(placement: .keyboard) {
//                                        Button("Previous") { /* focus previous field */ }
//                                        Button("Next") { /* focus next field */ }
//                                        Spacer()
//                                        Button("Done") { /* dismiss keyboard */ }
//                                    }
//                                }
//
//                        // Grade Level Picker
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Grade Level")
//                                .font(.headline)
//                                .toolbar {
//                                        ToolbarItemGroup(placement: .keyboard) {
//                                            Button("Previous") { /* focus previous field */ }
//                                            Button("Next") { /* focus next field */ }
//                                            Spacer()
//                                            Button("Done") { /* dismiss keyboard */ }
//                                        }
//                                    }
//
//                            Menu {
//                                ForEach(gradeLevels, id: \.self) { grade in
//                                    Button(grade) {
//                                        gradeLevel = grade
//                                    }
//                                }
//                            } label: {
//                                HStack {
//                                    Text(gradeLevel.isEmpty ? "Select grade level" : gradeLevel)
//                                        .foregroundColor(gradeLevel.isEmpty ? .secondary : .primary)
//                                    Spacer()
//                                    Image(systemName: "chevron.down")
//                                        .foregroundColor(.secondary)
//                                }
//                                .padding()
//                                .background(Color.gray.opacity(0.1))
//                                .cornerRadius(8)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                                )
//                            }
//                        }
//
//                        TextField("Department (Optional)", text: $department)
//                            .withLoginStyles()
//                            .toolbar {
//                                    ToolbarItemGroup(placement: .keyboard) {
//                                        Button("Previous") { /* focus previous field */ }
////                                        Button("Next") { /* focus next field */ }
//                                        Spacer()
//                                        Button("Done") { /* dismiss keyboard */ }
//                                    }
//                                }
//                    }
//                }
//
//                // Buttons
//                HStack(spacing: 16) {
//                    Button("Cancel") {
//                        onCancel()
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.gray.opacity(0.2))
//                    .foregroundColor(.primary)
//                    .cornerRadius(10)
//
//                    Button(action: {
//                        let teacherData = TeacherSignUpData(
//                            firstName: firstName,
//                            lastName: lastName,
//                            schoolName: schoolName,
//                            areaOfTeaching: department, // or a new areaOfTeaching variable if available
//                            gradeLevels: [gradeLevel],  // wrap string in array or use multi-select array
//                            email: email,
//                            password: password,
//                            confirmPassword: confirmPassword
//                        )
//                        onSignUp(teacherData)
//                    }) {
//                        if isSigningUp {
//                            ProgressView()
//                                .tint(.white)
//                        } else {
//                            Text("Create Account")
//                                .foregroundColor(.white)
//                                .fontWeight(.semibold)
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(isFormValid ? Color.Orange : Color.gray)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                    .disabled(!isFormValid || isSigningUp)
//                }
//            }
//            .padding(.horizontal, 40)
//            .padding(.vertical, 30)
//        }
//    }
//}

// MARK: - Welcome Content View
struct WelcomeContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // MyMarkBook Branding
            VStack(spacing: 20) {
                Image(systemName: "book.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.Orange)

                Text("Welcome to MyMarkBook")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Digital Assessment Made Simple")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Image("MarkbookText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180) // adjust as needed
                    .padding(.horizontal)
            }


            Spacer()

        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Teacher Sign Up Data Model
struct TeacherSignUpData {
    var firstName: String
    var lastName: String
    var schoolName: String
    var areaOfTeaching: String
    var gradeLevels: [String] // Multi-select
    var email: String
    var password: String
    var confirmPassword: String
}


struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
            .environmentObject(AuthenticationViewModel(
                authRepository: FirebaseAuthRepository()
            ))
    }
}
