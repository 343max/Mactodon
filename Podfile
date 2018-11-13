platform :macos, '10.13'

target 'Mactodon' do
  use_frameworks!

  pod 'Atributika'
  pod 'MastodonKit', :git => 'https://github.com/MastodonKit/MastodonKit.git', :branch => 'master'
  pod 'Nuke'
  pod 'ReachabilitySwift'
  pod 'Starscream'
  
  target 'MactodonTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
