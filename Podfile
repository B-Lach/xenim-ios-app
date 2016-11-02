# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'Xenim' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Alamofire is already included in the XenimAPI Framework
  pod 'Parse', '~> 1.10'
  pod 'AlamofireImage'

  target 'XenimUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'XenimToday' do
  use_frameworks!
  pod 'AlamofireImage'
end

target 'XenimAPI' do
  use_frameworks!
  pod 'Alamofire'
  pod 'SwiftyJSON'
end
