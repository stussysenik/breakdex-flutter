require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
unless File.exist?(project_path)
  puts "Error: #{project_path} not found!"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
test_targets = project.targets.select { |t| ['RunnerTests', 'RunnerUITests'].include?(t.name) }

test_targets.each do |target|
  puts "Updating signing settings for: #{target.name}"
  target.build_configurations.each do |config|
    config.build_settings['DEVELOPMENT_TEAM'] = '95MF6RX2GK'
    # Ensure code signing is set to iOS developer standard
    config.build_settings['CODE_SIGN_IDENTITY'] = 'iPhone Developer'
  end
end

project.save
puts "Successfully configured code signing for test targets in Runner.xcodeproj!"
