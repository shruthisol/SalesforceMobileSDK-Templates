//
//  ContactDetailViewModel.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 7/9/20.
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

class ContactDetailViewModel: ObservableObject {
    @Published var contact: ContactSObjectData
    var isNewContact: Bool = false
    var title: String
    private var sObjectDataManager: SObjectDataManager

    init(id: String, sObjectDataManager: SObjectDataManager) {
        self.sObjectDataManager = sObjectDataManager
        self._contact = Published(initialValue: ContactSObjectData())
        self.title = "Loading contact"
        fetchContact(id: id)
    }
    
    init(localId: String?, sObjectDataManager: SObjectDataManager) {
        self.sObjectDataManager = sObjectDataManager
        self._contact = Published(initialValue: ContactSObjectData())

        if let localId = localId {
            self.title = "Loading contact"
            loadContact(id: localId)
        } else {
            self.title = "New Contact"
            self.isNewContact = true
        }
    }

    func isLocallyDeleted() -> Bool {
        return SObjectDataManager.dataLocallyDeleted(contact)
    }

    func fetchContact(id: String) {
        sObjectDataManager.fetchContact(id: id) { contact in
            if let contact = contact {
                self.contact = contact
                self.title = ContactHelper.nameStringFromContact(firstName: contact.firstName, lastName: contact.lastName)
            } else {
                self.title = "Unable to load contact"
            }
        }
    }

    func loadContact(id: String) {
        if let contact = sObjectDataManager.localRecord(soupID: id) {
            self.contact = contact
            self.title = ContactHelper.nameStringFromContact(firstName: contact.firstName, lastName: contact.lastName)
        } else {
            self.title = "Unable to load contact"
        }
    }
    
    func deleteButtonTitle() -> String {
        return isLocallyDeleted() ? "Undelete" : "Delete"
    }

    func deleteButtonTapped() {
        if isLocallyDeleted() {
            sObjectDataManager.undeleteLocalData(contact)
        } else {
            sObjectDataManager.deleteLocalData(contact)
        }
    }

    func saveButtonTapped() -> ContactSObjectData.ID? {
        if self.isNewContact {
            let data = sObjectDataManager.createLocalData(contact)
            if let newContact = data?.first as? [String : Any]{
                let user = ContactSObjectData(soupDict: newContact)
                return user.id
            }
        } else {
            sObjectDataManager.updateLocalData(contact)
        }
        return nil
    }
    
}
