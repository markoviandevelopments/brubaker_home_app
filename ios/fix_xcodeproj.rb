require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if Release configuration exists
unless project.build_configurations.any? { |config| config.name == 'Release' }
  profile_config = project.build_configurations.find { |config| config.name == 'Profile' }
  if profile_config
    release_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
    release_config.name = 'Release'
    release_config.build_settings = profile_config.build_settings.dup
    project.build_configurations << release_config
  else
    raise 'Profile configuration not found'
  end
end

# Ensure code signing is disabled for all configurations
project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    config.build_settings['CODE_SIGN_IDENTITY'] = ''
    config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  end
end

project.save
