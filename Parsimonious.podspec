Pod::Spec.new do |s|
  s.name         = "Parsimonious"
  s.version      = "1.3.1"
  s.summary      = "A parsimonious little parser combinator framework for Swift"
  s.homepage     = "https://github.com/Prosumma/Parsimonious"
  s.social_media_url = 'http://twitter.com/prosumma'
  s.license      = "MIT"
  s.author             = { "Gregory Higley" => "code@revolucent.net" }
  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"
  s.source       = { :git => "https://github.com/Prosumma/Parsimonious.git", :tag => s.version }
  s.source_files  = "Parsimonious"
  s.requires_arc = true
  s.swift_versions = ['5.0', '5.1'] 
end
