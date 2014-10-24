FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

#Runit
RUN apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
RUN sed -i "s/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/" /etc/pam.d/sshd
RUN sed -i "s/PermitRootLogin without-password/#PermitRootLogin without-password/" /etc/ssh/sshd_config

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#Data provider
RUN apt-get install -y python-pip
RUN pip install cql
RUN pip install pytz
RUN git clone https://github.com/mumrah/kafka-python && \
    pip install ./kafka-python
RUN pip install flask
RUN pip install jsonschema

#Kafka
RUN curl http://mirror.cogentco.com/pub/apache/kafka/0.8.1.1/kafka_2.9.2-0.8.1.1.tgz | tar zx && \
    mv kafka_* kafka

#Maven
RUN curl http://apache.mirrors.lucidnetworks.net/maven/maven-3/3.2.3/binaries/apache-maven-3.2.3-bin.tar.gz | tar zx
RUN ln -s /apache-maven-3.2.3/bin/mvn /usr/bin/mvn

#Storm
RUN wget http://mirror.symnds.com/software/Apache/incubator/storm/apache-storm-0.9.2-incubating/apache-storm-0.9.2-incubating.zip && \
    unzip apache-storm-0.9.2-incubating.zip && \
    rm *zip && \
    mv apache-storm* storm

#Cassandra
RUN curl http://www.us.apache.org/dist/cassandra/2.1.0/apache-cassandra-2.1.0-bin.tar.gz | tar zx && \ 
    mv apache-cassandra* cassandra

#PHP-FPM
RUN apt-get install -y nginx php5-fpm
RUN sed -i "s|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|" /etc/php5/fpm/php.ini

RUN git clone --depth 1 https://github.com/slawekj/wolf.git
RUN cd wolf/rule.engine && \
    sed -i "s|0.9.3-incubating-SNAPSHOT|0.9.2-incubating|" pom.xml && \
    sed -i "s|ec2-.*\.amazonaws\.com|localhost|" /wolf/rule.engine/src/main/java/rule/engine/RuleEngineTopology.java && \
    mvn install

#Add runit services
ADD sv /etc/service 
ADD init.sh /init.sh

#fix ajax calls
RUN find /wolf/web.interface/js -type f -exec sed -i 's|http://54\.183\.118\.189|http://"+location.hostname+"|' {} \;
#add missing jot
RUN wget http://www.flotcharts.org/downloads/flot-0.8.3.zip && \
    unzip flot*zip && \
    rm flot*zip && \
    mv flot /wolf/web.interface/js
#fix calls to aws
RUN find /wolf/ -type f -exec sed -i "s|ec2-.*\.amazonaws\.com|localhost|" {} \;

#Init
RUN runsv /etc/service/zookeeper& \
    runsv /etc/service/kafka& \
    runsv /etc/service/nimbus& \
    runsv /etc/service/cassandra& \
    sleep 3 && ./init.sh

