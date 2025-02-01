import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                if let currentUserID = viewModel.currentUserID {
                    HStack {
                        Text("ID'niz: \(currentUserID)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            UIPasteboard.general.string = currentUserID
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                HStack {
                    TextField("Arkadaş ID'si girin", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($isSearchFocused)
                        .onChange(of: searchText) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                searchText = filtered
                            }
                            if filtered.count > 6 {
                                searchText = String(filtered.prefix(6))
                            }
                        }
                    
                    Button(action: {
                        isSearchFocused = false
                        guard !searchText.isEmpty else { return }
                        Task {
                            do {
                                try await viewModel.sendFriendRequest(to: searchText)
                                searchText = ""
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.blue)
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            ScrollView {
                LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                    // Arkadaşlık İstekleri Bölümü
                    if !viewModel.friendRequests.isEmpty {
                        Section(header: sectionHeader("Arkadaşlık İstekleri")) {
                            ForEach(viewModel.friendRequests) { request in
                                requestRow(for: request)
                            }
                        }
                    }
                    Section(header: sectionHeader("Arkadaşlarım (\(viewModel.friends.count))")) {
                        if viewModel.friends.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(viewModel.friends) { friend in
                                friendRow(for: friend)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Arkadaşlar")
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Arkadaşlıktan çıkar", isPresented: $viewModel.showDeleteConfirmation) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                if let friend = viewModel.friendToDelete {
                    Task {
                        do {
                            try await viewModel.removeFriend(friend)
                            viewModel.friendToDelete = nil
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
        }
        .task {
            do {
                await viewModel.loadFriends()
                viewModel.startListeningToRequests()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .onDisappear {
            viewModel.stopListeningToRequests()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Tamam") {
                    isSearchFocused = false
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func requestRow(for request: User) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(request.username.isEmpty ? request.email : request.username)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Button(action: {
                    Task {
                        do {
                            try await viewModel.acceptFriendRequest(from: request)
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                
                Button(action: {
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func friendRow(for friend: User) -> some View {
        HStack {
            Text(friend.username.isEmpty ? friend.email : friend.username)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                viewModel.friendToDelete = friend
                viewModel.showDeleteConfirmation = true
            }) {
                Image(systemName: "person.badge.minus")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("Henüz arkadaşınız yok")
                .foregroundColor(.gray)
            Text("Arkadaş eklemek için yukarıdan ID ile arama yapabilirsiniz")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
} 
