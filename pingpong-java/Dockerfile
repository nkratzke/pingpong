FROM ubuntu

MAINTAINER Nane Kratzke

# Update the system
RUN sudo apt-get install software-properties-common python-software-properties -y
RUN sudo add-apt-repository ppa:webupd8team/java -y
RUN sudo apt-get update

# Install Java
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
RUN sudo apt-get install oracle-java8-installer -y

# Installs Sources
ADD src /pingpong/src

# Compiles Sources
RUN javac -classpath /pingpong/src /pingpong/src/*.java

EXPOSE 8888

ENTRYPOINT ["java", "-classpath", "/pingpong/src", "Ping"]