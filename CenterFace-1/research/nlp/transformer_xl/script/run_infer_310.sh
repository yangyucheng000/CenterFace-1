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

if [[ $# -lt 2 || $# -gt 4 ]]; then
    echo "Usage: bash run_infer_310.sh [MINDIR_PATH] [NEED_PREPROCESS] [DEVICE_ID] [CONFIG_PATH]
    NEED_PREPROCESS means weather need preprocess or not, it's value is 'y' or 'n'.
    DEVICE_ID is optional, it can be set by environment variable device_id, otherwise the value is zero
    CONFIG_PATH is optional, default value is '../default_config_large.yaml'"
exit 1
fi

get_real_path(){
    if [ "${1:0:1}" == "/" ]; then
        echo "$1"
    else
        echo "$(realpath -m $PWD/$1)"
    fi
}
model=$(get_real_path $1)

if [ "$2" == "y" ] || [ "$2" == "n" ];then
    need_preprocess=$2
else
  echo "weather need preprocess or not, it's value must be in [y, n]"
  exit 1
fi

device_id=0
if [ $# -ge 3 ]; then
    device_id=$3
fi

device_model="gpu"
if [[ "$1" =~ $device_model ]]; then
  device_model="gpu"
else
  device_model="ascend"
fi
echo $device_model

BASE_PATH=$(cd ./"`dirname $0`" || exit; pwd)
CONFIG_PATH="${BASE_PATH}/../default_config_large.yaml"
if [ $# -eq 4 ]
then
    CONFIG_PATH=$(get_real_path $4)
    if [ ! -f $CONFIG_PATH ]
    then
        echo "error: CONFIG_PATH=$CONFIG_PATH is not a file"
    exit 1
    fi
fi
echo $CONFIG_PATH

echo "mindir name: "$model
echo "need preprocess: "$need_preprocess
echo "device id: "$device_id

function preprocess_data()
{
    if [ -d preprocess_Result ]; then
        rm -rf ./preprocess_Result
    fi
    mkdir preprocess_Result
    export CONFIG_PATH=${CONFIG_PATH}
    python ../preprocess.py --result_path=./preprocess_Result/
}

function compile_app()
{
    cd ../ascend310_infer || exit
    bash build.sh &> build.log
}

function infer()
{
    cd - || exit
    if [ -d result_Files/$device_model ]; then
        rm -rf ./result_Files/$device_model
    fi
    if [ -d time_Result ]; then
        rm -rf ./time_Result
    fi
    mkdir result_Files
    cd result_Files
    mkdir $device_model
    cd ../
    mkdir time_Result

    ../ascend310_infer/out/main --mindir_path=$model --input0_path=./preprocess_Result/00_data --input1_path=./preprocess_Result/01_target --device_id=$device_id &> infer.log

}

function cal_acc()
{
    export CONFIG_PATH=${CONFIG_PATH}
    python ../postprocess.py --result_dir=./result_Files/$device_model &> acc.log
}

if [ $need_preprocess == "y" ]; then
    preprocess_data
    if [ $? -ne 0 ]; then
        echo "preprocess dataset failed"
        exit 1
    fi
fi
compile_app
if [ $? -ne 0 ]; then
    echo "compile app code failed"
    exit 1
fi
infer
if [ $? -ne 0 ]; then
    echo " execute inference failed"
    exit 1
fi
cal_acc
if [ $? -ne 0 ]; then
    echo "calculate accuracy failed"
    exit 1
fi