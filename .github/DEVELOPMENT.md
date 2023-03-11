## Actions secrets

| 名称 | 说明 | 默认值 | 必须 |
| ---- | ---- | ------ | ---- |
| DOCKERHUB_USERNAME | DockerHub用户名 |  | 是 |
| DOCKERHUB_TOKEN | DockerHub Api token |  | 是 |
| ENABLE_WATCH_MDCX_RELEASE | 是否监控新版应用 | true | 是 |
| MY_GITHUB_TOKEN | Github personal access token, 勾选`workflow` |  | 是 |
| ENABLE_TG_NOTIFICATION | 是否发送TG通知 | false | 是 |
| TELE_BOT_TOKEN | TG Bot token |  | 否 |
| TELE_CHAT_ID | TG 通知接收会话ID |  | 否 |

## Actions variables
| 名称 | 说明 | 默认值 | 必须 |
| ---- | ---- | ------ | ---- |
| MDCX_LATEST_TIME | 应用发布时间 | 2023-03-08T14:33:08Z | 是 |
| MDCX_LATEST_VERSION | 应用版本 | 20230308 | 是 |
