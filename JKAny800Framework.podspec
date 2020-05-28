#
# Be sure to run `pod lib lint JKAny800Framework.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JKAny800Framework'
  s.version          = '1.0.0'
  s.summary          = '这是久科Any800的sdk，可以快速集成和实现IM聊天'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "当前版本支持真机和模拟器运行，是关于访客端的SDK，具体使用请联系久科客服进行相关注册appkey和appSecret等"

  s.homepage         = 'https://github.com/jerryzhengwen/JKAny800Framework'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ilucklyzhengwen@163.com' => 'jerry.gu@9client.com' }
  s.source           = { :git => 'https://github.com/jerryzhengwen/JKAny800Framework.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.platform     = :ios, "9.0"
  s.libraries = "resolv", "xml2","icucore"
  s.source_files = 'JKAny800Framework/**/Classes/**/*.{h,m}','JKAny800Framework/**/UI/**/*.{h,m}',
  s.public_header_files = 'JKAny800Framework/**/Classes/**/*.h'
  s.ios.vendored_libraries = 'JKAny800Framework/**/Frameworks/**/*.a'
  s.resources = 'JKAny800Framework/**/UIKit/**/{JKDialogeModel.xcdatamodeld,JKFace.plist,JKIMImage.bundle,style.css}'
  s.xcconfig = { 'VALID_ARCHS' => 'arm64 x86_64 armv7 i386', }
  s.frameworks = 'UIKit', 'MapKit'
  s.requires_arc = false

  s.requires_arc = ['JKAny800Framework/**/Classes/*.{h,m}']
  s.dependency 'YYWebImage'
  s.dependency 'MJRefresh'
  s.dependency 'MBProgressHUD', '~> 1.1.0'
  s.dependency 'IQKeyboardManager'
end
