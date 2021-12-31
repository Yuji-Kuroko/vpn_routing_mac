module VpnRoutingMac
  class Application
    class DefaultGatewayNotFound; end

    class << self
      # load
      def setup
        require "bundler/setup"
        require "yaml"
        project_root.glob("lib/**/*.rb").each do |path|
          require path
        end
      end

      def project_root
        Pathname.new("#{__dir__}/../..")
      end

      def set_default_gateway!
        cmd_active_interface_name = <<~CMD
          /sbin/ifconfig | /usr/bin/grep -o '^en[0-9]*' | /usr/bin/xargs -n1 -I{} /bin/zsh -c "/sbin/ifconfig {} | /usr/bin/grep 'inet ' > /dev/null && echo {}"
        CMD
        active_interface_name = CommandExecutor.instance.execute!(cmd_active_interface_name, exception: false).strip
        raise DefaultGatewayNotFound if active_interface_name == ""

        cmd = "/sbin/route change default -interface #{active_interface_name}"
        CommandExecutor.instance.execute!(cmd)
      end

      def recent_vpn_log_path
        VpnRoutingMac::Config.etc_config_dir.join("recent.log")
      end

      def cmd_ip_up(remote_ip:, interface_name:, local_ip:, tty_device:, speed:, ipparam:)
        # logging vpn info
        recent_vpn_log_path.open("a") do |f|
          f.puts("#{Time.now}:#{interface_name}:#{remote_ip}")
        end

        config = VpnRoutingMac::Config.load_with_ip(remote_ip)
        config.interface = interface_name
        config.route_all!

        set_default_gateway!
      end

      def cmd_reload
        VpnRoutingMac::Config.active_configs.each do |config|
          config.route_all!
        end
      end

      def cmd_add_domain(domain, permanent:, comment:, dir: nil)
        config = config_with_dir(dir)
        ip_addresses = VpnRoutingMac::Config.search_ip_with_domain(domain)
        ip_addresses.each do |ip|
          config.route!(ip)
          puts "added: #{ip}"
        end

        if permanent
          config.save_domain!(domain, comment)
        end
      end

      def cmd_delete_domain(domain, dir: nil)
        config = config_with_dir(dir)
        ip_addresses = VpnRoutingMac::Config.search_ip_with_domain(domain)
        ip_addresses.each do |ip|
          config.delete_route!(ip)
          puts "deleted: #{ip}"
        end
      end

      def cmd_add_ip(ip, permanent:, comment:, dir: nil)
        config = config_with_dir(dir)
        config.route!(ip)
        puts "added: #{ip}"

        if permanent
          config.save_ip_address!(ip, comment)
        end
      end

      def cmd_delete_ip(ip, dir: nil)
        config = config_with_dir(dir)
        config.delete_route!(ip)
        puts "deleted: #{ip}"
      end

      def config_with_dir(dir)
        config = if dir
          VpnRoutingMac::Config.find_with_directory_name(dir)
        else
          all_configs = VpnRoutingMac::Config.all_configs
          raise "required: --dir option" if all_configs.count >= 2

          # 1 directory only
          all_configs.first
        end
      end

      def cmd_create_config(dir:, gateway_ip:)
        new_dir_path = VpnRoutingMac::Config.create_config_directory(dir: dir, gateway_ip: gateway_ip)
        puts "created: #{new_dir_path.to_s}"
      end

      # setup /etc/ppp/ip-up
      def cmd_install
        VpnRoutingMac::Installer.new.install
      end

      # delete /etc/ppp/ip-up
      def cmd_uninstall
        VpnRoutingMac::Installer.new.uninstall
      end
    end
  end
end
