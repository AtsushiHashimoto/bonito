# セットアップのガイド(サーバ管理者向け)


## 前提

計算用サーバは必ずしもGPUクラスタである必要はありませんが，現状はubuntuのみが公式サポートされています(基本的にはlinux全般で動くはず)．
HeteroなPC群であっても，nfsなどでディレクトリ共有がされてさえいれば動きます．
逆にいえば，リソースの管理などは行いません．どの仮想環境からもPC上のすべてのGPUが見えます．
言い換えれば，計算用サーバの利用者は他のチャンネルで繋がっており，リソース管理は別の方法で行うことが想定されています．

## 設定

1. nfsなどの共有ディレクトリ(/path/to/nfs)上にbonitoをcloneします．

    % cd /path/to/nfs/
    % git clone https://github.com/AtsushiHashimoto/bonito.git bonito

1. 設定ファイルを編集します．

    % cd bonito
    % cp bonito.conf.example bonito.conf
    % vim bonito.conf

    - BONITO_DIR /path/to/nfs/BONITO_DIRを指定してください．

    - BONITO_HOME_DIR bonitoのdockerファイルが利用するホームディレクトリを指定します．基本は $BONITO_DIR/volume/home となります．

    - BONITO_MOUNTS defaultでマウントするべきディレクトリ(学習用データが置かれたNASなど)はここで指定できます．  
      注) /dev, /tmpは常に指定することをお勧めします．特に/dev/shmをマウントしないとプログラム実行時にshared memoryのサイズが不足するエラーがでる場合があります．  
      ディレクトリ名の後ろに:roをつけるとread onlyでマウントされます．  
      e.g.) `BONITO_MOUNTS="/tmp /dev /NAS1:ro /NAS2"`  
      これでhostPC上の/NAS1は，docker container内で/NAS1として，read onlyでマウントされます．
      hostPC上の/NAS2は，container内で/NAS2として，read/write可能なディレクトリとしてマウントされます．

    - BONITO_COMMON_RUNOPT="--runtime=nvidia"

1. Dockerfileの全ユーザ共通部分を作成します．  
    
    ```% cp Dockerfile_head.example Dockerfile_head```  
```% vim Dockerfile_head```
    
1. bonitoコマンドをpathが通っているディレクトリに追加します(各ホストで実行)．  
   
```% ln -s /path/to/nfs/bonito /usr/bin/bonito```
   
1. [ユーザとして利用](./how-to-use.html)し，テストをします．

### ホスト毎に異なるDockerfileを生成するようにする

3のDockerfile_headはホスト毎に異なるファイルを使うようにもできます．
例えば，host名が server2のマシンにのみ適用するDockerfile_headは， ファイル名をDockerfile_head.server2 とすれば，bonitoは実行したPCの環境変数$HOSTNAMEから自動的にファイルを特定し，それをDockerfile_headとして利用します．

## 



