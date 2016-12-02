模块如何接入？
1. 下载：git@git.lianjia.com:qa/se-ci.git
运行install.sh <目标路径> 即可
2. 编译配置（application.ini）
BUILD_SCRIPT: 指定编译脚本。默认为空，如PHP源码模式不需要额外编译，但JAVA和FE静态资源池必须制定；
主要枚举值：
-	java_build.sh 适用于编译java；
-	java_fe_build.sh 适用于同时编译java和fe静态资源，（兼容java_build）
-	fe_build.sh 适用于编译fe静态资源
BUILD_HOST：指定编译机器。默认为空，采用本地编译。
BUILD_USER：指定编译机器的用户授权。在BUILD_HOST非空时有效。
BUILD_PASSWD：指定编译机器的用户密码授权。在BUILD_HOST非空时有效。
BUILD_PACKAGE：指定编译模式，多个值以空格分开。默认为空，会自动和部署配置DEPLOY_PACKAGE值保持一致。
主要枚举值：
-	test：编译测试包
-	prod：编译线上包

3. 部署配置(config-xxx.ini)

4. 服务个性化配置(sed-xxx.ini) 
可选，一般应用与线下闭环，比如ci、off、link-off中外部链接动态替换，保证页面点击在一个闭环中完成。
