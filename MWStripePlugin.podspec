Pod::Spec.new do |s|
    s.name                  = 'MWStripePlugin'
    s.version               = '0.2.1'
    s.summary               = 'Stripe plugin for MobileWorkflow on iOS.'
    s.description           = <<-DESC
    Stripe plugin for MobileWorkflow on iOS, containg Stripe related steps:
	- MWStripeStep
    DESC
    s.homepage              = 'https://www.mobileworkflow.io'
    s.license               = { :type => 'Copyright', :file => 'LICENSE' }
    s.author                = { 'Future Workshops' => 'info@futureworkshops.com' }
    s.source                = { :git => 'https://github.com/FutureWorkshops/MWStripePlugin-iOS.git', :tag => "#{s.version}" }
    s.platform              = :ios
    s.swift_version         = '5'
    s.ios.deployment_target = '15.0'
	s.default_subspecs      = 'Core'
	
    s.subspec 'Core' do |cs|
        cs.dependency            'MobileWorkflow', '~> 2.1.0'
        cs.dependency            'Stripe', '~> 22.8.4'
        cs.source_files          = 'MWStripePlugin/MWStripePlugin/**/*.swift'
        cs.resources             = ['MWStripePlugin/MWStripePlugin/**/*.strings']
    end
end
