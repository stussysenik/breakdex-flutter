require 'xcodeproj'
require 'fileutils'

project_path = 'ios/Runner.xcodeproj'
scheme_name = 'Runner'

unless File.exist?(project_path)
  puts "Error: #{project_path} not found!"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
test_target = project.targets.find { |t| t.name == 'RunnerUITests' }

if test_target.nil?
  puts "Error: RunnerUITests target not found!"
  exit 1
end

# Find or initialize scheme
shared_dir = Xcodeproj::XCScheme.shared_data_dir(project_path)
FileUtils.mkdir_p(shared_dir) unless Dir.exist?(shared_dir)
shared_scheme_path = shared_dir + "#{scheme_name}.xcscheme"

puts "Shared scheme path: #{shared_scheme_path}"

if File.exist?(shared_scheme_path)
  puts "Loading existing shared scheme..."
  scheme = Xcodeproj::XCScheme.new(shared_scheme_path)
else
  puts "Creating a new scheme..."
  scheme = Xcodeproj::XCScheme.new
end

# Add the test target to test_action if not already present
already_exists = scheme.test_action.testables.any? do |t|
  t.buildable_references && t.buildable_references.any? { |ref| ref.target_name == 'RunnerUITests' }
end

if already_exists
  puts "RunnerUITests target is already in the scheme test action."
else
  puts "Adding RunnerUITests target to scheme test action..."
  scheme.add_test_target(test_target)
  # Save the scheme as shared
  scheme.save_as(project_path, scheme_name, true)
  puts "Scheme saved successfully."
end
