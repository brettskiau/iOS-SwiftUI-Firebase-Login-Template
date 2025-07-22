//  SignUpFormView.swift
//  MyMarkBook

import SwiftUI

struct SignUpFormView: View {
    @Binding var teacherProfile: TeacherSignUpData
    @Binding var isSigningUp: Bool
    var onSubmit: () -> Void
    var onCancel: () -> Void

    @State private var showGradePicker = false
    @State private var showSubjectPicker = false
    @State private var selectedTitle = "Mr"

    let titles = ["Mr", "Mrs", "Ms", "Miss", "Dr"]

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
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Label("", systemImage: "person.crop.circle.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("Create Teacher Account")
                    .font(.largeTitle).bold()
                Text("Join MyMarkBook and start managing your assessments")
                    .foregroundColor(.gray)
            }

            Divider()

            // Account Info
            Text("Account Information")
                .font(.headline)

            HStack(spacing: 12) {
                Picker("Title", selection: $selectedTitle) {
                    ForEach(titles, id: \.self) { title in
                        Text(title)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 100)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

                TextField("First", text: $teacherProfile.firstName)
                    .textContentType(.givenName)
                    .styledTextField()
                    .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button("Previous") { /* focus previous field */ }
                                Button("Next") { /* focus next field */ }
                                Spacer()
                                Button("Done") { /* dismiss keyboard */ }
                            }
                        }

                TextField("Last", text: $teacherProfile.lastName)
                    .textContentType(.familyName)
                    .styledTextField()
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("Previous") { /* focus previous field */ }
                            Button("Next") { /* focus next field */ }
                            Spacer()
                            Button("Done") { /* dismiss keyboard */ }
                        }
                    }
            }

            TextField("E-Mail", text: $teacherProfile.email)
                .textContentType(.emailAddress)
                .styledTextField()
                .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("Previous") { /* focus previous field */ }
                            Button("Next") { /* focus next field */ }
                            Spacer()
                            Button("Done") { /* dismiss keyboard */ }
                        }
                    }

            HStack(spacing: 12) {
                SecureField("Password", text: $teacherProfile.password)
                    .textContentType(.newPassword)
                    .styledTextField()
                    .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button("Previous") { /* focus previous field */ }
                                Button("Next") { /* focus next field */ }
                                Spacer()
                                Button("Done") { /* dismiss keyboard */ }
                            }
                        }
                SecureField("Confirm", text: $teacherProfile.confirmPassword)
                    .textContentType(.newPassword)
                    .styledTextField()
                    .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button("Previous") { /* focus previous field */ }
                                Button("Next") { /* focus next field */ }
                                Spacer()
                                Button("Done") { /* dismiss keyboard */ }
                            }
                        }
            }

            TextField("School", text: $teacherProfile.schoolName)
                .styledTextField()
                .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("Previous") { /* focus previous field */ }
                            Button("Next") { /* focus next field */ }
                            Spacer()
                            Button("Done") { /* dismiss keyboard */ }
                        }
                    }

            // Grade and Subject Pickers
            HStack(spacing: 12) {
                Button(action: { showGradePicker.toggle() }) {
                    HStack {
                        Text(teacherProfile.gradeLevels.isEmpty ? "Year level" : teacherProfile.gradeLevels.joined(separator: ", "))
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button("Previous") { /* focus previous field */ }
                                Button("Next") { /* focus next field */ }
                                Spacer()
                                Button("Done") { /* dismiss keyboard */ }
                            }
                        }
                }

                Button(action: { showSubjectPicker.toggle() }) {
                    HStack {
                        Text(teacherProfile.areaOfTeaching.isEmpty ? "Subject/department" : teacherProfile.areaOfTeaching)
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button("Previous") { /* focus previous field */ }
                                Spacer()
                                Button("Done") { /* dismiss keyboard */ }
                            }
                        }
                }
            }

            // Action Buttons
            HStack(spacing: 20) {
                Spacer()
                Button("Cancel", action: onCancel)
                    .frame(maxWidth: 180)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray))
                Button("Submit", action: onSubmit)
                    .frame(maxWidth: 180)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isSigningUp)
                Spacer()
            }

            Spacer()

            Text("Privacy statement")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
        .sheet(isPresented: $showGradePicker) {
            MultiSelectPicker(title: "Select Grade Levels", options: gradeLevelOptions, selections: $teacherProfile.gradeLevels)
        }
        .sheet(isPresented: $showSubjectPicker) {
            SingleSelectPicker(title: "Select Subject Area", options: teachingAreas, selection: $teacherProfile.areaOfTeaching)
        }
    }
}

struct MultiSelectPicker: View {
    let title: String
    let options: [String]
    @Binding var selections: [String]

    var body: some View {
        NavigationView {
            List(options, id: \.self) { option in
                MultipleSelectionRow(title: option, isSelected: selections.contains(option)) {
                    if selections.contains(option) {
                        selections.removeAll { $0 == option }
                    } else {
                        selections.append(option)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
        }
    }
}

struct SingleSelectPicker: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        NavigationView {
            List(options, id: \.self) { option in
                HStack {
                    Text(option)
                    Spacer()
                    if option == selection {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = option
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .navigationTitle(title)
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                Text(title)
                Spacer()
            }
        }
        .foregroundColor(.primary)
    }
}
