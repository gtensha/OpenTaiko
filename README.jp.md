# OpenTaiko
OpenTaiko は、クロスプラットフォーム対応のリズムゲームで、D 言語で書かれています。グラフィックライブラリに SDL2 ([DerelictSDL2][3]) を、サウンドライブラリに SFML2([DerelictSFML2][4]) をそれぞれ利用しています。

GNU GPLv3 ライセンスのもとで利用可能です。

![曲選択画面](screenshot0.png)

![プレイ中](screenshot1.png)

_※画像は現在のゲームと異なる可能性があります。_

# 始める前に
OpenTaiko を使う前に、コンパイラとその他の必要なものを準備しましょう。OS ごとにインストール方法が異なるので、利用している OS のインストール方法をご覽ください。バイナリのリリースはありません。リリースに関する機能は未実装です。

# コンパイラ
現在、dmd と ldc のみ対応しています。しかし、場合によっては他のコンパイラも使えるかもしれません。

コンパイル時に dmd の release フラグをつけると実行時にエラーが発生します。そのため、現在は dmd のデバッグビルドのみサポートしています。これは dmd と derelict-sdl2 のバグのためです。ldc は問題なく release ビルドを行えます。

# 依存パッケージ
* dmd または ldc
* dub
* SDL >= 2.0
* SDL2\_ttf
* SDL2\_image
* ffmpeg のコマンドラインツール (SFML2 は mp3 対応していないので、ffmpeg が使用できれば、プレイする際に mp3 を ogg に変換して再生可能です)
* csfml-audio-2

利用しているプラットフォームに csfml がない場合は SDL\_mixer も使えますが、音楽再生のタイミングが合わずに、正しく実行できない場合があります。なお、音質が悪くなる可能性もありますので、できれば csfml を使ってください。

## DUB dependencies
[dub.sdl](dub.sdl) をご覧ください。

## OS 固有のセットアップ手順
利用している OS 手順がここに記載されていない場合は、一般的な手順を実施してください。成功したらこのリストを更新して、ぜひ PR をください。

### Linux
どんなディストリビューションでも OpenTaiko はコンパイルおよび実行できるはずです。

#### 一般的な手順
ディストリビューション標準のパッケージマネージャを使って、コンパイルに必要なパッケージをインストールしてください。

#### Debian/Devuan (stable)
Debian buster のリポジトリーに ldc のバージョン1.12がありますので、dmd よりこのバージョンをお勧めします。
stretch や ascii を利用している方は未だに dmd をインストールする必要があります。その場合は依存パッケージをインストールの上、以下の stretch/ascii 節をご覧ください。
apt を使って、これらのパッケージをインストールします。

* gcc (buster のみ)
* ldc (buster のみ)
* dub (buster のみ)
* libsdl2-2.0-0
* libsdl2-image-2.0-0
* libsdl2-ttf-2.0-0
* libcsfml-audio2.5 (stretch/ascii に libcsfml-audio2.3)
* ffmpeg

##### buster
以下のコマンドは buster のみ対応しています。ldc と dub は Debian の公式リポジトリーからインストールされます。

```
apt install gcc ldc dub libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 libcsfml-audio2.5 ffmpeg
```

derelict-sfml2 は libcsfml-audio のバージョン 2.4 以上の情報を持っていないため、シンボリックリンクを作る必要があります。リンクは /usr/lib かプロジェクトのディレクトリかどっちに作っても同じです。下のコマンドは DLL を探してワーキングディレクトリにリンクを作ります。

```
ln --symbolic $(find /usr -name libcsfml-audio.so.2.5 | head -n 1) libcsfml-audio.so.2
```

##### stretch/ascii
dub とdmd が公式のリポジトリにはないので、dlang.org の [official installer](https://dlang.org/download.html) を使用してください。以下のコマンドはバージョン 2.084 をダウンロードしますが、ダウンロードページからの最新のバージョンをお勧めします。

```
wget http://downloads.dlang.org/releases/2.x/2.084.0/dmd_2.084.0-0_amd64.deb
```

ダウンロード済みの .sig ファイルを使ってインストール前にパッケージの確認を行いましょう。

```
sudo dpkg -i dmd_2.084.0-0_amd64.deb
```

#### Guix
ご覧のパッケージをインストールして、または environment に追加してください。

* ldc
* dub
* sdl2
* sdl2-ttf
* sdl2-image
* sfml
* ffmpeg

インストールするには

```
guix install ldc dub sdl2 sdl2-ttf sdl2-image sfml ffmpeg
```

で、environment に追加するだけには以下のコマンドを実行します。

```
guix environment --ad-hoc ldc dub sdl2 sdl2-ttf sdl2-image sfml ffmpeg
```

CSFML は公式リポジトリからインストール出来ませんが、[このパッケージ製法](https://gist.github.com/gtensha/d42f34e5276e2267c086cc8bd5bb82b2)を使えば自動的にダウンロードおよびビルドが行い、インストール出来ます。以下のコマンドの風になります。

```
wget https://gist.github.com/gtensha/d42f34e5276e2267c086cc8bd5bb82b2/raw/3530f5ddf95281513c3bfcb7d964f31af5a19de5/csfml-guix.scm
guix package --install-from-file=csfml-guix.scm
```

### Windows
まず、[dlang.org](https://dlang.org/download.html#dmd )から dmd インストーラを入手します。説明どおりにインストールして、Visual Studio 対応の質問には「do nothing」を答えて dmd とdub がインストールされるのを待つだけです。

git を持っている場合は git clone で OpenTaiko のリポジトリをクローンします。ただし  Windows の git は少々使いづらいかもしれません。.zip をダウンロードすることもできますので、試したい方には一番便利な方法かもしれません。

次に、必要な .dll ファイルと ffmpeg を手に入れましょう。64-bit PC を持っている方は 64-bit の .dll が必要で、32-bit PC は 32-bit の .dll が必要なので、気をつけて正しいものをダウンロードしましょう。ダウンロードした .dll を OpenTaiko ディレクトリに移動します。SDL2 にもいくつかの .dll が付いていますので、必ずそれも移動しましょう。

これらの .dll をダウンロードします。

* [SDL2](http://libsdl.org/download-2.0.php)
* [SDL2-ttf](https://www.libsdl.org/projects/SDL_ttf/) 「Runtime Binaries」下の Windows 系を選びます。
* [SDL2-image](https://www.libsdl.org/projects/SDL_image/) 上記と同じように行い、zlib を書き換えても構いません。
* [CSFML](https://www.sfml-dev.org/download/csfml/) Windows の最新バージョンを選びます。ダウンロードした .zip の「bin」ディレクトリから「csfml-audio-2.dll」を移動するだけで十分です。

その後は、同様に [ffmpeg.exe](https://ffmpeg.zeranoe.com/builds/) をダウンロードして、ffmpeg.exe を OpenTaiko ディレクトリに移動します。ffmpeg.exe は「bin」ディレクトリにあります。

続いて [OpenAL redistributable](http://openal.org/downloads/oalinst.zip) を手に入れましょう。インストーラを実行したくない場合は [SFML builds](https://www.sfml-dev.org/download/sfml/2.5.1/) からバージョンを選んで、zip ファイルにある openal32.dll を前と同じように使っても大丈夫です。

OpenTaiko のコンパイル準備ができました。cmd を実行して OpenTaiko ディレクトリに移動します。エクスプローラのアドレスバーからディレクトリパスをコピーして、cd を入力後にペーストすると簡単です。スペースや特別文字があるパスなら以下のように「"」で囲みましょう。

```
cd "C:\Users\gtensha\Projects\OpenTaiko-0.2"
```

最後はビルドを行うだけです。64-bit マシンなら --arch=x86\_64 のフラグを付けましょう。32-bit の場合は --arch=x86 を使います。それと --config=SFMLMixer のフラグも必要です。フラグを追加して dub build のコマンドを実行します。

```
dub build --config=SFMLMixer --arch=x86_64
```

初回実行時は dub がインターネットから依存ファイルを取得しますので少々お待ちください。

ビルドに成功したら OpenTaiko.exe がディレクトリに作られます。OpenTaiko の実行時にエラーが出たら、もう一度、手順を確認してください。特に、PC のアーキテクチャにあった dll が含まれることを確認してください。

### BSD

#### FreeBSD
CSFML を除いて、コンパイラー・必要なライブラリはすでに ports から利用可能なので、以下のパッケージをインストールします。

```
pkg install ldc dub sdl2 sfml sdl2_image sdl2_ttf ffmpeg
```

実行できる前に、[CSFML](https://www.sfml-dev.org/download/csfml/) をソースからコンパイル必要があります。sfml、gcc、cmake をもったら問題なくコンパイルおよびインストールを行えるはずです。

```
doas pkg install cmake gcc
curl -O https://www.sfml-dev.org/files/CSFML-2.5-sources.zip
unzip CSFML-2.5-sources.zip
cd CSFML-2.5
mkdir build
cd build
cmake ..
make
doas make install
```

### MacOS
[homebrew](https://brew.sh/) を使って必要なパッケージをインストールします。

## ビルド方法
OpenTaiko はビルドシステムとして dub を利用しています。dub は OS のコマンドラインから実行します。なお、作業は OpenTaiko をクローンしたディレクトリで行います。

```
dub run
```

を実行したら、OpenTaiko はビルドされて、実行します。

```
dub build
```

ならビルドだけを行います。SDLMixerのサポートはあんまりよくなくてお勧めしませんが、利用しているプラットフォームに SFML サポートがない場合は

```
--config=SDLMixer
```

フラグを使えます。DerelictSFML ソースをダウンロードせずSDL_Mixerとリンクされるビルドとなります。

どちらのコマンドを実行してもワーキングディレクトリに OpenTaiko の実行ファイルが出てきます。ほかのディレクトリに移動せずに、そのまま実行できます。

一般的に、コンパイル時にアーキテクチャを意識する必要はありません。ただし、64-bit の Windows のみ、フラグを指定しないと 32-bit バイナリになり、64-bit の dll を利用できなくなります。
そのため以下のフラグをつけてください。

```
--arch=x86_64
```

これで 64-bit のビルドを行います。また、複数のフラグを組み合わせることができます。

```
dub build --config=SFMLMixer --arch=x86
```

上のコマンドは SFML サポート付きの 32-bit x86 ビルドとなります。※SFMLMixer の値は冗長です

初回ビルド時はインターネットから依存ファイルのダウンロードによって少々時間がかかるかもしれません。この時はネットワーク接続が必要なので気をつけてください。その後は自由にオフラインでも作業を続けても平気です。手動で依存ファイルを手に入れる方法に関して知りたい場合は、dub のドキュメントをご覧ください。

## インストール方法
コンパイル済みのゲームをインストールするには OS の固有スクリプトを実行出来ます。

### Unix系 (install.sh)
Unix系のインストールスクリプトは Bourne Shell 付幾どの OS に対応しています。ワーキングディレクトリーをプロジェクトディレクトリーに設定したそのままで実行すればインストール出来ます。

デフォールト設定によってバイナリーは /usr/local/games に、リソースは /usr/local/share/OpenTaiko にインストールされます。インストール地を変更するには以下の環境変数をセットしてください。なお、アンインストール時のために、その変数をファイルに保存するのをお勧めします。

```
echo "export OPENTAIKO_BINARY_INSTALLDIR=/home/gtensha/bin" > install-variables  
echo "export OPENTAIKO_RESOURCE_INSTALLDIR=/home/gtensha/share/OpenTaiko" >> install-variables  
source install-variables  
./install.sh
```

上のコマンド列はホームディレクトリーに例えのインストールを行います。ラーンチャやコマンドラインからの実行出来るために、バイナリーを必ず PATH 変数が当るディレクトリーにインストールしてください。

アンインストールするには同じ環境変数で --uninstall のフラグを付いてスクリプトを実行してください。

```
source install-variables  
./install.sh --uninstall
```

### Windows (install.bat)
スクリプトを実行すればゲームはデフォールトに %LOCALAPPDATA%\\Local\\.opentaiko にインストールされます。スタートメニューにショートカットが作られます。

インストール地を変るにはスクリプトをエディットして、好きな値に設定してください。

現在スクリプトでアンインストール出来ませんが、必要とはインストールディレクトリーとスタートメニューのショートカットを削除に過ぎません。

## プレイ方法
OpenTaiko はキーボードで遊べます。コントローラのサポートは計画中です。一人だけではなく、同じキーボードで (PC に接続されてる他のキーボードでも OK) 複数人と同時に遊ぶこともできます。

### キーボードの使い方
ドラムを叩くにはキーボードを使います。マウスはサポートしていません。

メニューを動かすには矢印キーを使います。ENTER キーを押すと決定し、ESC キーで前のメニューに戻ります。タイトル画面まで戻りさらにもう一度 ESC キーをおすとゲームを終了します。メニューを選択するには TAB を押します。

数の値を調整するには矢印キーを押して値を変って、ENTER を押して加える値を変更出来ます。メニューから戻るように、ESCAPE を押して決定します。

遊ぶ時にプレイヤー 1 の叩くキーはデフォールト [D F J K] に設定されています。D は左カッで、F は左ドンと言う感じになります。プレイヤー 2 の場合は [End PageDown Numpad8 Numpad9] に設定されています。

#### キーを変更する
キーを変更するには「プレイヤー」メニューに移動して、「キーマップを設定する」オプションを選択します。キーを追加したい場合は ESC 以外いずれかのキーを押すと、そのキーが設定されます。

キーの設定は _keybinds.json_ に登録しています。このファイルはテキストエディタで変更しても平気です。設定は選択したナンバーのプレイヤーのみ有効です。

プレイヤーのキーを再設定する場合は、「プレイヤー」メニューから行えます。

### プレイヤーを追加する
始めに「Player」のプレイヤーを選択します。他のプレイヤーを登録するには、「プレイヤー」メニューに移動して、「プレイヤーを選ぶ」オプションを選択します。その後は登録されたプレイヤーから選べます。新しいプレイヤーを登録することもできます。プレイヤーを追加すると、遊ぶ時に各プレイヤーがプレイヤーエリアが現れて、同時に遊べます。遊んでいるプレイヤーは右上に表示されます。

「プレイヤーを削除する」オプションはプレイヤーを現在の演奏から削除できます。登録されたプレイヤー一覧からは削除しません。

プレイヤー一覧は _players.json_ に登録されています。そちらも、テキストエディタで変更を行っても平気です。

### 曲を追加する
曲を追加するには自分でゲーム譜面を作るか、誰かが創作した譜面を手に入れます。また、他のゲームから譜面をインポートすることもできます。

#### ゲーム譜面の制作
制作機能は実装中です。手間はかかりますが、手で制作できます。やり方は、maps ディレクトリにある見本を参照してください。

制作したゲーム譜面を追加するには、そのマップのディレクトリを maps にコピーするだけです。

#### ゲーム譜面をインポートする
.osz ファイルからゲーム譜面をインポートすることができます。自動的にその中にある beatmap をOpenTaiko の譜面ファイルに変更して、ffmpeg が利用可能なら mp3 も ogg に変更します。ffmpeg を持ってない場合、ゲーム中に音楽が再生できない可能性があります。インポート後に .osz は消しません。

インポートするには「設定」メニューから「マップをインポートする」のボタンを押してください。

### ゲーム設定
「設定」メニューでは、言語を設定したり vsync モードをセットすることができます。画面解像度を設定するには _settings.json_ のファイルを編集して、「resolution」を好きな値に変更します。

タイミング変数以外の設定を反映するためには、ゲームを再起動する必要があります。

#### タイミング変数
タイミングに関して四変数が調整出来ます。全てがミリ秒です。

* **音楽・叩きのタイミング** - 音楽再生とドラムのタイミングが違っている場合はこの変数でカバー出来ます。
* **可ヒットゾーン** - Xミリ秒の間に遅くて早くて可のヒットが貰えます。別々に当る値なので、100ms に設定したら全 200ms の間になります。
* **良ヒットゾーン** - 可ヒットゾーンと同じよう、最高のポイントを貰える間の値です。
* **叩ける寸前のアウト確定ゾーン** - 可ヒット前、この間にドラムを叩いたらアウトです。無茶な叩きを罰する為です。

### ゲームをカスタマイズする
ロードされるリソースがカスタマイズ出来ます。ユーザーのカスタムのリソースディレクトリーにオリジナルと同じ名前のファイルをコピーしたら、カスタムのファイルがオリジナルの代わりにロードされます。デフォールトは assets/custom に設定していますが、変るには settings.json の "assets" フィールドをエディットしてください。

### 遊び方
ドラムが打つ場所にきたら、キーボードを正しいタイミングで叩きます。赤はドラムの真ん中のキーで、緑はドラムは周りのキーで叩きます。右や左のボタンのどっちでも OK です。タイミングが良ければスコアもよくなります。リズムをよく聞いて叩くのがコツです！

開発が進むともっとゲームの機能が追加されます。

# 開発のゴール
どんなマシンを使っても遊べる音ゲーになること。

同じマシンでもネットでもマルチプレイヤー機能があって、楽しくて簡単にできること。

同じ感じのゲームからマップのインポートができたり、簡単にテキストファイルを変更してマップ作成できたりすること。

コードに対して誰でも簡単に変更を加えられるように、ソースコードが読みやすくて実行しやすいこと。直したり追加したいことがたくさんあるので、コントリビューションをいつでも受け付けています。

OpenTaiko は GNU GPLv3 のフリーソフトため、すべてをフリーソフトままで配信できるように、フリーな共有ライブラリを使い続けること。

# コピーライト知らせ
こちらのリポジトリに付いているファイルは、作者よりコピーライトされたものです。


## Noto fonts
**© 2010-2015, Google Corporation**

### ファイル
* assets/default/NotoSansCJK-Bold.ttc
* assets/default/NotoSansCJK-Light.ttc
* assets/default/NotoSansCJK-Regular.ttc

### ライセンス
[SIL Open Font License](assets/default/LICENSE.NotoSansCJK.txt)

### ホームページ
[GitHub リポジトリ](https://github.com/googlei18n/noto-cjk)


## 124-Taiko-Rim.wav と 123-Taiko-Open.wav
**freesound.org にて [klemmy](https://freesound.org/people/klemmy/) が投稿した録音**

### ファイル
* [red.wav](assets/default/red.wav) (123-Taiko-Open.wav)
* [blue.wav](assets/default/blue.wav) (124-Taiko-Rim.wav)

### ライセンス
[Creative Commons Attribution 3.0](https://creativecommons.org/licenses/by/3.0/legalcode)

### 基ページ
* freesound.org にて [123-Taiko-Open.wav](https://freesound.org/people/klemmy/sounds/203344/)
* freesound.org にて [124-Taiko-Rim.wav](https://freesound.org/people/klemmy/sounds/203343/)

### 変更
* アンプリファイしました
* 無音の部分を抜きました

[3]: https://github.com/DerelictOrg/DerelictSDL2
[4]: https://github.com/DerelictOrg/DerelictSFML2
