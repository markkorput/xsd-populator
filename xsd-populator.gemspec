Gem::Specification.new do |s|
  s.name = "xsd-populator"
  s.version = '0.2.0'
  s.files = `git ls-files`.split($/)
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency 'builder', '~> 3.2'
  s.add_dependency 'xsd-reader', '~> 0.2'
  s.add_dependency 'data-provider', '~> 0.2'
  s.add_development_dependency 'nokogiri', '~> 1.6'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'byebug', '~> 5.0'

  s.author = "Mark van de Korput"
  s.email = "dr.theman@gmail.com"
  s.date = '2015-08-27'
  s.summary = %q{A Ruby gem to build XML data from XSD schemas}
  s.description = s.summary
  s.homepage = %q{https://github.com/markkorput/xsd-populator}
  s.license = "MIT"
end
