#!/bin/sh

git config --global user.name "shixiaoqiang"
git config --global user.email "shixiaoqiang@lianjia.com"

ssh-keygen -t rsa -C "shixiaoqiang@lianjia.com"
cat ~/.ssh/id_rsa.pub 
