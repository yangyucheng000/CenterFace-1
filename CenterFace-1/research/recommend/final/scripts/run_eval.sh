#!/bin/bash
#    d
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================
echo "Please run the script as: "
echo "sh scripts/run_eval.sh DEVICE_ID DEVICE_TARGET DATASET_PATH CHECKPOINT_PATH"
echo "for example: sh scripts/run_eval.sh 0 GPU /dataset_path /checkpoint_path"
echo "After running the script, the network runs in the background, The log will be generated in ms_log/eval_output.log"

export DEVICE_ID=$1
DEVICE_TARGET=$2
DATA_URL=$3
CHECKPOINT_PATH=$4

mkdir -p ms_log
CUR_DIR=`pwd`
export GLOG_log_dir=${CUR_DIR}/ms_log
export GLOG_logtostderr=0

python -u eval.py \
    --dataset_path=$DATA_URL \
    --checkpoint_path=$CHECKPOINT_PATH \
    --device_target=$DEVICE_TARGET > ms_log/eval_output.log 2>&1 &
