#!/bin/bash
COLOR='\033[0;36m' # Cyan
NC='\033[0m' # No Color
# Variables
PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
PROJECT_NAME=$(gcloud projects describe $PROJECT_ID --format="value(name)")
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID | grep projectNumber | sed "s/.* '//;s/'//g")
SERVICE_ACCOUNT=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
IMAGE_NAME="shrinkify"
TAG="latest" # e.g., "latest"

create_image() {
    echo -e "${COLOR}Creating Image...${NC}"
    docker build -t ${IMAGE_NAME} ../
    docker tag ${IMAGE_NAME} gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}
    docker push gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}
    echo "Image pushed to GCP Container Registry successfully."
}
run_tf() {
    echo -e "${COLOR}Creating Infra...${NC}"
    terraform apply -var "project_id=$PROJECT_ID" -var "project_number=$PROJECT_NUMBER" -auto-approve
    echo -e "${COLOR}Infra Created!${NC}"
}
deploy_all() {
    create_image
    run_tf
}
for i in "$@"; do
    "$i"
    exitcode=$?
    if [ $exitcode -ne 0 ]; then
        echo "Breaking script as command '$i' failed"
        exit $exitcode
    fi
done