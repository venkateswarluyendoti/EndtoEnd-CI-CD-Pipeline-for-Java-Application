''' bash 
Leanring Techniques From Project:
----------------------------------
STEP : 1
---------
We can install JDK 17 alongside JDK 21 and then switch the default Java version.

🔹 Step 1: Install JDK 17
sudo apt update
sudo apt install -y openjdk-17-jdk

🔹 Step 2: Check Installed Java Versions
update-alternatives --list java


👉 This will show both Java 21 and Java 17 paths, e.g.:

/usr/lib/jvm/java-17-openjdk-amd64/bin/java
/usr/lib/jvm/java-21-openjdk-amd64/bin/java

🔹 Step 3: Switch Default Java Version

Run:

sudo update-alternatives --config java


👉 You’ll get a menu like:

There are 2 choices for the alternative java (providing /usr/bin/java).

  Selection    Path                                           Priority   Status
------------------------------------------------------------
* 0            /usr/lib/jvm/java-21-openjdk-amd64/bin/java    1211      auto mode
  1            /usr/lib/jvm/java-17-openjdk-amd64/bin/java    1111      manual mode
  2            /usr/lib/jvm/java-21-openjdk-amd64/bin/java    1211      manual mode


➡️ Type 1 (or whichever corresponds to JDK 17) and press Enter.

🔹 Step 4: Verify Java Version
java -version


✅ Now it should show:

openjdk version "17.0.x"


👉 This way, Java 21 remains installed (in case some tools need it), but your system will use Java 17 by default for Spring Boot + Maven builds.





STEP : 2
---------
minikube installation problem:
------------------------------
ubuntu@ip-172-31-39-62:~/EndtoEnd-CI-CD-Pipeline-for-Java-Application/app$ minikube version

❌  Exiting due to HOST_HOME_PERMISSION: mkdir /home/ubuntu/.minikube/certs: permission denied        
💡  Suggestion: Your user lacks permissions to the minikube profile directory. Run: 'sudo chown -R $USER $HOME/.minikube; chmod -R u+wrx $HOME/.minikube' to fix
🍿  Related issue: https://github.com/kubernetes/minikube/issues/9165

Solution : 
----------
A classic Minikube permissions issue when Jenkins or even your user tries to access ~/.minikube.
It usually happens because Minikube was installed or started with sudo, so the $HOME/.minikube directory is owned by root instead of your normal user.

🔹 How to Fix It (Safe Way)

Run this on your EC2 instance:

sudo chown -R $USER:$USER $HOME/.minikube
chmod -R u+wrx $HOME/.minikube


chown -R $USER:$USER → Makes your user the owner of .minikube directory.

chmod -R u+wrx → Grants full read, write, execute permissions for your user.

🔹 Verify Ownership

After running above, check:

ls -ld $HOME/.minikube


✅ Expected output:

drwxr-xr-x  10 ubuntu ubuntu  4096 Aug 17 10:25 /home/ubuntu/.minikube


(ubuntu is your EC2 username, not root).

🔹 Why This Matters

Jenkins container mounts $HOME/.minikube to /root/.minikube.

If the host’s .minikube belongs to root, Jenkins (running as root inside container but mapping from your $HOME) can’t read/write it.

Fixing ownership ensures Jenkins + kubectl can talk to the Minikube cluster.

ubuntu@ip-172-31-39-62:~/EndtoEnd-CI-CD-Pipeline-for-Java-Application/app$ sudo chown -R $USER:$USER $HOME/.minikube
chmod -R u+wrx $HOME/.minikube    
ubuntu@ip-172-31-39-62:~/EndtoEnd-CI-CD-Pipeline-for-Java-Application/app$ ls -ld $HOME/.minikube
drwxr-xr-x 2 ubuntu ubuntu 4096 Aug 17 05:14 /home/ubuntu/.minikube 


STEP : 3
---------
minikube starting problem:
--------------------------
🚫  Exiting due to HOST_KUBECONFIG_PERMISSION: Failed kubeconfig update: writing kubeconfig: Error writing file /home/ubuntu/.kube/config: open /home/ubuntu/.kube/config: permission denied
💡  Suggestion: Run: 'sudo chown $USER $HOME/.kube/config && chmod 600 $HOME/.kube/config'
🍿  Related issue: https://github.com/kubernetes/minikube/issues/5714

Solution:
----------
🔹 Important Notes

Never run kubectl or minikube with sudo.

If you do, kubeconfig & cluster certs get owned by root again.

Always run as your EC2 user (ubuntu).

If you already have both .kube and .minikube directories messed up (owned by root), fix them together:

sudo chown -R $USER:$USER $HOME/.kube $HOME/.minikube
chmod -R u+wrx $HOME/.kube $HOME/.minikube


After fixing, restart Minikube:

minikube stop
minikube start --driver=docker

👉 One-shot script that fixes both .kube and .minikube ownership + permissions, so we won’t see these errors again?

# Fix ownership and permissions for .kube and .minikube

# Ensure your user owns the directories
sudo chown -R $USER:$USER $HOME/.kube $HOME/.minikube

# Set secure permissions on kubeconfig
chmod 600 $HOME/.kube/config

# Allow your user full access to minikube files
chmod -R u+wrx $HOME/.minikube

# Verify results
echo "✅ Ownership and permissions fixed!"
ls -ld $HOME/.kube $HOME/.minikube
ls -l $HOME/.kube/config

🔹 Expected Results

After running:

ls -ld $HOME/.kube $HOME/.minikube


You should see:

drwxr-xr-x  3 ubuntu ubuntu 4096 Aug 17 11:10 /home/ubuntu/.kube
drwxr-xr-x 10 ubuntu ubuntu 4096 Aug 17 11:10 /home/ubuntu/.minikube


For the kubeconfig file:

ls -l $HOME/.kube/config


You should see:

-rw------- 1 ubuntu ubuntu 12345 Aug 17 11:10 /home/ubuntu/.kube/config

🔹 After Fix

Always run Minikube as normal user:

minikube start --driver=docker


Never use sudo kubectl or sudo minikube.

Jenkins will now successfully read ~/.kube/config + ~/.minikube since we mount them into the container.


STEP : 3
---------

ubuntu@ip-172-31-39-62:~$ docker exec -it jenkins bash
root@e2b560aad349:/# curl -v http://34.204.77.57:30441
*   Trying 34.204.77.57:30441...
* Connected to 34.204.77.57 (34.204.77.57) port 30441 (#0)
> GET / HTTP/1.1
> Host: 34.204.77.57:30441
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 307 Temporary Redirect
< Content-Type: text/html; charset=utf-8
< Location: https://34.204.77.57:30441/
< Date: Sun, 17 Aug 2025 12:46:35 GMT
< Content-Length: 63
<
<a href="https://34.204.77.57:30441/">Temporary Redirect</a>.

* Connection #0 to host 34.204.77.57 left intact


Solution:
---------

The curl output shows that your Argo CD server is reachable, but it’s returning a 307 Temporary Redirect to HTTPS:

< Location: https://34.204.77.57:30441/


This means the server expects connections over HTTPS, not HTTP.

Use --insecure with HTTPS in your argocd login command:

argocd login 34.204.77.57:30441 --username admin --password <password> --insecure


Key points:

HTTPS is required (the server redirects HTTP → HTTPS).

--insecure allows login despite self-signed certificates.

Make sure Jenkins container or host can reach port 30441 via HTTPS.

💡 Optional: Test manually first from the Jenkins host:

curl -k https://34.204.77.57:30441


You should get the Argo CD login page HTML.

After that, the pipeline should be able to log in and proceed.


Output:
-------

root@e2b560aad349:/# curl -k https://34.204.77.57:30441
<!doctype html><html lang="en"><head><meta cha                                         rset="UTF-8"><title>Argo CD</title><base href=                                    "/"><meta name="viewport" content="width=devic                               e-width,initial-scale=1"><link rel="icon" type="image/png" href="assets/favicon/favicon-32x32.png" sizes="32x32"/><link rel="icon" type="image/png" href="assets/favicon/favicon-16x16.png" sizes="16x16"/><link href="assets/fonts.css" rel="stylesheet"><script defer="de-width,initial-scale=1"><link rel="icon" type="image/png" href="assets/favicon/favicon-32x32.png" sizes="32x32"/><link rel="icon" type="image/png" href="assets/favicon/favicon-16x16.png" sizes="16x16"/><link href="assets/fonts.css" rel="stylesheet"><script defer="defer" src="main.6428ac7755a7519079f9.js"></script></head><body><noscript><p>Your browser does not support JavaScript. Please enable JavaScript to view the site. Alternatively, Argo CD can be used with the <a href="https://argoproj.github.io/argo-cd/cli_installation/">Argo CD CLI</a>.</p></noscript><div id="app"></div></body><script defer="defer" src="extensions.js"></script></html>
