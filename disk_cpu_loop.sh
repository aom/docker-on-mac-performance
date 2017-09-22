#!/usr/bin/env sh

COUNT=$1
DOCKER_HOST_DESCRIPTION=$2
TEST_SETUP_DESCRIPTION=$3

if [ "$TEST_SETUP_DESCRIPTION" = "" ]; then
  echo "Usage:"
  echo "  disk_cpu_loop.sh <number of test runs> <describe host> <describe setup>"
  echo ""
  echo "Descriptions should not include dashes or empty spaces. Ie."
  echo "  disk_cpu_loop.sh 3 imac_5k_2017 7cores_ssd"
  echo "  disk_cpu_loop.sh 3 mbp_15_2015 7cores_ssd"
  echo "  disk_cpu_loop.sh 3 imac_5k_2017 7cores_ramdisk"
  exit
fi

Benchmark ()
{
  VM=$1

  eval $(docker-machine env $VM)

  i=0
  while [ $i -lt $COUNT ]; do
    TIMESTAMP=`date "+%Y%m%d%H%M%S"`
    LOG_FILE=logs/benchmark-$DOCKER_HOST_DESCRIPTION-$TEST_SETUP_DESCRIPTION-$VM-$i-$TIMESTAMP.log
    echo "------------------------------"
    echo $LOG_FILE
    echo "------------------------------"
    echo ""

    docker run -d  -p 80:80 -p 5001:5001 --name=simple-container-benchmarks-server-$i misterbisson/simple-container-benchmarks &&
    docker run -d -e "DOCKER_HOST=$DOCKER_HOST" -e "TARGET=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' simple-container-benchmarks-server-$i)" --name=simple-container-benchmarks-client-$i misterbisson/simple-container-benchmarks;
    docker logs -f $(docker ps -aqf "name=simple-container-benchmarks-client-$i") | tee $LOG_FILE

    docker stop $(docker ps -q)
    docker rm $(docker ps -a -q)

    i=$[$i+1]
    echo ""
    sleep 1
  done
}

Cleanup ()
{
  VM=$1

  docker-machine ls
  docker-machine rm $VM -y
}

CPU_COUNT_FOR_VMS=$((`sysctl -n hw.ncpu` - 1))
DISK_SIZE=20000
MEMORY=2048

echo "------------------------------"
echo "Benchamarking VMWare Fusion 8"
echo "------------------------------"
echo ""

VM=fusion

docker-machine create \
  --driver vmwarefusion \
  --vmwarefusion-cpu-count $CPU_COUNT_FOR_VMS \
  --vmwarefusion-disk-size $DISK_SIZE \
  --vmwarefusion-memory-size $MEMORY \
  $VM

Benchmark $VM
Cleanup $VM

echo "------------------------------"
echo "Benchamarking VirtualBox 5"
echo "------------------------------"
echo ""

VM=virtualbox

docker-machine create \
  --driver virtualbox \
  --virtualbox-cpu-count $CPU_COUNT_FOR_VMS \
  --virtualbox-disk-size $DISK_SIZE \
  --virtualbox-memory $MEMORY \
  $VM

Benchmark $VM
Cleanup $VM

echo "------------------------------"
echo "Benchamarking xhyve"
echo "------------------------------"
echo ""

VM=xhyve

docker-machine create \
  --driver xhyve \
  --xhyve-cpu-count $CPU_COUNT_FOR_VMS \
  --xhyve-disk-size $DISK_SIZE \
  --xhyve-memory-size $MEMORY \
  --xhyve-experimental-nfs-share \
  $VM

Benchmark $VM
Cleanup $VM
