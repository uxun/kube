# Dashboard

> Versioning support
>
> Dashboard 1.10.1 version 
>
> kubernetes 1.13.x version 

参考[官方文档](https://github.com/kubernetes/dashboard)

1. 增加了通过`api-server`方式访问dashboard
2. 增加了`NodePort`方式暴露服务，这样集群外部可以使用 `https://NodeIP:NodePort` (注意是https不是http，区别于1.6.3版本) 直接访问 dashboard。

## 1.Install

``` bash
# 部署dashboard 主yaml配置文件
$ kubectl apply -f /etc/ansible/manifests/dashboard/kubernetes-dashboard.yaml
# 创建可读可写 admin Service Account
$ kubectl apply -f /etc/ansible/manifests/dashboard/admin-user-sa-rbac.yaml
# 创建只读 read Service Account
$ kubectl apply -f /etc/ansible/manifests/dashboard/read-user-sa-rbac.yaml
# [可选]部署基本密码认证配置，使用apiserver 方式访问需要
$ kubectl apply -f /etc/ansible/manifests/dashboard/ui-admin-rbac.yaml
$ kubectl apply -f /etc/ansible/manifests/dashboard/ui-read-rbac.yaml
```

## 2.Validation

``` shell
# 查看pod 运行状态
$ kubectl get pod -n kube-system | grep dashboard
kubernetes-dashboard-7c74685c48-9qdpn   1/1       Running   0          22s

# 查看dashboard service
$ kubectl get svc -n kube-system|grep dashboard
kubernetes-dashboard   NodePort    10.68.219.38   <none>        443:24108/TCP                   53s

# 查看集群服务
$ kubectl cluster-info|grep dashboard
kubernetes-dashboard is running at https://192.168.1.1:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

# 查看pod 运行日志
$ kubectl logs kubernetes-dashboard-7c74685c48-9qdpn -n kube-system
```

+ 由于还未部署 Heapster 插件，当前 dashboard 不能展示 Pod、Nodes 的 CPU、内存等 metric 图形，后续部署 heapster后自然能够看到

### 访问控制

因为dashboard 作为k8s 原生UI，能够展示各种资源信息，甚至可以有修改、增加、删除权限，所以有必要对访问进行认证和控制，本项目部署的集群有以下安全设置：详见 [apiserver配置模板](../../roles/kube-master/templates/kube-apiserver.service.j2)

+ 启用 `TLS认证` `RBAC授权`等安全特性
+ 关闭 apiserver非安全端口8080的外部访问`--insecure-bind-address=127.0.0.1`
+ 关闭匿名认证`--anonymous-auth=false`
+ 补充启用基本密码认证 `--basic-auth-file=/etc/kubernetes/ssl/basic-auth.csv`，[密码文件模板](../../roles/kube-master/templates/basic-auth.csv.j2)中按照每行(密码,用户名,序号)的格式，可以定义多个用户

新版 dashboard可以有多层访问控制，首先与旧版一样可以使用apiserver 方式登陆控制：

+ 第一步通过api-server本身安全认证流程，与之前[1.6.3版本](dashboard.1.6.3.md)相同，这里不再赘述
+ 第二步通过dashboard自带的登陆流程，使用`Kubeconfig` `Token`等方式登陆

**注意：** 如果集群已启用 ingress tls的话，可以[配置ingress规则访问dashboard](ingress-tls.md#%E9%85%8D%E7%BD%AE-dashboard-ingress)

## 3.Login

> 支持两种登录方式：Kubeconfig、令牌(Token)
>

### 令牌登录（admin）

选择“令牌(Token)”方式登陆，复制下面输出的admin token 字段到输入框

``` bash
# 创建Service Account 和 ClusterRoleBinding
$ kubectl apply -f /etc/ansible/manifests/dashboard/admin-user-sa-rbac.yaml

# 获取 Bearer Token，找到输出中 ‘token:’ 开头那一行
$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

### 令牌登录（只读）

选择“令牌(Token)”方式登陆，复制下面输出的read token 字段到输入框

``` bash
# 创建Service Account 和 ClusterRoleBinding
$ kubectl apply -f /etc/ansible/manifests/dashboard/read-user-sa-rbac.yaml

# 获取 Bearer Token，找到输出中 ‘token:’ 开头那一行
$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep read-user | awk '{print $1}')
```
### Kubeconfig登录（admin）

Admin kubeconfig文件默认位置：`/root/.kube/config`，该文件中默认没有token字段，使用Kubeconfig方式登录，还需要将token追加到该文件中，完整的文件格式如下：

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdxxxxxxxxxxxxxx
    server: https://192.168.1.2:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: admin
  name: kubernetes
current-context: kubernetes
kind: Config
preferences: {}
users:
- name: admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRxxxxxxxxxxx
    client-key-data: LS0tLS1CRUdJTxxxxxxxxxxxxxx
    token: eyJhbGcixxxxxxxxxxxxxxxx
```

- Kubeconfig登陆（只读）
首先[创建只读权限 kubeconfig文件](../op/readonly_kubectl.md)，然后类似追加只读token到该文件，略。

### 参考

- 1. [Dashboard Access control](https://github.com/kubernetes/dashboard/wiki/Access-control)
- 2. [a-read-only-kubernetes-dashboard](https://blog.cowger.us/2018/07/03/a-read-only-kubernetes-dashboard.html)

------



## 自定义创建Dashboard CA

##### 1. 手动创建 Dashboard 授权证书 (用户证书) 与 SA 无关 （不创建，集群自动创建）

```shell
$ (umask 077; openssl genrsa -out dashboard.key 2048)
#需要当前集群ca签证
$ openssl req -new -key dashboard.key -out dashboard.csr -subj "/O=uxun/CN=www.uxun.com"
$ openssl x509 -req -in dashboard.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out dashboard.crt -days 36500
#将dashboard.csr,dashboard.key 创建 secret
$ kubectl create secret generic dashboard-cert -n kubesystem --from-file=dashboard.crt=./dashboard.crt --from-file=dashboard.key=./dashboard.key 
#查看
$ kubectl get secret | grep dashboard-cert

```

##### 2. 通过kubeconfig 认证

> TOKEN=$(kubectl get secret def-ns-admin-token-44k7c -o jsonpath={.data.token} | base64 -d)

```shell
#
$ kubectl config set-cluster kubernetes --certificate-authority=./ca.crt --server="https://172.20.0.70:6443" --embed-certs=true --kubeconfig=/root/def-ns-admin.conf
$ kubectl config set-credentials def-ns-admin --token=$TOKEN --kubeconfig=/root/def-ns-admin.conf
$ kubectl config set-context def-ns-admin@kubernetes --cluster=kubernetes --user=def-ns-admin --kubeconfig=/root/def-ns-admin.conf
$ kubectl config use-context def-ns-admin@kubernetes --kubeconfig=/root/def-ns-admin.conf


```

