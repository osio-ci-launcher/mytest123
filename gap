#!/usr/bin/env bash

APP_NAME=mytest
SERVICE_NAME=mytest-service
JAR_NAME=booster-1.0.0-SNAPSHOT.jar

SCRIPT_DIR=$(cd "$(dirname "$BASH_SOURCE")" ; pwd -P)

case "$1" in
    "deploy")
        PARAMS=""
        REPO_URL=$(git config --get remote.origin.url || echo "")
        if [[ ! -z "${REPO_URL}" ]]; then
            PARAMS="$PARAMS -p=SOURCE_REPOSITORY_URL=${REPO_URL}"
        fi
        CONSOLE_URL=$(oc status | head -n 1  | grep -Eo 'https?:.*')
        if [[ ! -z "${CONSOLE_URL}" ]]; then
            PARAMS="$PARAMS -p=OPENSHIFT_CONSOLE_URL=${CONSOLE_URL}"
        fi
        oc process -f ${SCRIPT_DIR}/.openshiftio/application.yaml --ignore-unknown-parameters ${PARAMS} | oc apply -f -
        if [[ -f ${SCRIPT_DIR}/.openshiftio/service.welcome.yaml ]]; then
             oc process -f ${SCRIPT_DIR}/.openshiftio/service.welcome.yaml --ignore-unknown-parameters ${PARAMS} | oc apply -f -
        fi
        ;;
    "push")
        shift
        FROM=${SCRIPT_DIR}/target/${JAR_NAME}
        if [[ "$1" == "--binary" || "$1" == "-b" ]]; then
            shift
            oc start-build ${SERVICE_NAME} --from-file ${FROM} "$@"
        elif [[ "$1" == "--source" || "$1" == "-s" ]]; then
            shift
            oc start-build ${SERVICE_NAME} --from-dir ${SCRIPT_DIR} "$@"
        elif [[ "$1" == "--git" || "$1" == "-g" ]]; then
            shift
            oc start-build ${SERVICE_NAME} "$@"
        else
            if [[ -f ${FROM} ]]; then
                oc start-build ${SERVICE_NAME} --from-file ${FROM} "$@"
            else
                oc start-build ${SERVICE_NAME} --from-dir ${SCRIPT_DIR} "$@"
            fi
        fi
        ;;
    "delete")
        oc delete all,secrets -l app=${APP_NAME}
        ;;
    *)
        echo "Usage: gap [deploy|push|delete] ..."
        echo "   deploy  - Deploys the application to OpenShift"
        echo "   push    - Pushes code to the application. By default this will push the pe-compiled"
        echo "             binary if it exists, otherwise it will push the local sources to be compiled"
        echo "             on OpenShift. This can be overridden by using one of the following flags:"
        echo "      -b, --binary - Pushes a pre-compiled binary"
        echo "      -s, --source - Pushes the sources"
        echo "      -g, --git    - Reverts to using the sources from Git"
        echo "   delete - Deletes the application from OpenShift"
    ;;
esac
