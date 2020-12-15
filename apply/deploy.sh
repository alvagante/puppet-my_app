#!/usr/bin/env bash
NODES=$1
TASK='profile::puppet_apply'
PUPPET_ENVIRONMENT=host
MY_PATH="`dirname \"$0\"`"
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
PARAMS="@${MY_PATH}/task_params.json"
puppet task run $TASK --nodes $NODES --environment $PUPPET_ENVIRONMENT -p $PARAMS