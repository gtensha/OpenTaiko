# OpenTaiko
OpenTaikoは、GPLv3されてる音ゲームです。D言語で書いてあって、グラフィックはSDL2([DerelictSDL2][3])で、サウンドとしてはSFML2([DerelictSFML2][4])を利用しています。

![曲選択画面](screenshot0.png)

![遊び中](screenshot1.png)

_スクリーンショットは現在のゲームと違っている可能性があります。_

# 始める前に
OpenTaikoを使えるようになる前に、コンパイラーとその他の必要なことをじゅんびしましょう。違うOSは違うインストール方法がありますので、気をつけてください。バイナリーリリースに関している機能は詳しく決めてないため、まだ配信しません。

# コンパイラー
現在、dmdしか完全に対応しません。しかし、場合によって他のコンパイラーも使えるようになるかもしれません。なお、ldcサポートは将来の目的です。

dmdとderelict-sdl2のバグのため、dmdを使えると「-release」フラグをつけば実行時にエラーが出てしまいそうなので、現在「debug」しか利用できません。

# 要り物（パッケージなど）
* dmd
* dub
* SDL >= 2.0
* SDL2\_ttf
* SDL2\_image
* ffmpeg、コマンドライン系（SFML2はmp3対応がないので、ffmpeg使えれば遊ぶ時にmp3をoggに、再生できられる）
* csfml-audio-2

利用しているプラットフォームにcsfmlがない場合はSDL\_mixerも使えられるが、音楽再生計時能がなくて、正しく実行しない場合があります。なお、音質が悪くなる可能性もありますので、できればcsfmlを使ってください。

## DUB dependencies
dub.sdlをご覧ください。

## プラットフォーム特有やり方
自分のOSの特有やり方をここにつけてもどうぞ。もうやったってところがあればもちろん、やり直す必要がありません。

### Linux
どんなディストロでもOpenTaikoはコンパイルと実行するはずです。

#### 一般的に
ディストロのパッケージマネージャーを使って、「要り物」から各を探してインストールのが基本的なやり方です。普通にこんなところまでです。

#### Debian/Devuan (stable)
aptを使って、こちらのパッケージをインストールします。

* libsdl2-2.0-0
* libsdl2-image-2.0-0
* libsdl2-ttf-2.0-0
* libcsfml-audio2.3
* ffmpeg

```
apt install libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 libcsfml-audio2.3 ffmpeg
```

dubとdmdが公的なリポジトリにありませんので、dlang.orgからの [official installer](https://dlang.org/download.html)を使います。

```
wget http://downloads.dlang.org/releases/2.x/2.084.0/dmd_2.084.0-0_amd64.deb
```

付け込んでいる.sigファイルを使ってインストール前にパッケージの確認を行いましょう。

```
sudo dpkg -i dmd_2.084.0-0_amd64.deb
```

### Windows
まず、[dlang.org](https://dlang.org/download.html#dmd)からdmd installer exeを手に入ります。説明どおりにインストールして、Visual Studio対応の質問に「do nothing」を答えてdmdとdubがインストール込みのを待つだけです。

gitを持っている場合はgit cloneでOpenTaikoのリポジトリをクローンします。でもWindowsで使い辛いし、持っていない方は.zipを手に入ることもできますので、実験だけがしたい方に一番便利な方法かもしれません。

次は必要な.dllファイルとffmpegを手に入ります。64-bitマシンが持っている方に64-bitの.dllが必要で、32-bitマシンは32-bitの.dllなので、気をつけて正しいのをダウンしましょう。ダウンした.dllをOpenTaikoディレクトリに運びます。SDL2なら様々な.dllが付いていますので、必ずそれもこれも運びましょう。こちらの.dllをダウンロードします。

* [SDL2](http://libsdl.org/download-2.0.php)
* [SDL2-ttf](https://www.libsdl.org/projects/SDL_ttf/) 「Runtime Binaries」下のWindows系を選びます
* [SDL2-image](https://www.libsdl.org/projects/SDL_image/)前と同じくやって、zlibを書き換えても構いません
* [CSFML](https://www.sfml-dev.org/download/csfml/)、Windowsの一番新しいやつを。ダウンした.zipの「bin」ディレクトリから「csfml-audio-2.dll」を運ぶだけで十分です

その後は前と同じように[ffmpeg.exe](https://ffmpeg.zeranoe.com/builds/)をダウンロードして、ffmpeg.exeをOpenTaikoディレクトリに運びます。今度も要る実行ファイルが「bin」ディレクトリにあります。

つついては[OpenAL redistributable](http://openal.org/downloads/oalinst.zip)を手に入ります。インストーラーを実行したくない場合は[SFML builds](https://www.sfml-dev.org/download/sfml/2.5.1/)からのバージョンを選んで、付け込んでいるopenal32.dllを前と同じように使えても平気です。

OpenTaikoのコンパイル準備ができました。cmdを実行してOpenTaikoディレクトリを選びます。簡単に正しいディレクトリを選べるようにExplorerのアドレスバーからcdコマンド後にコピペできます。スペースや特別文字があるパスならご覧のように「"」の取り巻くを行いましょう。

```
cd "C:\Users\gtensha\Projects\OpenTaiko-0.2"
```

最後はビルドを行いだけです。64-bitマシンなら--arch=x86\_64のフラグを付きましょう。32-bitの場合は--arch=x86を使えます。それと--config=SFMLMixerのフラグも必要です。フラグを付けてdub buildのコマンドを実行します。

```
dub build --config=SFMLMixer --arch=x86_64
```

最初ならdubがネットからdependencyをGETしますので少々待ってください。

完成したらOpenTaiko.exeがディレクトリに出てきました。OpenTaikoの実行時にエラーが出たら、もう一同上のことを確認してください。特に、マシンに正しいdllバージョンを手に入れたことを確認してください。

### BSD
ただいまBSDのサポートがよく確認していませんが、ほとんどのBSDは必要なライブラリーが利用可能ので、できるかもしれません。

### MacOS
状況不明なのですが、できるはずです。

## ビルド方法
OpenTaikoはビルドシステムとしてdubを利用しています。dubはOSのコマンドラインから実行します。なお、作業ディレクトリはOpenTaikoにクローンしたディレクトリにセットします。

```
dub run
```

を実行したら、OpenTaikoはビルドされて、実行します。

```
dub build
```

ならビルドだけを行います。まだSFMLサポートに必要なので
```--config=SFMLMixer```
フラグも忘れないように。

どちらのコマンド系を選んでも本ディレクトリにOpenTaikoの実行ファイルが出てきます。ほかのディレクトリに運びせずに後から自由に実行できます。

本マシンにコンパイルしたい方は普通にプロセッサーのISAを特定する必要がないのですが、64-bitのWindowsユーザーなら特定しないと32-bitバイナリーになるし、64-bit dllを利用できなくなります。フラグとして
```
--arch=x86_64
```
を付いたら64-bitのビルドを行います。自由にフラグを交えて実行します。

```
dub build --config=SFMLMixer --arch=x86
```

上のコマンドはSFMLサポート付きの32-bit x86ビルドとなります。

初ビルドにはネットからdependenciesのダウンロードによって少々時間がかかるかもしれません。この時はネットワーク接続が必要なので気をつけてください。その後は自由にオフラインでも作業をつついても平気です。手でdependencyを手に入る方法に関してる情報が知りたいならdubの文書化をご覧ください。

# 目的
どんなマシンを使っても遊べる音ゲーになること。

同じマシンでもネットでもマルチプレイヤー機能があって、楽しくて楽にできること。

同じ感じのゲームからマップのインポートができたり、簡単にテキストファイルの変化を行ってマップ作成できたりすること。

コードにたいして誰でも簡単に変化するように、ソースコードが読みやすくてよく実行すること。直したり追加したりこといっぱいあるのでその状況になるまでももちろん投稿が受け入れられています。

OpenTaikoはGNU GPLv3のフリーソフトため、すべてをフリーソフトままで配信できるようにフリーな共有ライブラリを使いのみのこと。

[3]: https://github.com/DerelictOrg/DerelictSDL2
[4]: https://github.com/DerelictOrg/DerelictSFML2
