#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# 安装 perf 和 FlameGraph 工具，开启性能监控
for ip in ${iplist[@]};
do
  ssh -i ${key} -n -o BatchMode=yes -o StrictHostKeyChecking=no gabbai@${ip} "
    sudo apt-get update;
    sudo apt-get install -y linux-tools-common linux-tools-generic;
    git clone https://github.com/brendangregg/FlameGraph.git;
    sudo perf record -F 99 -a -g -o /users/gabbai/perf.data -- sleep 120" &
done

./script/deploy.sh $1

. ./script/load_config.sh $1

server_name=`echo "$server" | awk -F':' '{print $NF}'`
server_bin=${server_name}

bazel run //benchmark/protocols/pbft:kv_service_tools -- $PWD/config_out/client.config 

sleep 60

echo "benchmark done"


# 收集火焰图数据
for ip in ${iplist[@]};
do
  ssh -i ${key} -n -o BatchMode=yes -o StrictHostKeyChecking=no gabbai@${ip} "
    sudo perf script -i /home/gabbai/perf.data > /home/gabbai/out.perf;
    ./FlameGraph/stackcollapse-perf.pl /home/gabbai/out.perf > /home/gabbai/out.folded;
    ./FlameGraph/flamegraph.pl /home/gabbai/out.folded > /home/gabbai/flamegraph_${ip}.svg" &
done

wait  # 等待火焰图生成完成

echo "Fetching flamegraph data from each node"
for ip in ${iplist[@]};
do
  scp -i ${key} gabbai@${ip}:/home/flamegraph_${ip}.svg ./
done


count=1
for ip in ${iplist[@]};
do
`ssh -i ${key} -n -o BatchMode=yes -o StrictHostKeyChecking=no gabbai@${ip} "killall -9 ${server_bin}"` 
((count++))
done

while [ $count -gt 0 ]; do
        wait $pids
        count=`expr $count - 1`
done

echo "getting results"
for ip in ${iplist[@]};
do
  echo "scp -i ${key} gabbai@${ip}:/home/${server_bin}.log ./${ip}_log"
  `scp -i ${key} gabbai@${ip}:/home/${server_bin}.log result_${ip}_log` 
done

python3 performance/calculate_result.py `ls result_*_log` > results.log

rm -rf result_*_log
echo "save result to results.log"
cat results.log
