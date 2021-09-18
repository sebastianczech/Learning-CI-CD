#!/bin/bash

echo -e "Show Python installed packages:\n"

python3 -m pip list --format=columns

echo -e "\nAudit Python packages:\n"

LC_ALL=en_US
export LC_ALL

ossaudit -i
