#!/bin/bash
# File: checkup.sh
# Server Health Check Script - COMPLETELY FIXED VERSION

# ============================================
# PART 1: SETUP AND CONFIG
# ============================================

# Get the actual home directory (works with sudo too)
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi


# Create log directory
LOG_DIR="$USER_HOME/server-health-check/logs"
mkdir -p "$LOG_DIR"

# Log file with timestamp
LOG_FILE="$LOG_DIR/health_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Simple print functions
print_ok() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}➜ $1${NC}"
}

# ============================================
# PART 2: THE ACTUAL CHECKS
# ============================================

clear
echo "========================================"
echo "     SERVER HEALTH CHECK"
echo "========================================"
echo "Date: $(date)"
echo "Server: $(hostname)"
echo "Log file: $LOG_FILE"
echo "========================================"
echo ""

# Initialize log file (CREATE it first with >)
echo "========================================" > "$LOG_FILE"
echo "SERVER HEALTH CHECK - $(date)" >> "$LOG_FILE"
echo "Server: $(hostname)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# -------------------------------------------------
# CHECK 1: SYSTEM INFO
# -------------------------------------------------
echo "=== SYSTEM INFORMATION ==="
print_info "Hostname: $(hostname)"
print_info "Uptime: $(uptime -p)"
print_info "Kernel: $(uname -r)"
echo "=== SYSTEM INFORMATION ===" >> "$LOG_FILE"
echo "Hostname: $(hostname)" >> "$LOG_FILE"
echo "Uptime: $(uptime -p)" >> "$LOG_FILE"
echo "Kernel: $(uname -r)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# -------------------------------------------------
# CHECK 2: CPU & MEMORY
# -------------------------------------------------
echo "=== CPU & MEMORY ==="
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}')
print_info "CPU Load: $CPU_LOAD"
echo "=== CPU & MEMORY ===" >> "$LOG_FILE"
echo "CPU Load: $CPU_LOAD" >> "$LOG_FILE"

MEM_FREE=$(free -m | awk '/Mem:/ {print $4}')
if [ "$MEM_FREE" -lt 100 ]; then
    print_warn "Low memory: ${MEM_FREE}MB free"
    echo "WARNING: Low memory - ${MEM_FREE}MB free" >> "$LOG_FILE"
else
    print_ok "Memory OK: ${MEM_FREE}MB free"
    echo "Memory OK: ${MEM_FREE}MB free" >> "$LOG_FILE"
fi
echo "" >> "$LOG_FILE"

# -------------------------------------------------
# CHECK 3: DISK SPACE
# -------------------------------------------------
echo "=== DISK SPACE ==="
echo "=== DISK SPACE ===" >> "$LOG_FILE"
df -h / | awk '
NR==2 {
    printf "➜ Disk: %s used (%s free)\n", $5, $4
    print "Disk: " $5 " used (" $4 " free)" >> "'"$LOG_FILE"'"
    if ($5+0 > 90) print "⚠️  Warning: Disk almost full!"
    else print "✓ Disk space OK"
}'
echo "" >> "$LOG_FILE"

# -------------------------------------------------
# CHECK 4: SERVICES
# -------------------------------------------------
echo "=== SERVICES ==="
echo "=== SERVICES ===" >> "$LOG_FILE"

# Read services from config file
if [ -f "config/services.txt" ]; then
    SERVICES=$(cat config/services.txt)
else
    # Default services
    SERVICES="ssh cron nginx mysql"
fi

for service in $SERVICES; do
    if systemctl is-active "$service" >/dev/null 2>&1; then
        print_ok "$service: Running"
        echo "$service: Running" >> "$LOG_FILE"
    else
        print_error "$service: Stopped"
        echo "$service: Stopped" >> "$LOG_FILE"
    fi
done
echo "" >> "$LOG_FILE"

# -------------------------------------------------
# CHECK 5: NETWORK
# -------------------------------------------------
echo "=== NETWORK ==="
echo "=== NETWORK ===" >> "$LOG_FILE"

# Check internet
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    print_ok "Internet: Connected"
    echo "Internet: Connected" >> "$LOG_FILE"
else
    print_error "Internet: Disconnected"
    echo "Internet: Disconnected" >> "$LOG_FILE"
fi

# Check critical ports
print_info "Checking important ports:"
echo "Port Status:" >> "$LOG_FILE"

if ss -tulpn | grep -q ":22 "; then
    print_ok "SSH (22): Listening"
    echo "  SSH (22): Listening" >> "$LOG_FILE"
else
    print_error "SSH (22): Not listening"
    echo "  SSH (22): Not listening" >> "$LOG_FILE"
fi

if ss -tulpn | grep -q ":80 "; then
    print_ok "HTTP (80): Listening"
    echo "  HTTP (80): Listening" >> "$LOG_FILE"
else
    print_warn "HTTP (80): Not listening (normal if no web server)"
    echo "  HTTP (80): Not listening" >> "$LOG_FILE"
fi
echo "" >> "$LOG_FILE"

# -------------------------------------------------
# CHECK 6: SECURITY
# -------------------------------------------------
echo "=== SECURITY ==="
echo "=== SECURITY ===" >> "$LOG_FILE"

# Check for 777 permissions in home
BAD_FILES=$(find ~ -type f -perm 0777 2>/dev/null | head -3)
if [ -n "$BAD_FILES" ]; then
    print_warn "Found files with 777 permissions (dangerous!)"
    echo "$BAD_FILES"
    echo "WARNING: Found files with 777 permissions:" >> "$LOG_FILE"
    echo "$BAD_FILES" >> "$LOG_FILE"
else
    print_ok "No dangerously permissioned files found"
    echo "No dangerously permissioned files found" >> "$LOG_FILE"
fi
echo "" >> "$LOG_FILE"

# -------------------------------------------------
# CHECK 7: LOGS
# -------------------------------------------------
echo "=== LOGS ==="
echo "=== LOGS ===" >> "$LOG_FILE"

# Check recent errors
ERROR_COUNT=$(journalctl --since "1 hour ago" 2>/dev/null | grep -i "error\|fail" | wc -l)
if [ "$ERROR_COUNT" -gt 0 ]; then
    print_warn "Found $ERROR_COUNT errors in last hour"
    journalctl --since "1 hour ago" 2>/dev/null | grep -i "error\|fail" | tail -3
    echo "Found $ERROR_COUNT errors in last hour" >> "$LOG_FILE"
else
    print_ok "No recent errors in logs"
    echo "No recent errors in logs" >> "$LOG_FILE"
fi
echo "" >> "$LOG_FILE"

# ============================================
# PART 3: SUMMARY
# ============================================

echo "========================================"
echo "     CHECK COMPLETE - SUMMARY"
echo "========================================"
echo "" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "CHECK COMPLETE - SUMMARY" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Count services
SERVICE_COUNT=$(echo $SERVICES | wc -w)
RUNNING_COUNT=0
for service in $SERVICES; do
    if systemctl is-active "$service" >/dev/null 2>&1; then
        RUNNING_COUNT=$((RUNNING_COUNT + 1))
    fi
done

# Summary
echo ""
echo "Summary:"
print_info "Server: $(hostname)"
print_info "Uptime: $(uptime -p)"
print_info "Memory: ${MEM_FREE}MB free"
print_info "Services: $RUNNING_COUNT/$SERVICE_COUNT running"
print_info "Recent errors: $ERROR_COUNT"
print_info "Check completed at: $(date '+%H:%M:%S')"

echo "Summary:" >> "$LOG_FILE"
echo "  Server: $(hostname)" >> "$LOG_FILE"
echo "  Uptime: $(uptime -p)" >> "$LOG_FILE"
echo "  Memory free: ${MEM_FREE}MB" >> "$LOG_FILE"
echo "  Services running: $RUNNING_COUNT/$SERVICE_COUNT" >> "$LOG_FILE"
echo "  Errors in last hour: $ERROR_COUNT" >> "$LOG_FILE"
echo "  Check completed: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

print_info "Full report saved to: $LOG_FILE"
print_info "View log: cat $LOG_FILE"
print_info "Recent logs: ls -la $LOG_DIR/health_*.log"

echo ""
echo "========================================"
