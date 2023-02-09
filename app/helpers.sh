#!/bin/bash

set -e

_get_node_address() {
  celestia-appd keys list --output json | jq .[] | jq .address
}

_query_delegation() {
  celestia-appd query staking delegation $2 $3 --output json | jq .balance | jq .amount | sed 's/\"//g'
}

_get_wallet_balance() {
  celestia-appd query bank balances $WALLET_ADDRESS
}
_validator_connect() {
celestia-appd tx staking create-validator \
    --amount=1000000utia \
    --pubkey=$(celestia-appd tendermint show-validator) \
    --moniker=$MONIKER \
    --chain-id=mocha \
    --commission-rate=0.1 \
    --gas="auto" \
    --gas-adjustment=1.5 \
    --fees="10000utia" \
    --commission-max-rate=0.2 \
    --commission-max-change-rate=0.01 \
    --min-self-delegation=1000000 \
    --from=$VALIDATOR_WALLET_NAME \
    --evm-address=$EVM_ADDRESS \
    --orchestrator-address=$ORCHESTRATOR_ADDRESS \
    --keyring-backend=test
}
_delegate_to_validator() {
  # first argument is celestiavaloper address of validator and second is the amount e.g 1000000utia
celestia-appd tx staking delegate \
    $2 $3 \
    --chain-id=mocha \
    --gas="auto" \
    --gas-adjustment=1.5 \
    --fees="18000utia" \
    --from=$VALIDATOR_WALLET_NAME \
    --keyring-backend=test
}

_transfer() {
  celestia-appd tx bank send \
    $2 $3 $4 \
    --chain-id=mocha \
    --gas="auto" \
    --gas-adjustment=1.5 \
    --fees="18000utia" \
    --from=$VALIDATOR_WALLET_NAME \
    --keyring-backend=test
}

_redelegate() {
  echo redelegate $2 $3 $4
  celestia-appd tx staking redelegate \
    $2 $3 $4 \
    --chain-id=mocha \
    --gas="auto" \
    --gas-adjustment=1.5 \
    --fees="18000utia" \
    --from=$VALIDATOR_WALLET_NAME \
    --keyring-backend=test 
}

if [ "$1" = 'wallet:balance' ]; then
  _get_wallet_balance
elif [ "$1" = 'wallet:address' ]; then
  _get_node_address  
elif [ "$1" = 'validator:connect' ]; then
  _validator_connect
elif [ "$1" = 'validator:delegate' ]; then
  _delegate_to_validator "$@"
elif [ "$1" = 'validator:sync-info' ]; then
  curl -s localhost:26657/status | jq .result | jq .sync_info
elif [ "$1" = 'validator:query_delegation' ]; then
   _query_delegation "$@"
elif [ "$1" = 'wallet:transfer' ]; then
   _transfer "$@"
elif [ "$1" = 'validator:redelegate' ]; then
   _redelegate "$@"       
else
  /bin/celestia-appd "$@"
fi
