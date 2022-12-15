# iptables

List the rules in a chain:
```bash
sudo iptables -L -n -v --line-number
```
> add `-n` flag for **numeric output of addresses and ports**


save rules:
```bash
sudo iptables-save > new-rules
```

restore rules:
```bash
sudo iptables-restore < rules
```

flush rules and remove chains:
```bash
sudo iptables -F
sudo iptables -F INPUT

# Delete user-defined chains
sudo iptables -X
```

flush and delete used defined chain for filted and nat tables:
```bash
sudo iptables -t filter -F
sudo iptables -t filter -X
sudo iptables -t nat -F
sudo iptables -t nat -X
```

change input policy to DROP:
```bash
sudo iptables --policy INPUT DROP
sudo iptables --policy FORWARD DROP
sudo iptables --policy OUTPUT ACCEPT
```

drop connection from specfic IP:
```bash
sudo iptables -I INPUT 1 -s 192.168.0.54 -j DROP

# Append rules
sudo iptables -A INPUT -s 192.168.0.54 -j DROP
```

accept everything on localhost:
```bash
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT
```

allow icmp trafic:
```bash
sudo iptables -I OUTPUT 1 --proto icmp -j ACCEPT
```

delete rule number 3 from chain INPUT:
```bash
sudo iptables -D INPUT 3
```

allow destination port 22:
```bash
sudo iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
```

all new connections on port 80:
```bash
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
```

allow input and output from range 192.168.1.0/24 on port 3306:
```bash
sudo iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 3306 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 3306 -m conntrack --ctstate ESTABLISHED -j ACCEPT
```

enable http ports:
```bash
sudo iptables -A OUTPUT -p tcp -m multiport --dport 80,443,8080 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
```

reject connection from port 22:
```bash
sudo iptables -A OUTPUT -p tcp --dport 25 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 25 -j DROP
```

drop invalid state:
```bash
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
```

log connection:
```bash
sudo iptables -A INPUT -i enp1s0 -s 10.0.0.0/8 -j LOG --log-prefix "IP SPOOF A:"
```

add logs 5 logs per minute:
```bash
sudo iptables -A INPUT -i enp1s0 -s 10.10.10.0/24 -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix "IP_SPOOF_A"
```

drop icmp connection:
```bash
sudo iptables -A INPUT -p icmp --icmp-type echo-reply -j DROP
```

add new chain:
```bash
sudo iptables -N port-scanning
```

limit connection:
```bash
sudo iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
```

drop if more than 10 new connections are there in last 60 seconds:
```bash
sudo iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
```
