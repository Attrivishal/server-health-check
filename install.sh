#!/bin/bash
# File: install.sh
# Simple installer for Server Health Check

echo "========================================"
echo "   Server Health Check Installer"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Please run as root or use sudo"
    echo "   sudo ./install.sh"
    exit 1
fi

# Copy script to /usr/local/bin
echo "📦 Installing script..."
cp checkup.sh /usr/local/bin/server-check
chmod +x /usr/local/bin/server-check

# Create config directory
echo "📁 Setting up config directory..."
mkdir -p /etc/server-check

# Copy config files if they exist
if [ -d "config" ]; then
    cp config/* /etc/server-check/ 2>/dev/null || true
else
    # Create default config files
    echo "ssh" > /etc/server-check/services.txt
    echo "# Warning thresholds" > /etc/server-check/thresholds.txt
    echo "memory_warning=100" >> /etc/server-check/thresholds.txt
    echo "disk_warning=90" >> /etc/server-check/thresholds.txt
    echo "error_warning=5" >> /etc/server-check/thresholds.txt
fi

# Set default config directory in script
sed -i "s|CONFIG_DIR=\"config\"|CONFIG_DIR=\"/etc/server-check\"|" /usr/local/bin/server-check

# Create log directory
mkdir -p /var/log/server-check
chmod 755 /var/log/server-check

# Set up daily cron job at 5 PM
echo "⏰ Setting up daily cron job (5 PM)..."
CRON_JOB="0 17 * * * /usr/local/bin/server-check > /dev/null 2>&1"

# Remove existing cron jobs for server-check
crontab -l 2>/dev/null | grep -v "server-check" | crontab -

# Add new cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo ""
echo "✅ Installation complete!"
echo ""
echo "========================================"
echo "   INSTALLATION SUMMARY"
echo "========================================"
echo "✓ Script installed: /usr/local/bin/server-check"
echo "✓ Config directory: /etc/server-check"
echo "✓ Log directory: /var/log/server-check"
echo "✓ Cron job: Daily at 5:00 PM"
echo ""
echo "Usage:"
echo "  Run manually: sudo server-check"
echo "  View config: ls /etc/server-check/"
echo "  View logs: ls /var/log/server-check/"
echo ""
echo "To edit services to monitor:"
echo "  sudo nano /etc/server-check/services.txt"
echo ""
echo "Cron job will run automatically at 5 PM daily."
echo "========================================"