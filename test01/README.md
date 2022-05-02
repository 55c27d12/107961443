# Test 01
This test is referring to question 1 - Rate Limiting

### Usage
```
chmod +x rate_limit.sh
./rate_limit.sh TestQ1.log
```


### Background
I have developed a bash script to take the sample log input and produce the ban/unban output.

Since I am using bash script and running on a t2.micro EC2 instance, the run time maybe longer than expectation. 

I have tested the bash script in my environment which ran around 5 mins.

### Logic on rate_limit.sh
The bash script first filter the ip address to a list. Then, it process the list of ip addresses via a loop. Temporary files have been generated during the program for data processing.

There are two inter-loop to calculate whether rate limit ban the ip address. First is for condition 1 and 2. Second is for condition 3 since condition 3 counts the requests related to /login. I have generated another data set for /login filter only for processing.

After inter-loop processing, it generated a list of pending BAN actions. Then, it starts to process BAN action calculation to determine the first BAN action, whether it keeps BAN per conditions, and when will UNBAN action occur. Example, "31/Dec/2018:23:56:56 +0800" BAN 58.236.203.13 for 10 mins. It will keep BAN if there meet the condition on the next min. It means it will not UNBAN on "01/Jan/2019:00:06:57 +0800" until it has no match on all 3 conditions.

### Testing result
```
[ec2-user@ip-172-31-19-20 test01]$ time ./rate_limit.sh TestQ1.log 
1546271816,BAN,58.236.203.13
1546277422,BAN,221.17.254.20
1546281160,UNBAN,221.17.254.20
1546285801,BAN,210.133.208.189
1546293522,UNBAN,210.133.208.189
1546297454,BAN,221.17.254.20
1546301074,UNBAN,221.17.254.20
1546307258,UNBAN,58.236.203.13

real	5m36.514s
user	4m27.730s
sys	1m6.541s
[ec2-user@ip-172-31-19-20 test01]$ 
```
I am sorry that - from the above result, all BAN are matched. However, only the first UNBAN is correct while the others are not correct. 

Example:

- 1546310858,UNBAN,58.236.203.13

The above is the UNBAN action of 58.236.203.13 where timestamp is referred to "01/Jan/2019:10:47:38 +0800". The  request is on the below.
``` 
58.236.203.13 - - [01/Jan/2019:08:47:37 +0800] "GET /trending HTTP/1.1" 200 1137 "" ""
```
I assume it has been BAN for 2 hours starting from "01/Jan/2019:08:47:37 +0800". It is not /login and it cannot trigger the action for 2 hours.

### Limitation
Why I choose bash script, it is because I usually use bash script for Linux operation. But Bash script is not good to handle complex logic requirment. However, it is good for automation scripting or startup script for userdata.

### Contributor 

Ivan Wong (2022-May-2)