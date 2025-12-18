# Service Debugging & Testing Commands

Quick reference for debugging NixOS services and testing configurations.

## System Status

```bash
# Check overall system status
systemctl status

# View system boot log
journalctl -b

# Check for failed services
systemctl --failed

# View system resource usage
htop
```

## Service Management

```bash
# Check service status
systemctl status <service-name>

# View service logs (live)
journalctl -u <service-name> -f

# View last 100 lines of logs
journalctl -u <service-name> -n 100

# Restart a service
sudo systemctl restart <service-name>

# Stop a service
sudo systemctl stop <service-name>

# View service configuration
systemctl cat <service-name>
```

## CockroachDB

```bash
# Check service status
systemctl status cockroachdb

# View logs
journalctl -u cockroachdb -f

# Connect to SQL shell
cockroach sql --insecure --host=localhost:26257

# Check node status
cockroach node status --insecure --host=localhost:26257

# Check cluster health
cockroach node status --insecure | grep -i live

# Create test database
cockroach sql --insecure --execute="CREATE DATABASE test;"

# Show databases
cockroach sql --insecure --execute="SHOW DATABASES;"

# Admin UI
http://localhost:8080
```

## PostgreSQL

```bash
# Check service status
systemctl status postgresql

# View logs
journalctl -u postgresql -f

# Connect as postgres user
sudo -u postgres psql

# List databases
sudo -u postgres psql -c "\l"

# List users
sudo -u postgres psql -c "\du"

# Connect to specific database
sudo -u postgres psql -d <database-name>
```

## Redis

```bash
# Check service status
systemctl status redis

# View logs
journalctl -u redis -f

# Connect to Redis CLI
redis-cli

# Ping test
redis-cli ping

# Check memory usage
redis-cli info memory

# Monitor commands in real-time
redis-cli monitor
```

## Prometheus

```bash
# Check service status
systemctl status prometheus

# View logs
journalctl -u prometheus -f

# Check targets
curl http://localhost:9090/api/v1/targets | jq

# Web UI
http://localhost:9090
```

## Grafana

```bash
# Check service status
systemctl status grafana

# View logs
journalctl -u grafana -f

# Web UI (default: admin/admin)
http://localhost:3000
```

## Nginx

```bash
# Check service status
systemctl status nginx

# View logs
journalctl -u nginx -f

# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# View access logs
sudo tail -f /var/log/nginx/access.log

# View error logs
sudo tail -f /var/log/nginx/error.log
```

## Docker

```bash
# Check service status
systemctl status docker

# List running containers
docker ps

# List all containers
docker ps -a

# View container logs
docker logs <container-name>

# Follow container logs
docker logs -f <container-name>

# Inspect container
docker inspect <container-name>

# Execute command in container
docker exec -it <container-name> bash
```

## Network Debugging

```bash
# Check open ports
sudo ss -tlnp

# Check specific port
sudo ss -tlnp | grep :26257

# Test connectivity to port
nc -zv localhost 26257

# Check firewall rules
sudo iptables -L -n -v

# Check NixOS firewall config
sudo iptables -L nixos-fw -n -v

# View network interfaces
ip addr

# Ping test
ping -c 4 192.168.50.32

# DNS lookup
dig example.com

# Trace route
traceroute example.com
```

## Disk & Storage

```bash
# Check disk usage
df -h

# Check directory sizes
du -sh /var/lib/*

# Check inode usage
df -i

# Find large files
sudo find /var -type f -size +100M -exec ls -lh {} \;
```

## NixOS Specific

```bash
# View current configuration
sudo nix-instantiate --eval '<nixpkgs/nixos>' -A config.system.build.toplevel

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to previous generation
sudo nixos-rebuild switch --rollback

# Test configuration without switching
sudo nixos-rebuild test --flake .#<machine-name>

# Build configuration
nix build .#nixosConfigurations.<machine-name>.config.system.build.toplevel

# Check flake
nix flake check

# Update flake inputs
nix flake update

# Show flake info
nix flake show

# Garbage collect
sudo nix-collect-garbage -d
```

## Process Management

```bash
# List all processes
ps aux

# Find process by name
ps aux | grep <process-name>

# Kill process by PID
kill <pid>

# Force kill process
kill -9 <pid>

# Find process using port
sudo lsof -i :26257

# View process tree
pstree -p
```

## Performance Monitoring

```bash
# Real-time system monitor
htop

# System resource summary
top

# Disk I/O
iostat -x 1

# Network statistics
netstat -i

# Memory usage
free -h

# CPU information
lscpu
```

## Remote Deployment

```bash
# Deploy to remote machine
nixos-rebuild switch --flake .#<machine-name> --target-host <hostname> --use-remote-sudo

# Test remote configuration
nixos-rebuild test --flake .#<machine-name> --target-host <hostname> --use-remote-sudo

# Build remotely
nixos-rebuild build --flake .#<machine-name> --target-host <hostname>
```

## Quick Health Check Script

```bash
#!/usr/bin/env bash
# Save as check-services.sh

echo "=== System Status ==="
systemctl status cockroachdb redis prometheus grafana nginx | grep "Active:"

echo -e "\n=== Port Status ==="
sudo ss -tlnp | grep -E ":(26257|6379|9090|3000|80|443)"

echo -e "\n=== Disk Usage ==="
df -h | grep -E "/$|/var"

echo -e "\n=== Memory ==="
free -h

echo -e "\n=== Failed Services ==="
systemctl --failed
```
