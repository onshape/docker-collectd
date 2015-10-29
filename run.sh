#!/bin/bash
set -xe

COLLECTD_CONF=/etc/collectd/collectd.conf
WRITE_HTTP_CONF=/etc/collectd/managed_config/10-write_http-plugin.conf
PLUGIN_CONF=/etc/collectd/managed_config/20-signalfx-plugin.conf

if [ ! -d "/mnt/proc" ]; then
	echo "Please run with '-v /proc:/mnt/proc:ro' when running this docker image"
	exit 1
fi
if [ -z "$SF_API_TOKEN" ]; then
	echo "Please set SF_API_TOKEN env to the API token to use"
	exit 1
fi
if [ -n "$COLLECTD_CONFIGS" ]; then
	echo "Include \"$COLLECTD_CONFIGS/*.conf\"" >> $COLLECTD_CONF
fi
HOSTNAME="FQDNLookup true"
if [ -n "$COLLECTD_HOSTNAME" ]; then
	HOSTNAME="Hostname \"$COLLECTD_HOSTNAME\""
fi
if [ -z "$COLLECTD_BUFFERSIZE" ]; then
	COLLECTD_BUFFERSIZE="16384"
fi
if [ -z "$SF_INGEST_HOST" ]; then
	SF_INGEST_HOST="https://ingest.signalfx.com"
fi
if [ -z "$COLLECTD_INTERVAL" ]; then
	COLLECTD_INTERVAL="10"
fi
AWS_UNIQUE_ID=$(curl -s --connect-timeout 1 http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.instanceId + "_" + .accountId + "_" + .region')

[ -n "$AWS_UNIQUE_ID" ] && AWS_VALUE="?sfxdim_AWSUniqueId=$AWS_UNIQUE_ID"
[ -z "$AWS_UNIQUE_ID" ] && AWS_VALUE="?sfxdim_$COLLECTD_SFXDIM"

sed -i -e "s#%%%INTERVAL%%%#$COLLECTD_INTERVAL#g" $COLLECTD_CONF
sed -i -e "s#%%%HOSTNAME%%%#$HOSTNAME#g" $COLLECTD_CONF

sed -i -e "s#%%%AWS_PATH%%%#$AWS_VALUE#g" $WRITE_HTTP_CONF
sed -i -e "s#%%%BUFFERSIZE%%%#$COLLECTD_BUFFERSIZE#g" $WRITE_HTTP_CONF
sed -i -e "s#%%%INGEST_HOST%%%#$SF_INGEST_HOST#g" $WRITE_HTTP_CONF
sed -i -e "s#%%%API_TOKEN%%%#$SF_API_TOKEN#g" $WRITE_HTTP_CONF

sed -i -e "s#%%%INGEST_HOST%%%#$SF_INGEST_HOST#g" $PLUGIN_CONF
sed -i -e "s#%%%API_TOKEN%%%#$SF_API_TOKEN#g" $PLUGIN_CONF
sed -i -e "s#%%%INTERVAL%%%#$COLLECTD_INTERVAL#g" $PLUGIN_CONF
sed -i -e "s#%%%AWS_PATH%%%#$AWS_VALUE#g" $PLUGIN_CONF

cat $COLLECTD_CONF
cat $PLUGIN_CONF
cat $WRITE_HTTP_CONF

if [ ! -d /mnt/oldproc ]; then
	umount /proc
	mount -o bind /mnt/proc /proc
	mkdir /mnt/oldproc
	mount -t proc none /mnt/oldproc
fi

if [ -z "$@" ]; then
  exec collectd -C $COLLECTD_CONF -f
else
  exec "$@"
fi
