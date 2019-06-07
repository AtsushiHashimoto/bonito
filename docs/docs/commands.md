# 基本コマンド一覧

## create
    % bonito create [options]
既にあるdocker imageを元に，新しいimageを複製します．

## delete
    % bonito delete [options]
docker imageを削除します．

## run
    % bonito run [options]
docker imageを開始します．既に開始済みのcontainerが存在する場合には，そのコンテナに接続します．

## shutdown
    % bonito shutdown [options]
起動中のdocker containerを終了し，削除します．

## reboot
    % bonito reboot [options]
起動中のdocker containerをrebootします．

## help
    % bonito --help．
このページと同様の内容を表示する．コマンド名が指定されている場合は，そのコマンドのhelpを表示する．

    例) % bonito run --help 
