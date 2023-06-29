
chmod -R 0755 ./crypto-config
# Delete existing artifacts
rm -rf ./crypto-config

#Generate Crypto artifactes for organizations
cryptogen generate --config=./org4-crypto.yaml --output=./crypto-config/
