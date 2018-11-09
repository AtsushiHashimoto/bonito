# docker imageの操作

## create独自のオプション
- '-b|--base_image'
  イメージ作成時にコピー元となるdocker imageを指定する
  省略時は， bonito run -u defaultで実行されるイメージとなる (通常，bonito:default:default:latestという名前になる．)

    例1) bonito create
    例2) bonito create -u default -b nvidia_docker2:ほげほげ
    例3) bonito create -p my_second_project

## delete独自のオプション
- 何もなし

    例) bonito delete

## snapshot独自のオプション
- 何もなし

    例) bonito snapshot
    
