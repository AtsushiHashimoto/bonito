# Welcome to Bonito

Bonitoは小規模な研究室などでGPUサーバを共用しながら，各自が自由に仮想PCをいじくり回すことができるようにするためのオープンソースプロジェクトです．

- [githubのプロジェクトページ](https://github.com/AtsushiHashimoto/bonito)

# 哲学
Teachers be lazy! 最小の構成で，学生が自由にsudoできるお砂場仮想環境をGPUサーバ上で構築する．

## 誰に向けたプロジェクト?
研究室でGPUサーバを学生に共有させており，管理者権限は教員(or係の学生)が握っている研究室．

## 何ができるの?
- 学生が他のユーザに迷惑できずに自由にsudoできる仮想PCをGPUサーバ上で配布できる．
- dockerに関する初期教育コストなく，仮想PCを利用させることができる．

## ユーザ側の利用イメージ
1. 初回: 研究室標準のdocker imageを複製し，自分用のimageを作成)
  % bonito create [--user my_name]

2. docker image作成後: 自分用のimageを起動 (すでに起動している場合は，接続)
  % bonito run

3. docker imageの変更後: 自分用のimageを更新（container終了後も変更内容が保持されるようにする)
  % bonito snapshot

## 管理者側の利用イメージ
0. 複数のGPUサーバで共通のdocker imageを使う時のみ:
  - NFSなどを使い，dockerのhomeディレクトリを全サーバで共有する．
  - docker_repositoryの設定を行い，docker imageをサーバを跨いでpullできるようにする
1. bonitoをpullする
  % mv /path/to/bonito
  % git clone https://github.com/AtsushiHashimoto/bonito.git bonito
2. bonito.confファイルを編集し，初期設定を行う
  % vim /path/to/bonito/bonito.conf
3. nvidia-docker2のimage (base_image)をpullする
  % docker pull <<base_imageの名前>>
4. base_imageのコンテナを立ち上げ，研究室の環境に合わせた設定を行う
  % bonito create -u default -b <<base_imageの名前>>
  % bonito run -u default
  % bonito snapshot

# FAQ

1. KubernetesやKubeflowと違って，研究室など，実験に特化して，その後のクラウドでのローンチなどが不要なユーザに，最小のセットアップでの仮想環境配布を実現します．
2. dockerのwrapperとなっているため，dockerを使ってできることは，原理的には何でも出来ます．
 - [dockerについて:]
 - nvidia-docker2を使ったGPU利用
3. JupyterやTensorboardは使えるの??
 - imageを起動する際に，dockerコマンドにオプションを渡すことで利用できます．
  - 方法1: コマンドラインで指定
    % bonito run -o "-p 18888:8888 -p 16006:6006"
  - 方法2: ユーザごとの設定ファイルで指定
    % vim ~/.bonito/bonito.conf
    BONITO_OPTION_AT_RUN4DEFAULT="-p 18888:8888 -p 16006:6006"
