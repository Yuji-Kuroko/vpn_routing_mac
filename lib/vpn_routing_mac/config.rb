require "open3"

module VpnRoutingMac
  class Config
    class InterfaceNotFoundError < StandardError; end
    class DirectoryNameNotFoundError < StandardError; end

    attr_reader :gateway_ip
    attr_reader :dir_path
    attr_accessor :interface

    # @return [VpnRoutingMac::Config, nil]
    def self.load_with_ip(ip_address)
      all_configs.find { |a| a.gateway_ip == ip_address }
    end

    # @return [VpnRoutingMac::Config]
    def self.find_with_directory_name(dirname)
      config = all_configs.find { |a| a.directory_name == dirname }
      raise DirectoryNameNotFoundError.new(dirname) if config.nil?

      config
    end


    # configs in active connection
    # @return [Array<VpnRoutingMac::Config>]
    def self.active_configs
      all_configs.select(&:active_connection?)
    end

    # @return [Array<VpnRoutingMac::Config>]
    def self.all_configs
      config_files = config_dir.glob("config/*/config.yml")

      return [] if config_files.count == 0

      config_files.map { |config_file|
        params = YAML.load_file(config_file)
        self.new(params, dir_path: config_file.dirname)
      }
    end

    def self.config_dir
      if ENV.include?("HOME")
        home_config_dir
      else
        etc_config_dir
      end
    end

    def self.home_config_dir
      Pathname.new("#{ENV.fetch("HOME")}/.vpn-routing")
    end

    def self.etc_config_dir
      Pathname.new("/etc/ppp/config")
    end

    # @return [Pathname] created dir path
    def self.create_config_directory(dir:, gateway_ip:)
      new_config_dir = home_config_dir.join("config/#{dir}")
      new_config_dir.mkpath
      new_config_dir.join("config.yml").write({
        gateway_ip: gateway_ip
      })
      new_config_dir.join("ip_addresses").mkdir
      new_config_dir.join("domains").mkdir

      new_config_dir
    end

    # @return [Array<String>]
    def self.search_ip_with_domain(domain)
      CommandExecutor.instance.execute!("/usr/bin/dig +short #{domain}").lines.map(&:strip).select { |a|
        /\A\d+\.\d+\.\d+\.\d+\z/.match?(a)
      }.map { |ip| "#{ip}/32" }
    end

    # ---

    def initialize(params, dir_path: nil, interface: nil)
      @gateway_ip = params["gateway_ip"]
      @interface = interface
      @dir_path = dir_path
    end

    def directory_name
      @dir_path.basename.to_s
    end

    # @return [Array<String>] ["example.test"]
    def domains
      file_paths = dir_path.glob("domains/*")
      return [] if file_paths.count == 0

      # e.g.
      #   example.test # The example domain
      file_paths.map { |f| f.read.lines.map { |a| a.strip.split("#").first } }.flatten
    end

    # @return [Array<String>] ["192.168.1.1/32"]
    def ip_addresses
      file_paths = dir_path.glob("ip_addresses/*")
      return [] if file_paths.count == 0

      # e.g.
      #   192.168.1.1/32 # local ip
      file_paths.map { |f| f.read.lines.map { |a| a.strip.split("#").first } }.flatten
    end

    # #domains + #ip_addresses
    #
    # @return [Array<String>] ["192.168.1.1/32"]
    def all_ip_addresses
      (domains.map { |domain|
        self.class.search_ip_with_domain(domain)
      }.flatten + ip_addresses).uniq
    end

    # set routing
    # require: MacOS catalina or later.
    #
    # @param [String] ip_address "192.168.191.0/32"
    def route!(ip_address, interface: nil)
      interface ||= self.interface

      raise InterfaceNotFoundError.new(interface) unless interface_exist?(interface)

      CommandExecutor.instance.execute!("/sbin/route add -net #{ip_address} -interface #{interface}")
    end

    def route_all!
      all_ip_addresses.map(&:to_s).map(&:strip).select { |a| %r;\A\d+\.\d+\.\d+\.\d+(/\d+)?\z;.match?(a) }.each do |ip_address|
        route!(ip_address)
      end
    end

    def delete_route!(ip_address, interface: nil)
      interface ||= self.interface

      raise InterfaceNotFoundError.new(interface) unless interface_exist?(interface)

      CommandExecutor.instance.execute!("/sbin/route delete -net #{ip_address} -interface #{interface}")
    end

    def interface(gateway_ip = @gateway_ip)
      @interface ||= fetch_interface(gateway_ip)
    end

    # @param [String] gateway_ip 192.168.1.1
    def fetch_interface(gateway_ip)
      all_interfaces.find { |a|
        CommandExecutor.instance.execute!("/sbin/ifconfig #{a} | grep #{gateway_ip}") rescue false
      }
    end

    def active_connection?(gateway_ip = @gateway_ip)
      fetch_interface(gateway_ip)
    end

    def all_interfaces
      @all_interfaces ||= CommandExecutor.instance.execute!("/sbin/ifconfig -l").strip.split(" ")
    end

    def interface_exist?(interface)
      all_interfaces.include?(interface)
    end

    def save_ip_address!(ip_address, comment)
      cli_config_path = @dir_path.join("ip_addresses/cli.txt")
      cli_config_path.open("a") do |f|
        f.puts "#{ip_address} # #{comment}"
      end

      user = ENV.fetch("USER")

      CommandExecutor.instance.execute!("chown #{user} #{cli_config_path.to_s}")
    end

    def save_domain!(domain, comment)
      cli_config_path = @dir_path.join("domains/cli.txt")
      cli_config_path.open("a") do |f|
        f.puts "#{domain} # #{comment}"
      end

      user = ENV.fetch("USER")
      CommandExecutor.instance.execute!("chown #{user} #{cli_config_path.to_s}")
    end
  end
end
