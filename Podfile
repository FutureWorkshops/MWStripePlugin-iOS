source 'https://cdn.cocoapods.org/'
source 'https://github.com/FutureWorkshops/MWPodspecs.git'

workspace 'MWStripe'
platform :ios, '15.0'

inhibit_all_warnings!
use_frameworks!

project 'MWStripe/MWStripe.xcodeproj'
project 'MWStripePlugin/MWStripePlugin.xcodeproj'

abstract_target 'MWStripe' do
  pod 'MobileWorkflow'
  pod 'Stripe'

  target 'MWStripe' do
    project 'MWStripe/MWStripe.xcodeproj'

    target 'MWStripeTests' do
      inherit! :search_paths
    end
  end

  target 'MWStripePlugin' do
    project 'MWStripePlugin/MWStripePlugin.xcodeproj'

    target 'MWStripePluginTests' do
      inherit! :search_paths
    end
  end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ""
        config.build_settings['CODE_SIGN_IDENTITY'] = ""
        config.build_settings['DEVELOPMENT_TEAM'] = ""
        config.build_settings['CODE_SIGN_STYLE'] = "Manual"
    end
  end
end
