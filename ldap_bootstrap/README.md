### How to Use

#### Create an Admin User account

This script will copy a ruby file to the running app pod in the cluster.
The ruby script will create a new admin account and organization.

#### *Note: Make sure to create an account with a valid email address. You will need to reset the password.
#### **Note: You cannot make an account with the name "admin"

1) Update the bootstrap.rb file with the username, email and organization.

Example
```
username="bsoper"
email="bradley.soper@cnvrg.io"
organization="cnvrg"
```

2) Ensure the bootstrap.sh file is executable
```
chmod +x bootstrap.sh
```
3) Run the bootstrap.sh file
```
bash ./bootstrap.sh
```
4) Select Option 1 to create the admin user.

5) Once the script has been completed go to the Web UI and select "Sign In".

6) Click on "Forgot your password" to reset the password. You may now log in and begin inviting team members.


#### Change the Internal Registry

1) Add your registry using the Web UI.

2) Update the change-registry.rb file with the organization and your new registry url.

Example
```
repourl="docker.io/cnvrg"
organization="cnvrg"
```

3) Run the bootstrap.sh script and select Option 2.
