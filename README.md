remote
======
让你可以同时在多台远程机器上执行你指定的命令.


安装
===
1. git clone https://github.com/ahei/remote
2. 执行`cd remote && ./install.sh`


前提和原理
--------
remote命令原理很简单, 就是for循环ssh到每台机器上执行命令, 所以使用该命令的前提是当前机器必须和每台机器增加免密码输入, 否则你会累死...


使用方法
------
```
remote 可选选项 机器列表 命令
```

机器列表有三种指定办法:

* 提供集群名, 集群配置文件为/etc/remoterc和~/.remoterc, /etc/remtoerc为全局配置文件, 当同一个集群同时出现在全局配置文件和用户配置文件中时, 优先使用用户配置文件. 
  上述配置文件其实都是shell脚本, 集群名为shell变量, 比如 redis=“redis0 redis1 redis2”, 则表示集群redis有三台机器组成. 该办法是比较方便的最常用的指定机器列表的方法.
* -f 机器列表文件
* -H 机器列表字符串

到远程机器上执行命令时会先cd到当前机器所在的目录, 所以如果想看别的机器上同目录下是否有同样的文件非常简单: 先在本机器上cd到指定目录, 然后执行 remote cluster ls file即可.

命令可以包含参数, 带参数的命令可以不用引号引用起来, 比如: remote redis ls -l test.sh

由于命令可能会包含选项, 所以给remote指定的选项必须紧接着remote后面.


常用选项
------
* -l 登录用户, remote -l work redis date, 以work用户身份运行date命令. 不提供该选项时默认以当前用户去别的机器上执行命令
* -n 不运行命令, 只是打印将要执行的命令, 调试用
* -q 不打印要执行的命令
* -g 默认所有机器的命令同时并行在后台执行, 该选项告诉remote串行执行命令
* -N 如果本台机器也在指定的机器列表里面, 不执行本机器上的命令. 有时候想先在本机上试试要执行的命令,   然后再批量在其他机器上执行, 这时候该选项就很有用. 比如小流量时该选项就很有用
* -t 秒数 在准备到下一台机器上执行命令之前先sleep这么长时间. 该选项实现了波浪式部署
* -c 拷贝文件模式, 参考下面的rcp命令介绍
* -P remote打印命令执行结果时, 为了好区分, 会把机器名作为前缀打印出, 但这对于对这些命令结果的后续用其他命令处理可能不太方便, 这个选项告诉remote不要打印机器名前缀

其他不常用的选项可以通过remote -h查看



rcp
===
拷贝本地机器上的文件到多台远程机器上.


使用方法
------
```
rcp 机器列表 本地文件 远程文件(可选)
```
本地文件可以是目录或者文件, 也可以是相对文件名, 也可以是绝对文件名, 远程文件也是这样, 不提供远程文件时, 默认和本地文件名相同.

rcp其实是remote命令的alias, alias rcp='remote -c'

例子:

1. rcp reds relative_local_file
2. rcp reds relative_local_file remote_file
3. rcp reds /path/to/absolute/local_file



rgrep
=====
在多台远程机器上执行grep


使用方法
------
```
rgrep 可选选项 机器列表 PATTERN 待grep的文件(可选)
```
如果没有指定待grep的文件, 将会从配置文件/etc/rgreprc和~/.rgreprc中读取, 优先使用~/.rgreprc, 配置文件语法如下:

```
clusterFiles=([redis.*]=/data/logs/redis.log.%Y%m%d%H
             [php.*]=/data/logs/php.log.%Y-%m-%d.%H)
```
配置文件中需要配置shell hash数组变量`clusterFiles`, 该hash数组的key为集群名的pattern, 只要集群名完全匹配key, 就会把它的value当做待grep的文件, 
value中可以包含和date命令中一样的指定日期的语法, 这样可以使用rgrep中控制日期的选项来搜索不同的日期文件.

常用选项
------
* -h HOUR  指定grep哪个小时的文件
* -d DAY   指定grep哪天的文件
* -D DAY   指定grep哪天整天的文件
* -m MONTH 指定grep哪个月的文件

  不指定日期的话默认搜索当月当天当前小时的文件, 只指定某项的话其他项还是使用当时的日期, 比如-h 13, 那么会grep当月当天的13小时的文件, -d 13会grep当月13号的当前小时的文件.

  不管你的文件名中日期格式是两位数格式还是一位数格式, 比如2号, 是02或者2这种写法, 用上述选项的时候都不用考虑这些, 直接写2就行.

  指定的日期或者时间还可以是负数, 表示几个月前/几天前/几小时前的意思, 比如-h -1表示上个小时, -d -2表示两天前, -m -3表示三个月前.

  例子(假如当前时间为2016041720):

  1. -d 12 表示搜索2016041220的文件
  2. -D 13 表示搜索20160413全天的文件
  3. -m -1 -d -2 -h 4 表示搜索2016031504的文件

* -B 文件中的时间开始标识
* -E 文件中的时间结束标识

  如果想根据时间排序搜索出来的结果, 可以设置上述两个选项, 比如一般日志文件中时间是这样的: [2016-04-17 00:00:00.547], 那么就可以这样设置: `-B "[" -E “]”`

* -k INDEX 表示按第INDEX个字段进行排序
* -S 不根据时间排序搜索结果
* -C 默认会高亮搜索结果, 该选项关闭高亮显示
* -l 只搜索当前机器上的文件
* -g 设置grep的选项
* -n 不运行命令, 只是打印将要执行的命令, 调试用

其他不常用的选项可以通过rgrep -h查看


lgrep
=====
`alias lgrep='rgrep -B "[" -E "]" -o “-q”’`
lgrep是rgrep的alias, 用来更方便的搜索日志文件



rls
===
在多台远程机器上执行ls命令

`rls 可选选项 集群名 文件 ls选项(可选)`

`rls redis test.sh`



rps
===
在多台远程机器上执行ps然后grep命令

`rps 可选选项 集群名 PATTERN`

`rps redis crond`



psgrep
======
ps -ef | grep PATTERN



netgrep
=======
netstat -nap | grep PATTERN
