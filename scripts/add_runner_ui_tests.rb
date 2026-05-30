require 'xcodeproj'
require 'fileutils'

project_path = 'ios/Runner.xcodeproj'
unless File.exist?(project_path)
  puts "Error: ios/Runner.xcodeproj not found!"
  exit 1
end

project = Xcodeproj::Project.open(project_path)

# 1. Create target if not exists
target_name = 'RunnerUITests'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Creating RunnerUITests target..."
  target = project.new_target(:ui_test_bundle, target_name, :ios, '17.0', project.products_group)
else
  puts "RunnerUITests target already exists."
end

# 2. Setup directories and files
Dir.mkdir('ios/RunnerUITests') unless Dir.exist?('ios/RunnerUITests')

info_plist_path = 'ios/RunnerUITests/Info.plist'
unless File.exist?(info_plist_path)
  File.write(info_plist_path, <<~XML)
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>CFBundleDevelopmentRegion</key>
    	<string>$(DEVELOPMENT_LANGUAGE)</string>
    	<key>CFBundleExecutable</key>
    	<string>$(EXECUTABLE_NAME)</string>
    	<key>CFBundleIdentifier</key>
    	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    	<key>CFBundleInfoDictionaryVersion</key>
    	<string>6.0</string>
    	<key>CFBundleName</key>
    	<string>$(PRODUCT_NAME)</string>
    	<key>CFBundlePackageType</key>
    	<string>BNDL</string>
    	<key>CFBundleShortVersionString</key>
    	<string>1.0</string>
    	<key>CFBundleSignature</key>
    	<string>????</string>
    	<key>CFBundleVersion</key>
    	<string>1</string>
    </dict>
    </plist>
  XML
end

runner_m_path = 'ios/RunnerUITests/RunnerUITests.m'
unless File.exist?(runner_m_path)
  File.write(runner_m_path, <<~OBJC)
    @import XCTest;
    @import patrol;
    @import ObjectiveC.runtime;

    PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
  OBJC
end

# Ensure RunnerUITests group exists in project
group = project.main_group.find_subpath('RunnerUITests', true)

# Add file references to the project group
plist_ref = group.find_file_by_path('Info.plist') || group.new_file('Info.plist')
m_ref = group.find_file_by_path('RunnerUITests.m') || group.new_file('RunnerUITests.m')

# Add compiled source to the target
unless target.source_build_phase.files.any? { |f| f.file_ref && f.file_ref.path == 'RunnerUITests.m' }
  target.add_file_references([m_ref])
end

# 3. Configure Build Settings
target.build_configurations.each do |config|
  config.build_settings['TEST_TARGET_NAME'] = 'Runner'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.breakdex.breakdex.RunnerUITests'
  config.build_settings['INFOPLIST_FILE'] = 'RunnerUITests/Info.plist'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @loader_path/Frameworks'
end

# 4. Link test target with main target dependency
main_target = project.targets.find { |t| t.name == 'Runner' }
if main_target
  puts "Linking to Runner target dependency..."
  unless target.dependencies.any? { |dep| dep.target == main_target }
    target.add_dependency(main_target)
  end
end

project.save
puts "Successfully configured RunnerUITests target in Runner.xcodeproj!"
