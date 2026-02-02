#!/bin/bash

cd /tmp
cat > config.json <<EOL
{
  "agent" : {
    "metrics_collection_interval" : 60,
    "run_as_user" : "root",
    "logfile" : "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "metrics" : {
    "namespace" : "Project/Environement",
    "aggregation_dimensions" : [
      [
        "InstanceId"
      ]
    ],
    "append_dimensions" : {
      "ImageId" : "\${aws:ImageId}",
      "InstanceId" : "\${aws:InstanceId}",
      "InstanceType" : "\${aws:InstanceType}",
      "AutoScalingGroupName" : "\${aws:AutoScalingGroupName}"
    },
    "metrics_collected" : {
      "ethtool" : {
        "interface_include" : [
          "*"
        ],
        "metrics_include" : [
          "bw_in_allowance_exceeded",
          "bw_out_allowance_exceeded"
        ]
      },
      "disk" : {
        "measurement" : [
          "used_percent",
          "inodes_free",
          "inodes_used",
          "inodes_total"
        ],
        "resources" : [
          "*"
        ],
        "ignore_file_system_types" : [
          "sysfs",
          "devtmpfs",
          "tmpfs",
          "nfs",
          "nfs4"
        ],
        "metrics_collection_interval" : 300
      },
      "diskio" : {
        "measurement" : [
          "io_time"
        ],
        "resources" : [
          "*"
        ],
        "metrics_collection_interval" : 300
      },
      "mem" : {
        "measurement" : [
          "mem_used_percent"
        ],
        "metrics_collection_interval" : 60
      },
      "net" : {
        "measurement" : [
          "net_bytes_recv",
          "net_bytes_sent",
          "net_drop_in",
          "net_drop_out",
          "net_err_in",
          "net_err_out"
        ],
        "metrics_collection_interval" : 60
      },
      "swap" : {
        "measurement" : [
          "swap_used_percent"
        ],
        "metrics_collection_interval" : 60
      },
      "procstat" : [
        {
          "exe" : "/usr/sbin/sshd",
          "measurement" : [
            "pid_count"
          ]
        },
        {
          "exe" : "/usr/sbin/crond",
          "measurement" : [
            "pid_count"
          ]
        },
        {
          "exe" : "/opt/ds_agent/ds_agent",
          "measurement" : [
            "pid_count"
          ]
        },
        {
          "exe" : "/usr/sbin/rsyslogd",
          "measurement" : [
            "pid_count"
          ]
        },
        {
          "exe" : "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent",
          "measurement" : [
            "pid_count"
          ]
        },
        {
          "exe" : "/usr/bin/amazon-ssm-agent",
          "measurement" : [
            "pid_count"
          ]
        }
      ]
    }
  },
  "logs" : {
    "logs_collected" : {
      "files" : {
        "collect_list" : [
          {
            "file_path" : "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
            "log_group_name" : "Project/Environement/cloudwatch-agent.log",
            "log_stream_name" : "{instance_id}_{hostname}",
            "timezone" : "Local",
            "retention_in_days" : 30
          },
          {
            "file_path" : "/var/log/messages",
            "log_group_name" : "Project/Environement/System",
            "log_stream_name" : "{instance_id}_{hostname}",
            "timezone" : "Local",
            "retention_in_days" : 90
          },
          {
            "file_path" : "/var/log/syslog",
            "log_group_name" : "Project/Environement/System",
            "log_stream_name" : "{instance_id}_{hostname}",
            "timezone" : "Local",
            "retention_in_days" : 90
          },
          {
            "file_path" : "/var/log/secure",
            "log_group_name" : "Project/Environement/Logsecure",
            "log_stream_name" : "{instance_id}_{hostname}",
            "timezone" : "Local",
            "retention_in_days" : 90
          }
        ]
      }
    }
  }
}
EOL
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip -O AmazonCloudWatchAgent.zip
sudo unzip -o AmazonCloudWatchAgent.zip
sudo rm AmazonCloudWatchAgent.zip
sudo ./install.sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/tmp/config.json -s