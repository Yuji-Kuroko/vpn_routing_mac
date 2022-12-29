module VpnRoutingMac
  class Installer
    # required: sudo
    def install
      if ip_up_path.exist?
        backup_ip_up!
        ip_up_path.delete
      end

      FileUtils.ln_s(project_ip_up_path, ip_up_path)

      VpnRoutingMac::Config.etc_config_dir.unlink if VpnRoutingMac::Config.etc_config_dir.exist?
      FileUtils.ln_s(VpnRoutingMac::Config.home_config_dir, VpnRoutingMac::Config.etc_config_dir)
    end

    # required: sudo
    def uninstall
      if ip_up_path.exist?
        backup_ip_up!
        ip_up_path.delete
      end
    end

    def project_ip_up_path
      VpnRoutingMac::Application.project_root.join("config/ip-up")
    end

    def ip_up_dir_path
      Pathname.new("/etc/ppp")
    end

    def ip_up_path
      ip_up_dir_path.join("ip-up")
    end

    def backup_ip_up!
      backup_dir_path = ip_up_dir_path.join(Time.now.strftime("backup.%Y%m%d%H%M%S"))
      backup_dir_path.mkdir
      FileUtils.cp(ip_up_path, backup_dir_path)
    end
  end
end
