source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.0'
use_frameworks!

target 'Anime Detour'

pod 'Aspects'
pod 'GoogleAnalytics'
pod 'FXForms', '~> 1.2.0'

plugin 'cocoapods-acknowledgements', :settings_bundle => true , :settings_post_process => Proc.new { |settings_plist_path, umbrella_target|
  puts settings_plist_path
  puts umbrella_target.cocoapods_target_label
}

