# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "state_machine_workflow/version"

Gem::Specification.new do |s|
  s.name        = "state_machine_workflow"
  s.version     = StateMachineWorkflow::VERSION
  s.authors     = ["VN2 Developers"]
  s.email       = ["vn2developers@regenersis.com"]
  s.homepage    = ""
  s.summary     = %q{Workflow extensions for the state machine gem}
  s.description = %q{Workflow extensions for the state machine gem}

  s.rubyforge_project = "state_machine_workflow"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "state_machine", "1.0.2"
  s.add_runtime_dependency "activerecord", "~>3.1.11"
end
