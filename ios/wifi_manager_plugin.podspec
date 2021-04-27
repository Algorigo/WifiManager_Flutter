#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wifi_manager_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wifi_manager_plugin'
  s.version          = '1.0.0'
  s.summary          = 'Wifi Manager Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'https://www.algorigo.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'rouddy@naver.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.framework       = 'NetworkExtension'
  s.dependency      'RxSwift', '6.1.0'
  s.dependency      'RxCocoa', '6.1.0'
end
