# 🖥️ Server Health Check

A lightweight Bash script for automated server monitoring with daily health reports.

## ✨ Features
- System resource monitoring (CPU, Memory, Disk)
- Service status tracking
- Network connectivity checks
- Security permission validation
- Automated daily execution via cron
- Complete logging system

## 🚀 Quick Installation
```bash
git clone https://github.com/Attrivishal/server-health-check.git
cd server-health-check
chmod +x install.sh checkup.sh
sudo ./install.sh
⚙️ Configuration
Edit config files in /etc/server-check/:

services.txt - Services to monitor (ssh, nginx, mysql, etc.)

thresholds.txt - Warning levels for memory, disk, errors

📅 Automation
Runs automatically at 10 PM daily via cron.
To change time: sudo crontab -e

📊 Usage
bash
# Run manually
sudo server-check

# View logs
cat ~/server-check-cron.log
ls ~/server-health-check/logs/
📝 Sample Output
text
✅ System: Ubuntu 22.04 (uptime: 15d)
✅ Memory: 4.2GB free | ✅ Disk: 65% free
✅ Services: 5/6 running | ✅ Network: Connected
📁 Log: ~/server-health-check/logs/health_20260117_220000.log
🔧 Requirements
Linux/WSL2

Bash 4.0+

Sudo privileges