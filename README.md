```bash
cat >secrets <<EOF
export AWS_ACCESS_KEY_ID=***
export AWS_SECRET_ACCESS_KEY=***
EOF

source ./secrets
```

```
terraform plan -no-color -out plan | tee plan.jso
```


```bash
export MY_AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
export MY_AWS_REGION=$(aws configure get default.region)
docker pull nginx
docker tag nginx:latest $MY_AWS_ACCOUNT.dkr.ecr.$MY_AWS_REGION.amazonaws.com/nginx:latest
aws ecr get-login-password --region $MY_AWS_REGION | docker login --username AWS --password-stdin $MY_AWS_ACCOUNT.dkr.ecr.$MY_AWS_REGION.amazonaws.com
docker push $MY_AWS_ACCOUNT.dkr.ecr.$MY_AWS_REGION.amazonaws.com/nginx:latest
```