export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../../../../artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/../../../../artifacts/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/../../../../artifacts/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/../../../crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/../../../../artifacts/channel/config/



setGlobalsForOrderer() {
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../../../../artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../../../../artifacts/channel/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp

}

setGlobalsForPeer0Org1() {
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../../../../artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1Org1() {
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../../../../artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
}

setGlobalsForPeer0Org3() {
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../../../crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051

}

export CHANNEL_NAME=org1-org3-channel
export SYSTEM_CHANNEL_NAME=sys-channel

createChannel(){
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0Org3
    
    peer channel create -o localhost:7050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ./${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

# createChannel


generateOrg3Definition() {
    export FABRIC_CFG_PATH=$PWD/
    configtxgen -printOrg Org3MSP >org3.json
}

# generateOrg3Definition

fetchChannelConfig() {
    setGlobalsForOrderer
    # setGlobalsForPeer0Org1

    # Fetch the config for the channel, writing it to config.json
    echo "Fetching the most recent configuration block for the channel"
    peer channel fetch config config_block.pb -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.example.com \
        -c $SYSTEM_CHANNEL_NAME --tls --cafile $ORDERER_CA

     echo "Decoding config block to JSON and isolating config to config.json"
    configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >config.json

    # Modify the configuration to append the new org
    jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups":{"SampleConsortium":{"groups": {"Org3MSP":.[1]}}}}}}}' config.json ./org3.json >modified_config.json
}

# fetchChannelConfig

createConfigUpdate() {

    CHANNEL="sys-channel"
    ORIGINAL="config.json"
    MODIFIED="modified_config.json"
    OUTPUT="org3_update_in_envelope.pb"

    configtxlator proto_encode --input "${ORIGINAL}" --type common.Config >original_config.pb

    configtxlator proto_encode --input "${MODIFIED}" --type common.Config >modified_config.pb

    configtxlator compute_update --channel_id $SYSTEM_CHANNEL_NAME --original original_config.pb --updated modified_config.pb >config_update.pb

    configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json

    echo "{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"sys-channel\", \"type\":2}},\"data\":{\"config_update\":"$(cat config_update.json)"}}}" | jq . >config_update_in_envelope.json
    configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"${OUTPUT}"

}

# createConfigUpdate

signConfigAsOrdererOrg() {

    setGlobalsForOrderer
    peer channel update -f org3_update_in_envelope.pb -c ${SYSTEM_CHANNEL_NAME} \
        -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
        --tls --cafile ${ORDERER_CA}

}

# signConfigAsOrdererOrg



createChannel(){
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0Org3
    
    peer channel create -o localhost:7050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ./${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

# createChannel

runOrg3Containers(){
    source .env
    docker-compose -f ../../../docker-compose.yaml up -d
}

# runOrg3Containers

joinChannel(){
    setGlobalsForPeer0Org1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    sleep 2
    setGlobalsForPeer1Org1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    sleep 2
    setGlobalsForPeer0Org3
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
}
# joinChannel

updateAnchorPeers(){
    setGlobalsForPeer0Org1
    peer channel update -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -c $CHANNEL_NAME -f ./Org1MSPanchors.tx \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
    setGlobalsForPeer0Org3
    peer channel update -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -c $CHANNEL_NAME -f ./Org3MSPanchors.tx \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
}

# updateAnchorPeers

# joinChannel



# fetchChannelConfig
# createConfigUpdate
# signConfigtxAsPeerOrg
# joinChannel