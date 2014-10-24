#kafka topics
sv start kafka
/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic rules
/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic forex
/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic forexJ

#rule engine topology
sv start nimbus
/storm/bin/storm jar /wolf/rule.engine/target/rule.engine-0.0.1-SNAPSHOT-jar-with-dependencies.jar rule.engine.RuleEngineTopology RuleEngine

#data provider
sed -i "s|\$HOME||" /wolf/data.provider/bin/run.sh
sed -i "s|/home/ubuntu|/wolf|" /wolf/data.provider/src/5.crontab.txt
/wolf/data.provider/bin/run.sh

#cassandra tables
sv start cassandra
/cassandra/bin/cqlsh < /wolf/data.aggregator.rt/src/1.create.table.cql
