# 定时切换 validator
  切换 validator 的思路：
  1. 创建不同的 Validtor Container，这些 Container 共享同一个数据库。由于数据库是独占的，所以同时只能运行一个Container
  2. Validator Container 需要手动 connect。目前 staking 模式要求 delegate 之后必要 21 天后，才能取出资金或者redelegate 其他 validator.
  3. 调用 validtor 之前需要将 validtor container 配置好，即完成命令： 
```
    docker compose exec validator-1 /opt/helpers.sh validator:connect

    命令中 validator-1是 docker-compose.yml，配置的 `services` field 中 validators 名称。 
    对应的images: celestia-docker-validator-1，
    container: celestia-docker-validator-1
```
  4. 将所有的 validator 写入脚本 switch_validator.sh 第三行，例如
```  
  validators=(validator-1 validator-2)
```
  5. 使用 condtab 命令 定时执行 switch_validator.sh, 参考 https://crontab.guru/every-5-minutes


# 如何执行交易/查询状态
1. 执行 `docker exec -it celestia-docker-validator-1-1  bash` 进入某个 container
2. celestia-appd tx --help, 会发现很多提供交易的 module
```
    bank                类似 substrate balances 模块，控制 utia 代币
    broadcast           Broadcast transactions generated offline
    crisis              Crisis transactions subcommands
    decode              Decode a binary encoded transaction string
    distribution        Distribution transactions subcommands
    encode              Encode transactions generated offline
    evidence            Evidence transaction subcommands
    feegrant            Feegrant transactions subcommands
    gov                 Governance transactions subcommands
    multi-sign          Generate multisig signatures for transactions generated offline
    payment             payment transactions subcommands
    sign                Sign a transaction generated offline
    sign-batch          Sign transaction batch files
    slashing            Slashing transaction subcommands
    staking             Staking transaction subcommands
    validate-signatures validate transactions signatures
    vesting             Vesting transaction subcommands
```
    继续执行 celestia-appd tx staking --help 会看到 staking 模块提供的方法
    celestia-appd tx staking delegate --help 会看到如何使用 staking::delegate 交易
那么完整的 delegate 交易命令如下（其他参数类似 --chain-id=mocha 是固定的）：
```
    celestia-appd tx staking delegate \
    celestiavaloper1l2rsakp388kuv9k8qzq6lrm9taddae7fpx59wm 1000utia \
    --chain-id=mocha \
    --gas="auto" \
    --gas-adjustment=1.5 \
    --fees="18000utia" \
    --from=$VALIDATOR_WALLET_NAME \
    --keyring-backend=test
```
   
