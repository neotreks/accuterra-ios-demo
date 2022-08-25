source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/neotreks/Specs/'

#
#  In order to download SDK binary from distribution.accuterra.com you need to set credentials in .netrc file:
#
#  machine distribution.accuterra.com
#  login ###
#  password ###
#
#  Please ask NeoTreks to provide you these credentials. If you already have access to SDK documentation you can use the same credentials.
#

platform :ios, '13.0'
use_frameworks!

def shared_pods
  pod 'AccuTerraSDK', '~> 0.25.2'
  # UI pods
  pod 'StarryStars', '~> 1.0.0'
  pod 'AlignedCollectionViewFlowLayout'
  pod 'Kingfisher', '~> 5.0'
  # Analytics
  pod 'Firebase/Crashlytics', '8.7.0'
  pod 'Firebase/Analytics', '8.7.0'
end

target 'DemoApp(Develop)' do
    shared_pods
end

target 'DemoApp(Test)' do
    shared_pods
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        end
    end
end
