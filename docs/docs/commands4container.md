# コンテナに対する操作
## run独自のオプション
 - '-c|--command': docker起動時に実行するプログラムを指定する．省略時は'/bin/sh'となる．このデフォルト値はユーザ設定ファイルでBONITO_SHELLを指定することで変更可能．
 - '-o|--options': docker起動時に，docker run コマンドに対するオプションを指定する．(以下は未実装）このデフォルト値はユーザ設定ファイルでBONITO_OPTION4defaultで指定可能．(他のプロジェクトに対しては'default'の部分をプロジェクト名に変更することで指定可能．)

上記の2つのオプションは，runコマンドがコンテナを新たに起動するときのみ有効．起動済みのコンテナに接続する際には無視される（その旨のWarningも表示される）

    例1) % bonito run
    例2) % bonito run -c 'sh /root/my_own_script.sh'
    例3) % bonito run -o '-p 18888:8888 -p 10022:22'

## shutdown独自のオプション
 - 特になし
    例1) % bonito shutdown
    例2) % bonito shutdown -u default
    例3) % bonito shutdown -p my_second_project

## reboot
- 特になし (runと同じ独自オプションを持つべきだが，未実装）
    例) % bonito reboot
