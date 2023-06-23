export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../../../artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export FABRIC_CFG_PATH=${PWD}/../../../artifacts/channel/config/

export TLS_FILE=${PWD}/../../../artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.crt

export SYSTEM_CHANNEL_NAME=sys-channel

setGlobalsForOrderer() {
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../../../artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../../../artifacts/channel/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp

}

getLatestConfigBlock() {
    rm -rf genesis.block
    setGlobalsForOrderer
    peer channel fetch config genesis.block -o localhost:7050 -c $SYSTEM_CHANNEL_NAME --tls --cafile $ORDERER_CA
}
# getLatestConfigBlock

runOrderere4Container(){
    source .env
    docker-compose -f ../../docker-compose.yaml up -d
}

runOrderere4Container
