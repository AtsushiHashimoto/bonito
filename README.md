# bonito
a wrapper of docker for academic laboratories.

# What can we do with bonito?
You can copy a well set-up virtual machines for each student/project with 1 liner command:  
```% bonito create -u <<student_name>> [-p <<project_name>>]```

The student run the machine with:  
```bonito run -u <<student_name>> [-p <<project_name>>]```

If your server has user account for each student, then '-u' option can be skipped.  
Namely, following command is enough to create/log-in the virtual machine.
```
bonito create
bonito run
```

# Configuration for each linux user
Add following command to ~/.bashrc  
```
export PATH="$PATH:/<<where you put bonito>>/bin"  
eval $(bonito init)
```
   
# How to Install

