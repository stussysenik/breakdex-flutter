require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
unless File.exist?(project_path)
  puts "Error: #{project_path} not found!"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'RunnerUITests' }

if target
  puts "Setting PRODUCT_NAME to 'RunnerUITests' for: #{target.name}"
  target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = 'RunnerUITests'
  end
  project.save
  puts "Successfully updated target build settings!"
else
  puts "Error: RunnerUITests target not found!"
end
