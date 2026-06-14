#!/bin/bash

echo "=== User Audit Report ===" 
echo "Date: $(date)"
echo ""
echo "--- Active users ---"
cut -d: -f1,3,6 /etc/passwd | awk -F: '$2 >= 1000'
echo ""
echo "--- Groups ---"
cat /etc/group | grep -E "it-staff|finance-staff"
echo ""
echo "--- Last logins ---"
last | head -20