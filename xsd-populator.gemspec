GEM_NAME="xsd-populator"
PKG_VERSION='0.0.1'

Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.version = PKG_VERSION
  s.files = `git ls-files`.split($/)
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency 'builder'
  s.add_dependency 'xsd-reader', '>= 0.0.1'
  s.add_dependency 'data-provider', '>= 0.0.1'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'byebug'

  s.author = "Mark van de Korput"
  s.email = "dr.theman@gmail.com"
  s.date = '2015-07-06'
  s.description = %q{A library of Ruby classes for generating XML data from XSD schemas}
  s.summary = %q{A library of Ruby classes for generating XML data from XSD schemas}
  s.homepage = %q{https://github.com/markkorput/xsd-populator}
end
