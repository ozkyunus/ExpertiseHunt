import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainMenuView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showImagePicker = false
    @State private var showUsernameEdit = false
    @Binding var isUserLoggedIn: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    HStack(spacing: 15) {
                        Button(action: { showImagePicker = true }) {
                            if let profileImage = viewModel.profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .foregroundColor(.gray)
                            }
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(viewModel.profile?.username ?? "Kullanıcı")
                                .font(.title2)
                            Text("ID: \(viewModel.profile?.userID ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        VStack(spacing: 20) {
                            Button(action: { viewModel.showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 22))
                            }
                            
                            Button(action: {
                                do {
                                    try AuthService.shared.signOut()
                                    isUserLoggedIn = false
                                } catch {
                                    print("Çıkış yapılırken hata: \(error)")
                                }
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                    .font(.system(size: 22))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    HStack {

                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 22))
                            Text("\(viewModel.profile?.score ?? 0)")
                                .font(.title2)
                        }
                        
                        Spacer()
                            .frame(width: 40)

                        NavigationLink(destination: FriendsView()) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 22))
                                Text("\(viewModel.profile?.friendCount ?? 0)")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 15)

                    VStack(spacing: 12) {
                        RoomButton(
                            title: "Socrates Özel",
                            image: "socrates_logo",
                            category: "socrates_questions"
                        )
                        RoomButton(
                            title: "Htalks Özel",
                            image: "htalks_logo",
                            category: "htalks_questions"
                        )
                        RoomButton(
                            title: "SAÇ Özel",
                            image: "sac_logo",
                            category: "sac_ozel_questions"
                        )
                        RoomButton(
                            title: "Süper Lig Gurme",
                            image: "superlig_logo",
                            category: "superlig_gurme_questions"
                        )
                        RoomButton(
                            title: "Medya Devi Özel",
                            image: "medyadevi_logo",
                            category: "medya_devi_questions"
                        )
                        RoomButton(
                            title: "Derin Futbol Özel",
                            image: "derin_futbol_logo",
                            category: "derin_futbol_questions"
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            .background(Color.black)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $viewModel.selectedImage)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(isUserLoggedIn: $isUserLoggedIn)
        }
        .onAppear {
            viewModel.loadProfile()
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
} 
