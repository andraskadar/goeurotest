# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'goeurotest' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for goeurotest

  # DAL
  pod 'RealmSwift', '~> 2.8.3' # Local database

  # Networking
  pod 'Moya/RxSwift', '~> 9.0.0' # Network Abstraction (over Alamofire)
  pod 'Moya-ObjectMapper/RxSwift', '~> 2.4.2' # Object mapping

  # Reactive programming
  pod 'RxCocoa', '~> 3.4.0' # Reactive kit cocoa extension
  pod 'RxSwift', '~> 3.4.0' # Reactive kit swift extension
  pod 'RxOptional', '~> 3.2.0' # Reactive kit extension with optionals
  pod 'RxRealm', '~> 0.6.0' # Reactive Realm extension

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |configuration|
        # these libs work now only with Swift3.2 in Xcode9
        if ['ObjectMapper', 'RxSwift', 'RxCocoa', 'RxOptional', 'RxRealm'].include? target.name
          configuration.build_settings['SWIFT_VERSION'] = "3.2"
        end
      end
    end
  end

end
