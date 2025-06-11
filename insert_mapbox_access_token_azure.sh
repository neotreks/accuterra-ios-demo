echo "Inserting Mapbox access token..."
  
echo "token: $1"
echo "TARGET_BUILD_DIR: $2"
echo "INFOPLIST_PATH: $3"
  
token=$1
TARGET_BUILD_DIR=$2
INFOPLIST_PATH=$3
  
if [ "$token" ]; then
  plutil -replace MGLMapboxAccessToken -string $token "$TARGET_BUILD_DIR/$INFOPLIST_PATH"
  echo "Token insertion successful"
else
  echo \'error: Missing Mapbox access token\'
  echo "error: Get an access token from <https://www.mapbox.com/studio/account/tokens/>, then create a new file at $token_file that contains the access token."
  exit 1
fi
