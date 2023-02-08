FROM python:3.10

EXPOSE 80 443 1180 11443 5432

# install network tools
RUN apt-get upgrade -y && apt-get update -y && apt-get install -y \
    bash dnsutils curl iproute2 jq mtr iputils-ping net-tools nginx \
    openssl telnet procps tcpdump tcptraceroute wget postgresql postgresql-contrib

# install kubectl + add kc aliases
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
RUN echo 'alias kc="kubectl -n cnvrg"' >> ~/.bashrc
RUN echo 'alias app="kubectl -n cnvrg exec -it deploy/app -c cnvrg-app -- bash -l"' >> ~/.bashrc
RUN echo 'alias app-v="kc get pods -l app=app -o jsonpath='{.items[0].spec.containers[0].image}'; echo"' >> ~/.bashrc
RUN echo 'alias kwatch="watch 'kubectl -n cnvrg get pods'"' >> ~/.bashrc
RUN kubectl help

# install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
RUN aws --version

# Install the AWS authenticator
RUN curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64
RUN chmod +x ./aws-iam-authenticator
RUN install ./aws-iam-authenticator /usr/local/bin

# Install redis-cli
RUN apt install -y redis-tools
RUN redis-cli --version

## install Minio CLI
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc
RUN chmod +x mc && ./mc --help && mv ./mc /usr/local/bin && \
    mc ls && ls -la /root/.mc/config.json
RUN mc --help

# install jupyterlab version for running in a cnvrg workspace
RUN pip install jupyterlab==3.4.2 jupyterlab-git==0.37.1 nbclassic==0.4.8

# Install rysnc tool
RUN apt install -y rsync

# copy in the backup script and make executable
COPY ./dbs-backup.sh ./dbs-backup.sh
RUN chmod +x ./dbs-backup.sh


# verify versions
RUN python --version
RUN python3 --version
RUN pip --version
RUN pip3 --version
RUN pip show jupyterlab
RUN pip show jupyterlab-git
RUN pip show nbclassic

SHELL ["/bin/bash", "-c"]
CMD ["/bin/bash"]
