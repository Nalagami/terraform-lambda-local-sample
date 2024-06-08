# terraform-lambda-local

## what's this?
terraform で lambda 関数をローカルで実行するためのサンプル


## how to setup
- aws cli
- sam
- terraform
- docker

## how to use
- py_build.sh に実行権限をつける
- 以下のコマンドでbuildする
- このオプションは相対パスでビルドを実行すると、参照先が変わってしまうバグに対処するためのもの
- Make Failed が起きた時の対処方法

```bash
cd terraform
sam build --hook-name terraform --beta-features --terraform-project-root-path ./../
# 起動
sam local start-api --hook-name terraform
# apiのテスト
curl http://{表示されたローカルホスト}:{表示されたポート}/example
# ※remote環境では {ステージ名}/example になる
```

## 参考

https://dev.classmethod.jp/articles/2022-11-aws-sam-cli-terraform-support-lambda-local-testing-debugging/

https://github.com/aws/aws-sam-cli/issues/4724


