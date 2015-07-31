Gem::Specification.new do |s|
  s.name = "xsd-populator"
  s.version = '0.1.0'
  s.files = `git ls-files`.split($/)
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency 'builder', '~> 3.2'
  s.add_dependency 'xsd-reader', '~> 0.1'
  s.add_dependency 'data-provider', '~> 0.1'
  s.add_development_dependency 'nokogiri', '~> 1.6'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'byebug', '~> 5.0'

  s.author = "Mark van de Korput"
  s.email = "dr.theman@gmail.com"
  s.date = '2015-07-14'
  s.summary = %q{A Ruby gem to build XML data from XSD schemas}
  s.description = %q{A library of Ruby classes for generating XML data from XSD schemas (Data providers)}
  s.homepage = %q{https://github.com/markkorput/xsd-populator}
  s.license = "MIT"
end
