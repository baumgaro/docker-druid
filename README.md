# Druid Docker - Tutorial

## Run the Tutorial
This docker image will allow you to follow all tutorial lessions from
http://druid.io/docs/latest/tutorials/

The image is build and tested with Druid version 0.12.3

[Install Docker](docker-install.md)

Build the docker image and run it:

```sh
docker build -t baumgaro/druid:latest .
docker run --rm --name druid -i -p 8082:8082 -p 8081:8081 -p 8090:8090 baumgaro/druid:latest
```

Wait a minute or so for Druid to start up. The tutorial example files are downloaded inside the docker container.





On OS X

- List datasources

```
curl http://$(docker-machine ip default):8082/druid/v2/datasources
```

- access the coordinator console

```
open http://$(docker-machine ip default):8081/
```

- more command can be found in the "On Linux" section ....

On Linux

- List datasources

```
curl http://localhost:8082/druid/v2/datasources
```

- Coordinator - List Workers and Tasks
```
curl http://localhost:8090/console.html
```

- access the coordinator console at http://localhost:8081/

- Tutorial - Load batch data (http://druid.io/docs/latest/tutorials/tutorial-batch.html)
The example files are downloaded inside the docker container. With this command you can import them into druid:

```
docker exec druid sh -c 'curl -X 'POST' -H 'Content-Type:application/json' -d @examples/wikipedia-index.json http://localhost:8090/druid/indexer/v1/task'
```

- Tutorial - Query the datasource
This is quering druid - all just copied from the tutorial pages mentioned above.
```
docker exec -it druid curl -X 'POST' -H 'Content-Type:application/json' -d @examples/wikipedia-top-pages.json http://localhost:8082/druid/v2\?pretty

```


## Logging

You might want to look into the logs when debugging the Druid processes. This can be done by logging into the container using `docker ps`:
```
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                                                                                                      NAMES
9e73cbfc5612        druidio/example-cluster   "/bin/sh -c 'export H"   7 seconds ago       Up 6 seconds        2181/tcp, 2888/tcp, 3306/tcp, 3888/tcp, 8083/tcp, 0.0.0.0:3001->8081/tcp, 0.0.0.0:3000->8082/tcp    sick_lamport
```

And attaching to the container using `docker exec -ti 9e73cbfc5612 bash` logs are written to `/tmp/`:

```
root@d59a3d4a68c3:/tmp# ls -lah        
total 224K
drwxrwxrwt  8 root   root   4.0K Jan 18 20:38 .
drwxr-xr-x 61 root   root   4.0K Jan 18 20:38 ..
-rw-------  1 root   root      0 Jan 18 20:38 druid-broker-stderr---supervisor-az6WwP.log
-rw-------  1 root   root    18K Jan 18 20:39 druid-broker-stdout---supervisor-D28zOC.log
-rw-------  1 root   root      0 Jan 18 20:38 druid-coordinator-stderr---supervisor-RYMt5L.log
-rw-------  1 root   root   100K Jan 18 21:14 druid-coordinator-stdout---supervisor-Jq4WCi.log
-rw-------  1 root   root      0 Jan 18 20:38 druid-historical-stderr---supervisor-rmMHmF.log
-rw-------  1 root   root    18K Jan 18 20:39 druid-historical-stdout---supervisor-AJ0SZX.log
-rw-------  1 root   root   7.9K Jan 18 21:09 druid-indexing-service-stderr---supervisor-x3YNlo.log
-rw-------  1 root   root    28K Jan 18 21:14 druid-indexing-service-stdout---supervisor-5uyV7u.log
-rw-------  1 root   root    155 Jan 18 20:38 mysql-stderr---supervisor-NqN9nY.log
-rw-------  1 root   root    153 Jan 18 20:38 mysql-stdout---supervisor-23izTf.log
-rw-------  1 root   root     78 Jan 18 20:38 zookeeper-stderr---supervisor-Rm33j8.log
-rw-------  1 root   root   7.4K Jan 18 20:39 zookeeper-stdout---supervisor-6AFVOR.log
```

## Troubleshooting

This section will help you troubleshoot problems related to the Dockerized Druid.

### Out-Of-Memory (OOM) when using OSX

When using Docker on OSX, the Docker environment will be executed within the [HyperKit](https://github.com/docker/hyperkit) hypervisor, a lightweight visualization framework for running the Docker containers:
```
docker-druid foobar$ ps -ax | grep docker.hyperkit
71175 ??         0:04.02 /Applications/Docker.app/Contents/MacOS/com.docker.hyperkit -A -m 2048M -c 4 -u -s ...
```

The allocated resources are limited by default to 2 cpu's and 2gb of memory. Although 2gb is sufficient in most application, the Druid container is rather heavyweight because of the Mysql, Zookeeper and the JVM's. When start spawning additional JVM's, for example an indexing job, this might cause issues:
```
2017-01-20T15:59:58,445 INFO [forking-task-runner-0-[index_transactions_2017-01-20T15:59:50.637Z]] io.druid.indexing.overlord.ForkingTaskRunner - Process exited with status[137] for task: index_transactions_2017-01-20T15:59:50.637Z
```
From the log we observe that the process receives an 137 (=128+9) SIGKILL signal. Because it hit the memory limit, the application is killed instantly. To avoid this you might want to give more resources to the Docker hypervisor under Docker > Preferences.
