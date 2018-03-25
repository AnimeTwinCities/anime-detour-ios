source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
use_frameworks!

target 'Anime Detour'

pod 'Aspects'
pod 'Firebase/Core'
pod "Firebase/Auth"
pod "Firebase/Database"
pod 'FXForms', '~> 1.2.0'
pod 'Google/Analytics'
pod "Google/SignIn"

plugin 'cocoapods-acknowledgements', :settings_bundle => true , :settings_post_process => Proc.new { |settings_plist_path, umbrella_target|
  puts settings_plist_path
  puts umbrella_target.cocoapods_target_label
}

