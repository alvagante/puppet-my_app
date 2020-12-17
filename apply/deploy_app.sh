#!/usr/bin/env bash
APP=$1
NODES=$2
PARAMS_FILE=$(mktemp)
DESTINATION_DIR='/tmp/papply'
PUPPET_SOURCE='puppet://puppet/zam/rms'
TASK='profile::puppet_apply'
PUPPET_ENVIRONMENT='host'
MY_PATH="`dirname \"$0\"`"
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
PARAMS="@${PARAMS_FILE}"
cat <<EOF > $PARAMS_FILE
{
  "manifest": "$DESTINATION_DIR/$APP/apply/apply.pp",
  "destination": "$DESTINATION_DIR/$APP",
  "modulepath": "$DESTINATION_DIR",
  "puppet_source": "$PUPPET_SOURCE/$APP" 
}
EOF
echo "puppet task run $TASK --nodes $NODES --environment $PUPPET_ENVIRONMENT -p $PARAMS"

puppet task run $TASK --nodes $NODES --environment $PUPPET_ENVIRONMENT -p $PARAMS
rm $PARAMS_FILE