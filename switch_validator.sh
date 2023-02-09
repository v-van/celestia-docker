#!/bin/bash

validators=(validator-1 validator-2)
validator_containers=()

i=0
for element in ${validators[@]}
do
    validator_containers[i]=celestia-docker-${element}-1
    let i=i+1
done

echo "this script will control ${validator_containers[@]}"

contaner_number=${#validator_containers[@]}

next_container_index=0
current_container_index=-1

for(( i=0;i<${#validator_containers[@]};i++)) 
do
    if [[ -n $(docker ps -q -f "name=^${validator_containers[i]}$") ]];then
        current_container_index=$i
        if (($i < $contaner_number -1)); then
            next_container_index=$(($i+1))
        elif (($i == $contaner_number -1)); then
            next_container_index=0
        fi
    fi
done


if [ $current_container_index == -1 ]; then
    echo "no validator alive, prepare start the first validator"
    docker compose start ${validators[0]}
else
    echo "stop ${validators[$current_container_index]}, start ${validators[next_container_index]}"
    docker compose stop ${validators[$current_container_index]}
    docker compose start ${validators[next_container_index]}          
fi

# echo $current_container_index
# validators_address=("celestia1fwtjful7pq5nwfwcx9dne2lr0j7ssnpphsd6ns" "celestia18r934uwtkculfx4yvrzwadtqzh0n7z3ytlme8n" )
# validators_operator=("celestiavaloper1fwtjful7pq5nwfwcx9dne2lr0j7ssnppj00r9k" "celestiavaloper18r934uwtkculfx4yvrzwadtqzh0n7z3ywqeq34")
# deno="utia"

# if [ $current_container_index != 0 ]; then
#     echo "start ${current_container_index}"
#     docker compose stop ${validators[$current_container_index]}
#     docker compose start ${validators[0]}
#     sleep 30    
# fi

# # echo $current_container_index
# # echo $next_container_index
# for(( i=0;i<${#validator_containers[@]};i++)) 
# do
#     delegate_amount=$(docker compose exec ${validators[0]} /opt/helpers.sh validator:query_delegation ${validators_address[0]} ${validators_operator[i]})
#     echo $i $delegate_amount ${validators_address[0]} ${validators_operator[$i]} ${validators_operator[$next_container_index]} $next_container_index
#     if [[ $delegate_amount > 0 ]] && [[ $i != $next_container_index ]];then
#         echo "exec redelegate"
#         delegate_amount=$[$delegate_amount - 100]
#         docker compose exec ${validators[0]} /opt/helpers.sh validator:redelegate ${validators_operator[$i]} ${validators_operator[$next_container_index]} $delegate_amount$deno

#     fi
# done 

# if [ $next_container_index != 0 ];then
#     docker compose stop ${validators[0]}
#     docker compose start ${validators[$next_container_index]}
# fi    
