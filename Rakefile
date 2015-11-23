require 'rubygems'
Gem::manage_gems
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'



desc "Generate documentation"
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "Rcrawl"
  rdoc.options << "--line-numbers"
  rdoc.options << "--inline-source"
  rdoc.rdoc_files.include("README")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

spec = Gem::Specification.new do |s|
  s.name         = "rcrawl"
  s.version      = "0.5.1"
  s.author       = "Digital Duckies"
  s.email        = "rcrawl@digitalduckies.net"
  s.homepage     = "http://digitalduckies.net"
  s.platform     = Gem::Platform::RUBY
  s.summary      = "A web crawler written in ruby"
  s.files        = FileList["{test,lib}/**/*", "README", "MIT-LICENSE", "Rakefile", "TODO"].to_a
  s.require_path = "lib"
  s.autorequire  = "rcrawl.rb"
  s.has_rdoc     = true
  s.extra_rdoc_files = ["README", "MIT-LICENSE", "TODO"]
  s.add_dependency("scrapi", ">=1.2.0")
  s.rubyforge_project = "rcrawl"
end

gem = Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end
