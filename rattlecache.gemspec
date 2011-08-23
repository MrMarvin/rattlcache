# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "rattlecache"
  s.version     = "0.2"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Marv Cool"]
  s.email       = "marv@hostin.is"
  s.homepage    = "https://github.com/MrMarvin/rattlcache/wiki"
  s.summary     = %q{A smart caching system for battlenet API Requests.}

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency "rspec"
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
