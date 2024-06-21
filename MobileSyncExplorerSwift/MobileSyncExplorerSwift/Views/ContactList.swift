//
//  ContactList.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 3/20/20.
//  Copyright (c) 2020-present, salesforce.com, inc. All rights reserved.
//
//  Redistribution and use of this software in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright notice, this list of conditions
//  and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials provided
//  with the distribution.
//  * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission of salesforce.com, inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import SwiftUI
import MobileSync

struct ContactListView: View {
    @ObservedObject private var viewModel: ContactListViewModel
    private var notificationModel = NotificationListModel()
    @State private var searchTerm: String = ""
    
    init(sObjectDataManager: SObjectDataManager, selectedRecord: String? = nil, newContact: Bool = false, searchFocused: Bool = false) {
        self.viewModel = ContactListViewModel(sObjectDataManager: sObjectDataManager, presentNewContact: newContact, selectedRecord: selectedRecord)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: self.$searchTerm)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 45) {
                        ForEach(viewModel.sObjectDataManager.contacts.filter { contact in
                            self.searchTerm.isEmpty ? true : self.viewModel.contactMatchesSearchTerm(contact: contact, searchTerm: self.searchTerm)
                        }) { contact in
                            Button(action: {
                                viewModel.contactSelected(contact)
                            }) {
                                ContactBox(contact: contact)
                                    .onDrag { return viewModel.itemProvider(contact: contact) }
                            }
                            .frame(width: 300, height: 500)
                            .buttonBorderShape(.roundedRectangle)
//                            .background(SObjectDataManager.dataLocallyDeleted(contact) ? Color.contactCellDeletedBackground : .clear)
//                            .shadow(radius: 5)
                        }
                        
                        Button(action: {
                            viewModel.newContactToggled()
                        }) {
                            AddContactBox()
                        }
                        .buttonBorderShape(.roundedRectangle)
                        Spacer()
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.leading, 20)
                }
                
                Spacer()
                
                NavigationLink(destination: ContactDetailView(localId: viewModel.selectedRecord, sObjectDataManager: self.viewModel.sObjectDataManager, dismiss: { self.viewModel.dismissDetail()}), isActive: $viewModel.showContactDetail) { EmptyView() }
                
                if viewModel.alertContent != nil {
                    StatusAlert(viewModel: viewModel)
                }
            }
            .navigationBarTitle("MobileSync Explorer", displayMode: .inline)
            .navigationBarItems(trailing: NavBarButtons(viewModel: viewModel, notificationModel: notificationModel))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            self.notificationModel.fetchNotifications()
        }
    }
}

struct ContactBox: View {
    var contact: ContactSObjectData
    @State private var isHovered: Bool = false

    var body: some View {
        VStack {
            Image(uiImage: ContactHelper.initialsImage(ContactHelper.colorFromContact(lastName: contact.lastName), initials: ContactHelper.initialsStringFromContact(firstName: contact.firstName, lastName: contact.lastName))!)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .cornerRadius(10)
                .padding(20)
            
            Text(ContactHelper.nameStringFromContact(firstName: contact.firstName, lastName: contact.lastName))
                .font(.largeTitle)
                .foregroundColor(Color(UIColor.label))
            
            Text(ContactHelper.titleStringFromContact(title: contact.title))
                .font(.title)
                .foregroundColor(.secondary)
            
            //Spacer()
            
            HStack(spacing:20) {
                if let mobilePhone = contact.mobilePhone{
                    Button(action: {
                        print("Phone call triggered")
                        if let url = URL(string: "tel:\(mobilePhone)"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        print("iMessage triggered")
                        if let url = URL(string: "sms:\(mobilePhone)"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "message.fill")
                            .foregroundColor(.white)
                    }
                }
                if let email = contact.email{
                    Button(action: {
                        print("Email triggered")
                        if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .buttonBorderShape(.circle)
            
            //Spacer()
        }
        
        
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .frame(width: 300, height: 400)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}

struct AddContactBox: View {
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
            
            Spacer()
            
        }
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .shadow(radius: 10)
        .frame(width: 100, height: 140)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}





struct StatusAlert: View {
    @ObservedObject var viewModel: ContactListViewModel

    func twoButtonDisplay() -> Bool {
        if let alertContent = viewModel.alertContent {
            return alertContent.okayButton && alertContent.stopButton
        }
        return false
    }

    func stopButton() -> Bool {
        return viewModel.alertContent?.stopButton ?? false
    }

    func okayButton() -> Bool {
        return viewModel.alertContent?.okayButton ?? false
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
            VStack {
                Text(viewModel.alertContent?.title ?? "").bold()
                Text(viewModel.alertContent?.message ?? "").lineLimit(nil)
                
                if stopButton() || okayButton() {
                    Divider()
                    HStack {
                        if stopButton() {
                            if twoButtonDisplay() {
                                Spacer()
                            }
                            Button(action: {
                                self.viewModel.alertStopTapped()
                            }, label: {
                                Text("Stop").foregroundColor(Color.blue)
                            })
                        }
                        
                        if twoButtonDisplay() {
                            Spacer()
                            Divider()
                            Spacer()
                        }

                        if okayButton() {
                            Button(action: {
                                self.viewModel.alertOkTapped()
                            }, label: {
                                Text("Ok").foregroundColor(Color.blue)
                            })
                            if twoButtonDisplay() {
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 30)
                }
            }
            .padding(10)
            .frame(maxWidth: 300, minHeight: 100)
            .background(Color(UIColor.secondarySystemBackground))
            .opacity(1.0)
            .foregroundColor(Color(UIColor.label))
            .cornerRadius(20)
        }
    }
}

enum ModalAction: Identifiable {
    case switchUser
    case inspectDB

    var id: Int {
        return self.hashValue
    }
}

import SwiftUI

struct NavBarButtons: View {
    @ObservedObject var viewModel: ContactListViewModel
    @ObservedObject var notificationModel: NotificationListModel
    @State private var modalPresented: ModalAction?
    @State private var customActionSheetPresented = false
    @State private var logoutAlertPresented = false
    @State private var syncAlertPresented = false // New state for sync alert
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            HStack {
                Button(action: {
                    viewModel.newContactToggled()
                }, label: { Image("plusButton").renderingMode(.template) })

                Button(action: {
                    self.showSyncAlert()
                }, label: { Image("sync").renderingMode(.template) })

                Button(action: {
                    self.customActionSheetPresented = true
                }, label: { Image("setting").renderingMode(.template) })
                .sheet(isPresented: $customActionSheetPresented) {
                    CustomActionSheet(viewModel: viewModel, logoutAlertPresented: $logoutAlertPresented, modalPresented: $modalPresented)
                        .frame(width: 400, height: 500) // Adjust the size of the settings view
                }

                NotificationBell(notificationModel: notificationModel, sObjectDataManager: self.viewModel.sObjectDataManager)

            }
        }
        .alert(isPresented: $syncAlertPresented, content: {
            Alert(title: Text("Sync Complete"),
                  message: Text("Data synced successfully."),
                  dismissButton: .default(Text("OK")))
        })
    }

    private func showSyncAlert() {
        self.viewModel.syncUpDown() // Perform sync action
        self.syncAlertPresented = true // Show the sync alert
    }
}

struct CustomActionSheet: View {
    @ObservedObject var viewModel: ContactListViewModel
    @Binding var logoutAlertPresented: Bool
    @Binding var modalPresented: ModalAction?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Button("Show Info") {
                    self.viewModel.showInfo()
                }
                Button("Clear Local Data") {
                    self.viewModel.clearLocalData()
                }
                Button("Refresh Local Data") {
                    self.viewModel.refreshLocalData()
                }
                Button("Sync Down") {
                    self.viewModel.syncDown()
                }
                Button("Sync Up") {
                    self.viewModel.syncUp()
                }
                Button("Clean Sync Ghosts") {
                    self.viewModel.cleanGhosts()
                }
                Button("Stop Sync Manager") {
                    self.viewModel.stopSyncManager()
                }
                Button("Resume Sync Manager") {
                    self.viewModel.resumeSyncManager()
                }
                Button("Logout") {
                    self.logoutAlertPresented = true
                }
                Button("Switch User") {
                    self.modalPresented = ModalAction.switchUser
                }
                Button("Inspect DB") {
                    self.modalPresented = ModalAction.inspectDB
                }
                Button("Cancel", role: .cancel) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Additional Actions")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(InsetGroupedListStyle())
        }
    }
}




struct NotificationBell: View {
    @ObservedObject var notificationModel: NotificationListModel
    var sObjectDataManager: SObjectDataManager

    var body: some View {
        NavigationLink(destination: NotificationList(model: notificationModel, sObjectDataManager: sObjectDataManager)) {
            ZStack {
                Image(systemName: "bell.fill").frame(width: 20, height: 30, alignment: .center)
                if notificationModel.unreadCount() > 0 {
                    ZStack {
                        Circle().foregroundColor(.red)
                        Text("\(notificationModel.unreadCount())").foregroundColor(.white).font(Font.system(size: 12))
                    }
                    .frame(width: 12, height: 12)
                    .position(x: 15, y: 10)
                }
              }
              .frame(width: 20, height: 30)
        }
    }
}

struct ContactCell: View {
    var contact: ContactSObjectData

    var body: some View {
        HStack {
            Image(uiImage: ContactHelper.initialsImage(ContactHelper.colorFromContact(lastName: contact.lastName), initials: ContactHelper.initialsStringFromContact(firstName: contact.firstName, lastName: contact.lastName))!)
            VStack(alignment: .leading) {
                Text(ContactHelper.nameStringFromContact(firstName: contact.firstName, lastName: contact.lastName)).font(.appRegularFont(16)).foregroundColor(Color(UIColor.label))
                Text(ContactHelper.titleStringFromContact(title: contact.title)).font(.appRegularFont(12)).foregroundColor(.secondaryLabelText)
            }
            Spacer()
            if SObjectDataManager.dataLocallyUpdated(contact) {
                Image(systemName: "arrow.2.circlepath").foregroundColor(.appBlue)
            }
            if SObjectDataManager.dataLocallyCreated(contact) {
                Image(systemName: "plus").foregroundColor(.appBlue)
            }
        }
        .padding([.all], 10)
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}

struct InspectorViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = InspectorViewController
    var store: SmartStore

    func updateUIViewController(_ uiViewController: InspectorViewController, context: Context) {
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<InspectorViewControllerWrapper>) -> InspectorViewControllerWrapper.UIViewControllerType {
        return InspectorViewController(store: store)
    }
}

struct SalesforceUserManagementViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = SalesforceUserManagementViewController
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<SalesforceUserManagementViewControllerWrapper>) -> SalesforceUserManagementViewControllerWrapper.UIViewControllerType {
        return SalesforceUserManagementViewController { _ in
            self.presentationMode.wrappedValue.dismiss()
        }
    }

    func updateUIViewController(_ uiViewController: SalesforceUserManagementViewControllerWrapper.UIViewControllerType, context: UIViewControllerRepresentableContext<SalesforceUserManagementViewControllerWrapper>) {
    }
}

#Preview {
    let credentials = OAuthCredentials(identifier: "test", clientId: "", encrypted: false)!
    let userAccount = UserAccount(credentials: credentials)
    let sObjectManager = SObjectDataManager.sharedInstance(for: userAccount)
    
    return ContactListView(sObjectDataManager: sObjectManager)
}
