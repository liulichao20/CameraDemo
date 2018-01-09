Pod::Spec.new do |s|
  s.name             = 'CameraDemo'
  s.version          = '0.1.0'
  s.summary          = ' CameraDemo.'
  s.requires_arc = true
  s.homepage         = 'https://github.com/liulichao20/CameraDemo'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '709857598@qq.com' => 'liulichao20' }
  s.source           = { :git => 'https://github.com/liulichao20/CameraDemo.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'CameraDemo/Classes/**/*'
s.resource_bundles = {'CameraDemo' => ['CameraDemo/Assets/*.{png}']}
 s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
end
