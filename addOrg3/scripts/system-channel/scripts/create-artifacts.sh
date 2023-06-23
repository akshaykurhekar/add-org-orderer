
rm org1-org3-channel.tx
rm -rf ../../channel-artifacts/org1-org3-channel.block

# channel name defaults to "mychannel"
CHANNEL_NAME="org1-org3-channel"

echo $CHANNEL_NAME

# Generate channel configuration block
configtxgen -profile org1-org3-channel -configPath . -outputCreateChannelTx ./org1-org3-channel.tx -channelID $CHANNEL_NAME

echo "#######    Generating anchor peer update for Org1MSP  ##########"
configtxgen -profile org1-org3-channel -configPath . -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP


echo "#######    Generating anchor peer update for Org3MSP  ##########"
configtxgen -profile org1-org3-channel -configPath . -outputAnchorPeersUpdate ./Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP
