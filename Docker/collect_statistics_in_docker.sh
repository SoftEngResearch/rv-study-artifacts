#!/bin/bash
#
# Collect statistics in Docker
# Before running this script, run `docker login` first.
# Usage: ./collect_statistics_in_docker.sh <projects-list> <output-dir> [timeout=86400] [branch]
#
PROJECTS_LIST=$1
OUTPUT_DIR=$2
TIMEOUT=$3
BRANCH=$4
SCRIPT_DIR=$( cd $( dirname $0 ) && pwd )

function check_input() {
  if [[ ! -f ${PROJECTS_LIST} || -z ${OUTPUT_DIR} ]]; then
    echo "Usage: collect_statistics_in_docker.sh <projects-list> <output-dir>"
    exit 1
  fi
  
  mkdir -p ${OUTPUT_DIR}
  
  if [[ ! -s ${PROJECTS_LIST} ]]; then
    echo "${PROJECTS_LIST} is empty..."
    exit 0
  fi
  
  if [[ -z $(grep "###" ${PROJECTS_LIST}) ]]; then
    echo "You must end your projects-list file with ###"
    exit 1
  fi
  
  if [[ -z ${TIMEOUT} ]]; then
    TIMEOUT=86400s
  fi
}

function run_project() {
  local project=$1
  local repo=$(echo ${project} | cut -d ',' -f 1)
  local sha=$(echo ${project} | cut -d ',' -f 2)
  local project_name=$(echo ${repo} | tr / -)
  
  echo "Running ${project}"
  mkdir -p ${OUTPUT_DIR}/${project_name}
  
  local id=$(docker run -itd --name ${project_name} rvpaper:latest)
  docker exec -w /home/tsm/tsm-rv ${id} git pull
  
  if [[ -n ${BRANCH} ]]; then
    docker exec -w /home/tsm/tsm-rv ${id} git checkout ${BRANCH}
  fi
  
  timeout ${TIMEOUT} docker exec -w /home/tsm/tsm-rv -e M2_HOME=/home/tsm/apache-maven -e MAVEN_HOME=/home/tsm/apache-maven -e CLASSPATH=/home/tsm/aspectj-1.9.7/lib/aspectjtools.jar:/home/tsm/aspectj-1.9.7/lib/aspectjrt.jar:/home/tsm/aspectj-1.9.7/lib/aspectjweaver.jar: -e PATH=/home/tsm/apache-maven/bin:/usr/lib/jvm/java-8-openjdk/bin:/home/tsm/aspectj-1.9.7/bin:/home/tsm/aspectj-1.9.7/lib/aspectjweaver.jar:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ${id} timeout ${TIMEOUT} bash experiments/project_statistics.sh ${repo} ${sha} /home/tsm/logs &> ${OUTPUT_DIR}/${project_name}/docker.log

  docker cp ${id}:/home/tsm/logs ${OUTPUT_DIR}/${project_name}
  docker cp ${id}:/home/tsm/tsm-rv/projects/ ${OUTPUT_DIR}/${project_name}
  
  docker rm -f ${id}
}

function run_all() {
  while true; do
    if [[ ! -s ${PROJECTS_LIST} ]]; then
      echo "${PROJECTS_LIST} is empty..."
      exit 0
    fi
    
    local project=$(head -n 1 ${PROJECTS_LIST})
    if [[ ${project} == "###" ]]; then
      echo "Finished running all projects"
      exit 0
    fi
    
    if [[ -z $(grep "###" ${PROJECTS_LIST}) ]]; then
      echo "You must end your projects-list file with ###"
      exit 1
    fi
    
    sed -i 1d ${PROJECTS_LIST}
    echo $project >> ${PROJECTS_LIST}
    run_project ${project}
  done
}

check_input
run_all
