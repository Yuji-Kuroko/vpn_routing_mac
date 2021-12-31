# VpnRoutingMac

## License

MIT

## Requirement

macOS catalina or later

## Description

VpnRoutingMac is vpn routing tool for macOS.  
When using a VPN, we will connect via the VPN all packet.  
VpnRoutingMac can routing part of endpoint using /etc/ppp/ip-up.

VpnRoutingMacはmacOS向けのVPNルーティングツールです。  
通常、VPNを繋ぐとすべてのパケットがVPNを通過するようになります。  
VpnRoutingMacを使うと、/etc/ppp/ip-upの機能を利用して一部の通信のみVPNを通すことができます。  
必要な通信のみVPNを通し、Google MeetやZoomはVPNを介さないようにすることで、
快適なネット環境およびVPNへの負荷軽減を行うことができます。

## Installation

```bash
sudo /usr/bin/gem install bundler -v 2.3.3
sudo /usr/bin/gem install vpn_routing_mac
sudo vpn-routing install
```

## Uninstall

```bash
sudo vpn-routing uninstall
```

## Usage

### new VPN config

1. you connect VPN.
2. see `sudo cat ~/.vpn-routing/recent.log` in the IP address.
3. `sudo vpn-routing create-config --dir #{CONFIG_NAME} --gateway-ip=#{IP_ADDRESS}
   verbose option is show executed command.
### routing config

```
# If you have only one VPN config, you can omit the dir option.
# verbose option is show executed command.
 
# add routing ip with save the config.
sudo vpn-routing add-ip 192.168.1.1/32 --permanent --dir=#{CONFIG_NAME} --verbose

# delete routing ip. (without save the config)
sudo vpn-routing delete-ip 192.168.1.1/32 --dir=#{CONFIG_NAME} --verbose

# add routing domain with save the config.
sudo vpn-routing add-domain example.test --permanent --dir=#{CONFIG_NAME} --verbose

# delete routing ip. (without save the config)
sudo vpn-routing delete-domain example.test --dir=#{CONFIG_NAME} --verbose

# open config directory using Finder
vpn-routing edit

# reload config. (Isn't delete routing)
vpn-routing reload
```

### config directory

```
.vpn-routing/
├── config
│         └── CONFIG_DIR_NAME
│             ├── config.yml
│             ├── domains
│             │         └── cli.txt
│             └── ip_addresses
│                 └── cli.txt
└── recent.log
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Yuji-Kuroko/vpn_routing_mac.

