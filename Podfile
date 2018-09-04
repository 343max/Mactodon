platform :macos, '10.13'

target 'Mactodon' do
  use_frameworks!

  pod 'MastodonKit', :git => 'https://github.com/MastodonKit/MastodonKit.git', :branch => 'master'
  pod 'p2.OAuth2', :git => 'https://github.com/p2/OAuth2', :submodules => true

  target 'MactodonTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
