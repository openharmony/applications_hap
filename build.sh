#!/bin/bash

# Copyright (c) 2022 Huawei Device Co., Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#  limitations under the License.

set -e

CUR_PATH=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
BASE_PATH=$(dirname ${CUR_PATH})
ROOT_PATH=$(cd ${CUR_PATH}/../../.. && pwd) && cd -

arg_project=""
arg_sdk_path=""
arg_build_sdk="false"
arg_help="0"
arg_url=""
arg_branch=""
arg_npm=""
arg_out_path="${ROOT_PATH}/out/hap"
arg_sign_tool="${ROOT_PATH}/developtools/hapsigner/dist"
arg_p7b=""
arg_apl="normal"
arg_feature="hos_normal_app"
arg_profile="UnsgnedReleasedProfileTemplate.json"
arg_bundle_name=""

function print_help() {
  cat <<EOF
  use assembleHap [options] <mainclass> [args...]

EOF
}


function clear_dir(){
        if [ ! -d "$1" ]; then
                mkdir -p $1
        fi
}


function is_project_root(){
        if [[ -f $1"/build-profile.json5" && -f $1"/hvigorfile.js" ]]; then
                return 0
        else
                return 1
        fi
}

function build_sdk() {
        if [ -d ${ROOT_PATH}/out/sdk/packages/ohos-sdk/linux ]; then
                echo "ohos-sdk exists."
                return 0
        fi
        pushd ${ROOT_PATH}
        echo "building the latest ohos-sdk..."
        ./build.sh --product-name ohos-sdk
        pushd ${ROOT_PATH}/out/sdk/packages/ohos-sdk/linux
        ls -d */ | xargs rm -rf
        for i in $(ls); do
                unzip $i
        done
	for f in $(find . -name npm-install.js); do
                pushd $(dirname $f)
                node npm-install.js
                popd
        done
        api_version=$(grep apiVersion toolchains/oh-uni-package.json | awk '{print $2}' | sed -r 's/\",?//g')
        sdk_version=$(grep version toolchains/oh-uni-package.json | awk '{print $2}' | sed -r 's/\",?//g')
        for i in $(ls -d */); do
                mkdir -p $api_version
                mv $i $api_version
                mkdir $i
                ln -s ../$api_version/$i $i/$sdk_version
        done
        popd
        popd
}

function parse_arguments() {
	local helperKey="";
	local helperValue="";
	local current="";

 	while [ "$1" != "" ]; do
		current=$1;
      		helperKey=${current#*--};
      		helperKey=${helperKey%%=*};
      		helperKey=$(echo "$helperKey" | tr '-' '_');
      		helperValue=${current#*=};
      		if [ "$helperValue" == "$current" ]; then
        		helperValue="1";
      		fi
      		#echo "eval arg_$helperKey=\"$helperValue\"";

      		eval "arg_$helperKey=\"$helperValue\"";
      		shift
  	done
}


parse_arguments ${@};


if [ "$arg_help" != "0" ]; then
        print_help;
        exit 1;
fi


if [ "${arg_project}" == "" -a "${arg_url}" == "" ]; then
        echo "--project or --url is not null"
        exit 1;
fi


if [ ! -d "${arg_project}" ]; then
        echo "${arg_project} is not dir"
        exit 1;
fi


if [[ ${arg_project} = */ ]]; then
	arg_project=${arg_project%/}
fi


if [[ ${arg_sign_tool} = */ ]]; then
        arg_sign_tool=${arg_sign_tool%/}
fi

if [[ ${arg_p7b} = "" ]]; then
        arg_p7b=$(find ${arg_project} -name *.p7b | head -n 1)
        if [[ ${arg_p7b} = "" ]]; then
                arg_p7b=openharmony_sx.p7b
        fi
fi

clear_dir ${arg_out_path}
export OHOS_SDK_HOME=${arg_sdk_path}
echo "use sdk:"${OHOS_SDK_HOME}
npm config set ${arg_npm}
echo "npm config set ${arg_npm}"


if [ "${arg_url}" != "" ]; then
	if [ "${arg_branch}" == "" ]; then
		echo "branch is not null"
		exit 1
	fi
	project_name=${arg_url##*/}
	project_name=${project_name%%.git*}
        if test -d ${BASE_PATH}/projects/${project_name}
        then
                echo "${project_name} exists,ready for update..."
                cd ${BASE_PATH}/projects/${project_name}
                git fetch origin ${arg_branch}
                git reset --hard origin/${arg_branch}
                git pull
        else
                echo "${project_name} dose not exist,ready to download..."
                cd ${BASE_PATH}/projects
                git clone -b ${arg_branch} ${arg_url} ${project_name}
        fi
	arg_project=${BASE_PATH}/projects/${project_name}
fi


if ! is_project_root ${arg_project}; then
        echo "${arg_project} is not OpenHarmony Project"
        exit 1;
fi

if [ "${arg_build_sdk}" == "true" ]; then
        build_sdk
        export OHOS_SDK_HOME=${ROOT_PATH}/out/sdk/packages/ohos-sdk/linux
        echo "set OHOS_SDK_HOME to" ${OHOS_SDK_HOME}
fi

echo "start build hap..."
cd ${arg_project}


module_list=()
module_name=()
out_module=()
bundle_name=""


function del_module_name(){
        name=${1}
        for i in "${!module_name[@]}"
        do
                if [[ "${module_name[i]}" == "${name}" ]]; then
                        unset module_name[i]
			echo "移除"${name}" , 剩余 : "${module_name[@]}
			return 0
                fi
        done
        return 1
}


function load_dep(){
	cur_m_n=${1}
	for cur_module in ${module_list[@]}
	do
		if [[ "${cur_module}" =~ "${cur_m_n}" ]]; then
			del_module_name ${cur_m_n}
			for m_n_1 in ${module_name[@]}
			do
				rr=$(cat ${cur_module}"/package.json" | grep "${m_n_1}" || true)
				if [[ "${rr}" != "" ]]; then
					load_dep ${m_n_1}
				fi
			done
			cd ${cur_module}
			echo ${cur_module}" 执行npm install"
			npm i
		fi
	done
}


while read line
do
	if [[ ${line} =~ "srcPath" ]]; then
		pa=${line%\"*}
		pa=${pa##*\".}
		module_list[${#module_list[*]}]=${arg_project}${pa}
		module_name[${#module_name[*]}]=${pa}
		if [ -d "${arg_project}/AppScope" ]; then
			cur_bundle_line=`cat ${arg_project}/AppScope/app.json5 | grep "\"bundleName\""`
			bundle_name=${cur_bundle_line%\"*}
			bundle_name=${bundle_name##*\"}
			# echo "bundleName : "${bundle_name}
			is_entry=`cat ${arg_project}${pa}/src/main/module.json5 | sed 's/ //g' | grep "\"type\":\"entry\"" || true`
			is_feature=`cat ${arg_project}${pa}/src/main/module.json5 | sed 's/ //g' | grep "\"type\":\"feature\"" || true`
			if [[ "${is_entry}" != "" || "${is_feature}" != "" ]]; then
				echo "hap输出module: "${arg_project}${pa}
				out_module[${#out_module[*]}]=${arg_project}${pa}
			fi
		else
			cur_bundle_line=`cat ${arg_project}${pa}/src/main/config.json | grep "\"bundleName\""`
                        bundle_name=${cur_bundle_line%\"*}
                        bundle_name=${bundle_name##*\"}
                        # echo "bundleName : "${bundle_name}
			is_entry=`cat ${arg_project}${pa}/src/main/config.json | sed 's/ //g' | grep "\"moduleType\":\"entry\"" || true`
                        is_feature=`cat ${arg_project}${pa}/src/main/config.json | sed 's/ //g' | grep "\"moduleType\":\"feature\"" || true`
                        if [[ "${is_entry}" != "" || "${is_feature}" != "" ]]; then
                                echo "hap输出module: "${arg_project}${pa}
                                out_module[${#out_module[*]}]=${arg_project}${pa}
                        fi
		fi
	fi
done < ${arg_project}"/build-profile.json5"


for module in ${module_list[@]}
do
	if del_module_name ${module##${arg_project}}; then
		for m_n in ${module_name[@]}
		do
			rr=$(cat ${module}"/package.json" | grep "${m_n}" || true)
			if [[ "${rr}" != "" ]]; then
				load_dep ${m_n}
			fi
		done
		cd ${module}
		echo ${module}" 执行npm install"
		npm i
	fi	
done


cd ${arg_project}
echo ${arg_project}" 执行npm install"
npm install
node ./node_modules/@ohos/hvigor/bin/hvigor.js clean
node ./node_modules/@ohos/hvigor/bin/hvigor.js --mode module clean assembleHap -p debuggable=false


for module in ${out_module[@]}
do
	cur_out_module_name=${module##*/}
	is_sign=false
	echo "module = ${module} , cur_out_module_name=${cur_out_module_name}"
	if [ ! -d ${module}/build/default/outputs/default/ ]; then
		echo "module = ${module}, assembleHap error !!!"
		continue
	fi
	for out_file in `ls ${module}/build/default/outputs/default/`
	do
		if [[ "${out_file}" =~ "-signed.hap" ]]; then
			is_sign=true
			echo "发现signed包 : "${out_file}",直接归档"
			cp ${module}/build/default/outputs/default/${out_file} ${arg_out_path}/
			break
		fi
	done
	if test ${is_sign} = false
	then
		hap_name=${arg_project##*/}
		# echo "${hap_name},skip sign 'hap'. Invalid signingConfig is configured for 'default' product."
		for out_file in `ls ${module}/build/default/outputs/default/`
        	do
                	if [[ "${out_file}" =~ "-unsigned.hap" ]]; then
                        	echo "发现unsigned包 : "${out_file}",开始使用签名工具签名"
				nosign_hap_path=${module}/build/default/outputs/default/${out_file}
				sign_hap_path=${module}/build/default/outputs/default/${out_file/unsigned/signed}
				cp -r ${arg_sign_tool} ${arg_project}/
        			cd ${arg_project}/dist
				if [ ! -e ${arg_profile} ]; then
					echo "${arg_profile} not exist! ! !"
					exit 1
				fi
				if [ "${arg_bundle_name}" != "" ]; then
					sed -i "s/\"com.OpenHarmony.app.test\"/\"${arg_bundle_name}\"/g" ${arg_profile}
				else
					sed -i "s/\"com.OpenHarmony.app.test\"/\"${bundle_name}\"/g" ${arg_profile}
				fi
       		 		sed -i "s/\"normal\"/\"${arg_apl}\"/g" ${arg_profile}
        			sed -i "s/\"system_basic\"/\"${arg_apl}\"/g" ${arg_profile}
        			sed -i "s/\"system_core\"/\"${arg_apl}\"/g" ${arg_profile}
        			sed -i "s/\"hos_normal_app\"/\"${arg_feature}\"/g" ${arg_profile}
        			sed -i "s/\"hos_system_app\"/\"${arg_feature}\"/g" ${arg_profile}
        			java -jar hap-sign-tool.jar  sign-profile -keyAlias "openharmony application profile release" -signAlg "SHA256withECDSA" -mode "localSign" -profileCertFile "OpenHarmonyProfileRelease.pem" -inFile "${arg_profile}" -keystoreFile "OpenHarmony.p12" -outFile "openharmony_sx.p7b" -keyPwd "123456" -keystorePwd "123456"
        			java -jar hap-sign-tool.jar sign-app -keyAlias "openharmony application release" -signAlg "SHA256withECDSA" -mode "localSign" -appCertFile "OpenHarmonyApplication.pem" -profileFile "${arg_p7b}" -inFile "${nosign_hap_path}" -keystoreFile "OpenHarmony.p12" -outFile "${sign_hap_path}" -keyPwd "123456" -keystorePwd "123456"
        			cp ${sign_hap_path} ${arg_out_path}/
				is_sign=true
                        	break
                	fi
        	done
		if test ${is_sign} = false
		then
                	echo "${module} assembleHap error !!!"
                	rm -rf ${arg_project}/sign_helper
                	exit 1
        	fi
	fi
done
rm -rf ${arg_project}/sign_helper


exit 0
