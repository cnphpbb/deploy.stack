## 部署时需要注意的

1. 本地部署  
1.1  需要空间
2. docker部署  
2.1 需要制订 
   - 存储空间 
   ```docker
    ...
    volumes
    - /data/localFS:/data
    - /videos/videos:/videos  
    ...
    ```
   - 配置文件
   2.2 alist配置  
   2.3 权限问题
3. 其他需要安装的一些扩展