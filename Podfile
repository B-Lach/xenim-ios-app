# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'Xenim' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Alamofire is already included in the XenimAPI Framework
  # pod 'Alamofire', git: 'https://github.com/Alamofire/Alamofire.git', branch: 'swift3'
  pod 'AlamofireImage', git: 'https://github.com/Alamofire/AlamofireImage.git', branch: 'beta6'
  # pod 'AlamofireNetworkActivityIndicator', '~> 1.0'
  pod 'Parse', '~> 1.10'

  target 'XenimUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'XenimToday' do
  use_frameworks!
  pod 'AlamofireImage', git: 'https://github.com/Alamofire/AlamofireImage.git', branch: 'beta6'
end

target 'XenimAPI' do
  use_frameworks!
  pod 'Alamofire', git: 'https://github.com/Alamofire/Alamofire.git', branch: 'swift3'
  pod 'SwiftyJSON', git: 'https://github.com/SwiftyJSON/SwiftyJSON.git', branch: 'swift3'
end
