## i2c python3 

1. 必须安装
```shell
apt install -y fonts-wqy-microhei fonts-wqy-zenhei
apt install -y i2c-tools libgpiod-dev
apt install -y python3-pip python3-pil python3-libgpiod
pip3 install adafruit-circuitpython-ssd13060 --break-system-packages
```
2. 调试

```shell
python3 ./status.py
```
3. rc-local

```shell
vim /etc/rc.local
# 在 exit 0 之前添加
python3 /home/yong/i2c.py/status.py &
```


