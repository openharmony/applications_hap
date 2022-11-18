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


CUR_PATH=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
BASE_PATH=$(dirname ${CUR_PATH})


arg_project=""
arg_sdk_path=""
arg_help="0"
arg_url=""
arg_branch=""
arg_npm="@ohos:registry=https://mirrors.huaweicloud.com/repository/npm/"
arg_out_path=""
arg_sign_tool=""

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


is_project_root ${arg_project}
if [ $? -eq 1 ]; then
        echo "${arg_project} is not OpenHarmony Project"
        exit 1;
fi


echo "start build hap..."
cd ${arg_project}


module_list=()
module_name=()
out_module=()


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
				rr=$(cat ${cur_module}"/package.json" | grep "${m_n_1}")
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
	fi
	if [[ ${line} =~ "\"targets\":" ]]; then
                last_index=$((${#module_list[@]}-1))
                echo "hap输出module: "${module_list[${last_index}]}
                out_module[${#out_module[*]}]=${module_list[${last_index}]}
        fi
done < ${arg_project}"/build-profile.json5"


for module in ${module_list[@]}
do
	del_module_name ${module##${arg_project}}
	if [ $? -eq 0 ]; then
		for m_n in ${module_name[@]}
		do
			rr=$(cat ${module}"/package.json" | grep "${m_n}")
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
node ./node_modules/@ohos/hvigor/bin/hvigor.js --mode module clean assembleHap -p debuggable=false


for module in ${out_module[@]}
do
	cur_out_module_name=${module##*/}
	echo "module = ${module} , cur_out_module_name=${cur_out_module_name}"
	hap_name=${arg_project##*/}
	nosign_hap_path=${module}/build/default/outputs/default/${cur_out_module_name}-default-unsigned.hap
	sign_hap_path=${module}/build/default/outputs/default/${hap_name}.hap
	if [ ! -e ${nosign_hap_path} ]; then
                echo "assembleHap error !!!"
		rm -rf ${arg_project}/sign_helper
		exit 1
        fi
	cp -r ${arg_sign_tool} ${arg_project}/
	cd ${arg_project}/dist
	java -jar hap-sign-tool.jar  sign-profile -keyAlias "openharmony application profile release" -signAlg "SHA256withECDSA" -mode "localSign" -profileCertFile "OpenHarmonyProfileRelease.pem" -inFile "UnsgnedReleasedProfileTemplate.json" -keystoreFile "OpenHarmony.p12" -outFile "openharmony_sx.p7b" -keyPwd "123456" -keystorePwd "123456"
	java -jar hap-sign-tool.jar sign-app -keyAlias "openharmony application release" -signAlg "SHA256withECDSA" -mode "localSign" -appCertFile "OpenHarmonyApplication.pem" -profileFile "./openharmony_sx.p7b" -inFile "${nosign_hap_path}" -keystoreFile "OpenHarmony.p12" -outFile "${sign_hap_path}" -keyPwd "123456" -keystorePwd "123456"
	cp ${sign_hap_path} ${arg_out_path}/
done


exit 0
