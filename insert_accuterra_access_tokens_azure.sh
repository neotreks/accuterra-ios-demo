echo "Inserting Accuterra access tokens..."

echo "AccuTerraClientToken: $1"
echo "AccuTerraMapToken: $2"
echo "AccuTerraServiceUrl: $3"
echo "TARGET_BUILD_DIR: $4"
echo "INFOPLIST_PATH: $5"


client=$1
map=$2
service_url=$3
TARGET_BUILD_DIR=$4
INFOPLIST_PATH=$5

if [ "$client" ]; then
  plutil -replace AccuTerraClientToken -string $client "$TARGET_BUILD_DIR/$INFOPLIST_PATH"
  echo "Client Token insertion successful: $client"
else
  echo \'error: Missing AccuTerra Client token\'
  echo "error: Get an API Keys from https://sdk.accuterra.com/latest/api-keys/, then create a new file at $TOKEN_FILE that contains the API Key values."
  exit 1
fi
if [ "$map" ]; then
  plutil -replace AccuTerraMapToken -string $map "$TARGET_BUILD_DIR/$INFOPLIST_PATH"
  echo "Map Token insertion successful: $map"
else
  echo \'error: Missing AccuTerra Map token\'
  echo "error: Get an API Keys from https://sdk.accuterra.com/latest/api-keys/, then create a new file at $TOKEN_FILE that contains the API Key values."
  exit 1
fi
if [ "$service_url" ]; then
  plutil -replace AccuTerraServiceUrl -string $service_url "$TARGET_BUILD_DIR/$INFOPLIST_PATH"
  echo "Service URL insertion successful: $service_url"
else
  echo \'error: Missing AccuTerra Service URL\'
  echo "error: Get an API Keys from https://sdk.accuterra.com/latest/api-keys/, then create a new file at $TOKEN_FILE that contains the API Key values."
  exit 1
fi
