#!/bin/bash

psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

if [ "$#" -ne 5 ]; then
  echo "Illegal number of params"
  exit 1
fi

hostname=$(hostname -f)
vmstat_mb=$(vmstat --unit M)

memory_free=$(echo "$vmstat_mb" | tail -1 | awk '{print $4}' | xargs)
cpu_idle=$(echo "$vmstat_mb" | tail -1 | awk '{print $15}' | xargs)
cpu_kernel=$(echo "$vmstat_mb" | tail -1 | awk '{print $14}' | xargs)
disk_io=$(vmstat -d | tail -1 | awk '{print $10}' | xargs)
disk_available=$(df -BM / | awk 'NR==2{print $4}' | tr -d 'M' | xargs)
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

host_id="(SELECT id FROM host_info WHERE hostname='$hostname')"
insert_fields="INSERT INTO host_usage(timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available)"
insert_values="VALUES('$timestamp', $host_id, $memory_free, $cpu_idle, $cpu_kernel, $disk_io, $disk_available);"
insert_stmt="$insert_fields$insert_values"

export PGPASSWORD=$psql_password
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?
