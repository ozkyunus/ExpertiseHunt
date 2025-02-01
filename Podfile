source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'ExpertiseHunt' do
  use_frameworks!

  # Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Analytics'
  
  # GoogleSignIn
  pod 'GoogleSignIn'

  # Gerçek zamanlı bağlantılar için (isteğe bağlı)
  pod 'Firebase/Database'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end