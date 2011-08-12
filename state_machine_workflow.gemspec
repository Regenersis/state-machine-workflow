# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "state_machine_workflow/version"

Gem::Specification.new do |s|
  s.name        = "state_machine_workflow"
  s.version     = StateMachineWorkflow::VERSION
  s.authors     = ["Colin Gemmell"]
  s.email       = ["pythonandchips@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "state_machine_workflow"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_runtime_dependency "state_machine"
  s.add_runtime_dependency "activerecord"
end
