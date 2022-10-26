### How to Use
This script will copy a ruby file to the running app pod in the cluster.
The ruby script will create a new admin account and organization.

*Note Make sure to create an account with a valid email address. You will need to reset the password.
***You cannot make an account with the name "admin"

1) Update the bootstrap.rb file with the username, email and organization
2) Ensure the bootstrap.sh file is executable
```
chmod +x bootstrap.sh
```
3) Run the bootstrap.sh file
```
bash ./bootstrap.sh
```
4) Once the script has been completed go to the Web UI and select "Sign In".

5) Click on "Forgot your password" to reset the password. You may now log in and begin inviting team members.

