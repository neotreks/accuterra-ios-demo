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

platform :ios, '11.0'
use_frameworks!

def shared_pods
  pod 'AccuTerraSDK', '0.11.0'
  # UI pods
  pod 'StarryStars', '~> 1.0.0'
  pod 'Kingfisher'
  pod 'AlignedCollectionViewFlowLayout'
end

target 'DemoApp(Develop)' do
    shared_pods
end

target 'DemoApp(Test)' do
    shared_pods
end
