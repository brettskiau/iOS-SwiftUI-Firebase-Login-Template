//
//  SignUpFormView.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 22/7/2025.
//

import SwiftUI

struct SignUpFormView: View {
    @Binding var teacherProfile: TeacherSignUpData
    @Binding var isSigningUp: Bool
    var onSubmit: () -> Void
    var onCancel: () -> Void

    let teachingAreas = [
        "Homeroom Teaching", "Specialist Subject", "Learning Support",
        "Relief Teaching", "Tertiary", "Administration", "Other"
    ]

    let gradeLevelOptions = [
        "Prep/Foundation", "Year 1", "Year 2", "Year 3",
        "Year 4", "Year 5", "Year 6", "Year 7–10",
        "VCE / Senior", "TAFE / Uni", "Other"
    ]

    var body: some View {
        Form {
            Section(header: Text("Teacher Information")) {
                HStack {
                    TextField("First Name", text: $teacherProfile.firstName)
                    TextField("Last Name", text: $teacherProfile.lastName)
                }

                TextField("School Name", text: $teacherProfile.schoolName)

                Picker("Area of Teaching", selection: $teacherProfile.areaOfTeaching) {
                    ForEach(teachingAreas, id: \.self) { area in
                        Text(area)
                    }
                }
            }

            Section(header: Text("Grade Levels")) {
                ForEach(gradeLevelOptions, id: \.self) { level in
                    Toggle(isOn: Binding(
                        get: { teacherProfile.gradeLevels.contains(level) },
                        set: { selected in
                            if selected {
                                teacherProfile.gradeLevels.append(level)
                            } else {
                                teacherProfile.gradeLevels.removeAll { $0 == level }
                            }
                        }
                    )) {
                        Text(level)
                    }
                }
            }

            Section(header: Text("Account Information")) {
                TextField("Email Address", text: $teacherProfile.email)
                SecureField("Password", text: $teacherProfile.password)
                SecureField("Confirm Password", text: $teacherProfile.confirmPassword)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                Spacer()
                Button("Create Account", action: onSubmit)
                    .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Create Teacher Account")
    }
}
