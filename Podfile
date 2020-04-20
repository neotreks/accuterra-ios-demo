source 'https://github.com/CocoaPods/Specs.git'
source 'https://bgqgokyrqxdhquz4h6qulylgdmngwrknnibwwiaffz4hp3ctcyha:bgqgokyrqxdhquz4h6qulylgdmngwrknnibwwiaffz4hp3ctcyha@neotreks.visualstudio.com/Cocoapods/_git/Specs/'
platform :ios, '10.0'
use_frameworks!

def shared_pods
  pod 'AccuTerraSDK', '~> 0.3-snapshot'
  # pod 'AccuTerraSDK', :path => '../SDK/AccuTerraSDK.podspec'
end

target 'DemoApp(Develop)' do
    shared_pods
end

target 'DemoApp(Test)' do
    shared_pods
end
