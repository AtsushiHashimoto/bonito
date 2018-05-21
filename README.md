# bonito
a docker wrapper for academic laboratories.

# who should use bonito?
- those who want to give your student a root permission of the server.
- those who do not want your students change server settings.

# alternatives you should consider before installing bonito
- kubeflow (provide jupyter env to your student.)
- Rancher (provide web gui to control containers.)


# Quick Start (stand alone mode)
(tested on Ubuntu16.04.)
1. install docker server
2. install nvidia-docker2
3. download bonito
```
% cd /share
% git clone https://github.com/AtsushiHashimoto/bonito.git bonito
% cd bonito
% cp bonito.conf{.example,}
% cp volume/home/default{.example,}
```
(note: for multi-node setting, /share should be shared through NFS etc.)  
4. (multinode mode only) install and run docker registry.  
  - set registry server ip address to 'BONITO_REGIS_SERVER' in bonito.conf
  - exec following command at registry server machine
```
% /share/bonito/sbin/bonito_adm start_registry
```
  - exec following command at non-registry server machine (this command enables the machine to access your docker images remotely.)
```
% /share/bonito/sbin/bonito_adm init
```

5. download/set default image
```
% docker pull nvidia/cuda:9.2-cudnn7-runtime-ubuntu16.04 #adjust cuda/cudnn/ubuntu versions to your env.
% bonito create -u default -b nvidia/cuda:9.2-cudnn7-runtime-ubuntu16.04
```

6. edit default docker image
```
% bonito run -u default
(edit)
% bonito snapshot -u default
```
(you can directly put files to '/share/bonito/volume/home/default/', where is mounted as /root/ in docker container)

7. create your virtual machine, and run it. (once you have done 1-5 steps, you only need step 6 for every new user.  
    - as a root (after creating an account for the new user)
```
# /share/bonito/sbin/bonito_adm add_user <<username>>
# systemctl daemon-reload
# systemctl restart docker
```
    - as the new user
```
% echo export PATH="$PATH:/share/bonito/bin"
% bonito create
% bonito run
```

Now, you should be able to run your virtual machine.

# bonito virtual machine lifecycle
```
% bonito create (only once)
% bonito run 
% bonito shutdown (when you want to stop the container)
% bonito delete (when you want to delete the image)
```

# USE CASE
## run jupyter-notebook as a daemon for each user, which is accesible via port 18888 of the host machine.
```
% bonito run -c /root/jupyter.sh -o "-d --restart=always -p 18888:8888"
```



