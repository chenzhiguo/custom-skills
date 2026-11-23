---
name: fake-site
description: >-
  Use when a VLESS REALITY inbound should look like a normal personal website to browsers, when replacing a stolen REALITY dest such as www.amd.com:443 or www.microsoft.com:443, or when the user asks for a 伪装站点, fake site, fallback site, x-ui target, or 127.0.0.1:8443. Triggers include a stock nginx welcome page or the domain printed on the camouflage page.
---

# fake-site

浏览器看到的站点是 REALITY 回落，不是第二个 443 监听。xray 继续占 `*:443`。没有合法握手的 TLS 被转到本机 `127.0.0.1:8443`，由 nginx 用该域名的真实证书返回个人页。

不要装宝塔。不要把 nginx 绑到公网 443。不要把 8443 绑到 `0.0.0.0`。

## 顺序

1. 确认域名已经解析到这台机器，且外网能连 80 和 443。先备份 x-ui 数据库和 `config.json`。
2. 只装 apt 的 `nginx` 和 `certbot`。关掉默认站点。
3. 先只开 80：`/.well-known/acme-challenge/` 用 webroot 提供，其余 301 到 `https://域名`。用 HTTP-01 申请证书。不要用 TLS-ALPN-01，443 已被 xray 占用。
4. 再加 `listen 127.0.0.1:8443 ssl`。证书用 `/etc/letsencrypt/live/域名/`。`nginx -t` 后 reload。
5. 本机证明回落可用后，才改 xray：`curl -sk --resolve 域名:8443:127.0.0.1 https://域名/` 必须返回个人页。
6. 在 x-ui 里只改这一条 VLESS 入站，然后重启 **x-ui**，让它从数据库重写 `config.json`。只改 `config.json` 会被覆盖。
7. 从外网 `curl https://域名/`，正文必须含站点名，证书 CN/SAN 必须是该域名。

## x-ui 字段

面板上的「目标网站 / Dest」在数据库里是 `realitySettings.target`，不是 `dest`。改成 `127.0.0.1:8443`。`serverNames` 只留这个域名。不要留被盗用的 `amd.com` / `microsoft.com` 名单，留着也不能保住旧客户端。

不要改端口、UUID、privateKey、shortIds、xhttp path/mode，也不要改 `clients.flow` 或 `flow_override`。Hysteria 和面板端口不要动。

mihomo 可以使用面板里原有的 `xtls-rprx-vision`。不要因为 Xray 官方客户端在 xhttp 上拒绝 vision，就去清 flow。验收客户端用 mihomo，不用 Xray 官方客户端。

入站 `decryption` 不是 `none` 时，客户端必须用订阅里的 encryption。填 `none` 时传输层能起来，但服务器不会向目标拨号。

## 页面

一页静态 HTML 就够。站点名要像人名或文集名，不要用主机名、机器别名或域名。HTML 里不要出现域名。不要用 nginx 默认欢迎页；200 加 “Welcome to nginx” 不算完成。

旧客户端的 SNI 必须改成这个域名。地址、端口、UUID、公钥、shortId、xhttp 参数不变。

## 验收

| 检查 | 通过 |
| --- | --- |
| `ss` 里 8443 | 只在 `127.0.0.1` |
| `ss` 里 443 | 仍是 xray |
| 外网 `https://域名/` | 200，正文有站点名，没有域名 |
| 证书 | CN/SAN 是该域名 |
| `config.json` | target/dest 为 `127.0.0.1:8443`，serverNames 只有该域名 |

## 常见错误

| 借口 | 事实 |
| --- | --- |
| 默认欢迎页就够 | 那是占位页，不像个人站 |
| 清掉 vision flow 才能连 | mihomo 带 `xtls-rprx-vision` 可以连，不要改 flow |
| 只改 config.json 更快 | 重启 x-ui 会用数据库覆盖 |
| 留着原 serverNames 能兼容旧客户端 | 回落证书已经不是那个站，旧 SNI 不会通 |
| 先改 xray 再申请证书 | 切换时空窗里回落是空的 |
