\> 感谢支持`AXWebViewController`，希望大家一起构建优秀的开源框架！你的问题对我来说很重要！

\>

\> **提问**: 如果你有任何问题，欢迎`email`我：`devedbox@qq.com` 或者加入我的开源项目qq群：`481867135`

\>

\> **需求**: 只需要填写以下前两条内容.

\>

\> **Bugs**: 为了尽快帮助你解决问题，请描述你的问题和问题复现的步骤.

\>

\> 谢谢帮助我帮助你们! :-)

\>

\> 提交issue之前，请移除以上内容.

\## 目标

你想达到的目标，或者说你想实现的功能的效果或者预期的结果？

\## 预期的结果

你预期会产生的结果？

\## 实际的结果

实际上使用产生的结果？ 

比如：崩溃的控制台打印

\## 问题复现的步骤

issue复现所需的步骤，尽量详细！

\## 示例代码

提供一个突出问题的代码示例或测试用例.  对于量较大的代码示例，链接到外部的`gists/repositories`是首选. 需要保密的话通过邮件`devedbox@qq.com`分享，邮件主题写issue的名称. 问题严重的话可以提供完整的`Xcode`工程最好！

\## AXWebViewController和工具的版本

```shell
echo "\`\`\`
$(sw_vers)

$(xcode-select -p)
$(xcodebuild -version)

$(which pod && pod --version)
$(test -e Podfile.lock && cat Podfile.lock | sed -nE 's/^  - (Realm(Swift)? [^:]*):?/\1/p' || echo "(not in use here)")

$(which bash && bash -version | head -n1)

$(which carthage && carthage version)
$(test -e Cartfile.resolved && cat Cartfile.resolved | grep --color=no realm || echo "(not in use here)")

$(which git && git --version)
\`\`\`" | tee /dev/tty | pbcopy
```

复制以上内容到`终端`回车，就可以获取到版本信息. 获取到版本信息之后，请将以上脚本删除！

AXWebViewController版本: ?

Xcode版本: ?

iOS/OSX版本: ?

依赖管理工具(cocoapods)版本: ?