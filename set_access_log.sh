#!/bin/bash
curl -X PUT -d '"/var/log/access.log"' --unix-socket /var/run/control.unit.sock http://localhost/config/access_log