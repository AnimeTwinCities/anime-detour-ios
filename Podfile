source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'
use_frameworks!

pod 'FXForms', '~> 1.2.0'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Anime Detour/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
