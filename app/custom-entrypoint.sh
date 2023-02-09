#!/bin/bash

set -e

_init_p2p() {
  cd $HOME
  rm -rf networks
  rm -f $HOME/.celestia-app/config/genesis.json
  git clone https://github.com/celestiaorg/networks.git
  while true; do
    # in case you want recover priv_validator_key.json through mnemonics
    read -p "Do you want to import a previously created node mnemonics? " yn
    case $yn in
    [Yy]*)
      celestia-appd init "$CELESTIA_NODE_NAME" --chain-id mocha --recover
      break
      ;;
    [Nn]*)
      celestia-appd init "$CELESTIA_NODE_NAME" --chain-id mocha
      break
      ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  cp $HOME/networks/mocha/genesis.json $HOME/.celestia-app/config
}
_set_configs() {
  if [ -z "${PEERS}" ]; then
    # TODO : check the correctness of this with team
    PEERS=$(curl -s https://rpc-mocha.pops.one/net_info | jq -r '.result.peers[] | select(.remote_ip | test("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$")) | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr | split(":")[-1])"' | tr '\n' ',' | sed 's/,$//')
  fi
  sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml
  sed -i -e "s/^seed_mode *=.*/seed_mode = \"$SEED_MODE\"/" $HOME/.celestia-app/config/config.toml
  # Make the node accessible outside of container
  sed -i.bak -e "s/^laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/" $HOME/.celestia-app/config/config.toml
}

_config_pruning() {
  PRUNING="custom"
  PRUNING_KEEP_RECENT="100"
  PRUNING_INTERVAL="10"

  sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" $HOME/.celestia-app/config/app.toml
  sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \
    \"$PRUNING_KEEP_RECENT\"/" $HOME/.celestia-app/config/app.toml
  sed -i -e "s/^pruning-interval *=.*/pruning-interval = \
    \"$PRUNING_INTERVAL\"/" $HOME/.celestia-app/config/app.toml
}
_download_snapshot() {
  cd $HOME
  rm -rf ~/.celestia-app/data
  mkdir -p ~/.celestia-app/data
  SNAP_NAME=$(curl -s https://snaps.qubelabs.io/celestia/ |
    egrep -o ">mocha.*tar" | tr -d ">")
  wget -O - https://snaps.qubelabs.io/celestia/${SNAP_NAME} | tar xf - \
    -C ~/.celestia-app/data/
}
_init_wallet() {
  celestia-appd config keyring-backend test
  while true; do
    read -p "Do you want to import a previously created wallet? " yn
    case $yn in
    [Yy]*)
      celestia-appd keys add $VALIDATOR_WALLET_NAME --recover
      break
      ;;
    [Nn]*)
      celestia-appd keys add $VALIDATOR_WALLET_NAME
      break
      ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  echo "celesvaloper address : "
  celestia-appd keys show $VALIDATOR_WALLET_NAME --bech val -a
}
_init() {
  _init_p2p
  _set_configs
  _config_pruning
  _init_wallet
  while true; do
    read -p "Did you made a backup from your mnemonic keys? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) echo "Please, store it in a safe place then type yes" ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  # while true; do
  #   read -p "Do you want to download the latest snapshot? " yn
  #   case $yn in
  #   [Yy]*)
  #     _download_snapshot
  #     break
  #     ;;
  #   [Nn]*) exit ;;
  #   *) echo "Please answer yes or no." ;;
  #   esac
  # done

}
if [ "$1" = 'debug' ]; then
  trap : TERM INT
  sleep infinity &
  wait
elif [ "$1" = 'init' ]; then
  _init
elif [ "$1" = 'start' ]; then
  #always update configs before start to apply changes in .env file
  _set_configs
  /bin/celestia-appd start
else
  /bin/celestia-appd "$@"
fi
