require_relative 'lib/vpn_routing_mac/version'

Gem::Specification.new do |spec|
  spec.name          = "vpn_routing_mac"
  spec.version       = VpnRoutingMac::VERSION
  spec.authors       = ["Yuji Kuroko"]
  spec.email         = ["patye.roifure+gem@gmail.com"]

  spec.summary       = %q{Mac VPN routing setting tool.}
  spec.description   = %q{Mac VPN routing setting tool.}
  spec.homepage      = "https://github.com/Yuji-Kuroko/vpn_routing_mac"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Yuji-Kuroko/vpn_routing_mac"
  spec.metadata["changelog_uri"] = "https://github.com/Yuji-Kuroko/vpn_routing_mac"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~>1.1.0"
end
