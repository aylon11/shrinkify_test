# Copyright 2023 Google LLC.
#
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
# limitations under the License.

service_account="serviceAccount:${project_number}-compute@developer.gserviceaccount.com"
cf_name="shrinkify-cloud-agent"

echo "Setting Project ID: ${GOOGLE_CLOUD_PROJECT}"
gcloud config set project ${GOOGLE_CLOUD_PROJECT}

echo "Enabling container deployment..."
gcloud auth configure-docker

echo "Enabling APIs..."
gcloud services enable artifactregistry.googleapis.com cloudbuild.googleapis.com cloudfunctions.googleapis.com aiplatform.googleapis.com pubsub.googleapis.com eventarc.googleapis.com bigquery.googleapis.com compute.googleapis.com


echo "Setting service account permissions"
gcloud run services add-iam-policy-binding $cf_name \
  --member=$service_account \
  --role='roles/run.invoker' \
  --region=${GOOGLE_CLOUD_REGION}

echo "Creating cloud function..."
gcloud functions deploy $cf_name \
--gen2 \
--region=us-central1 \
--runtime=python39 \
--source=./cloud_function/ \
--entry-point=cloud_agent \
--trigger-location=us-central1 \
--trigger-event-filters="type=google.cloud.audit.log.v1.written" \
--trigger-event-filters="serviceName=bigquery.googleapis.com" \
--trigger-event-filters="methodName=google.cloud.bigquery.v2.JobService.InsertJob" \
--trigger-event-filters-path-pattern="resourceName=/projects/${GOOGLE_CLOUD_PROJECT}/datasets/shrinkify_output/tables/results_*" \
--timeout=520s 
