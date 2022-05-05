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

I have tested the bash script in my environment which ran around 8 mins on t2.micro.

### Logic on rate_limit.sh
The bash script first filter the ip address to a list. Then, it process the list of ip addresses via a loop. Temporary files have been generated during the program for data processing.

There is an inner loop to calculate whether rate limit ban the ip address. First is for condition 1, 2 and 3. 

After inner-loop processing, it generated a list of pending BAN actions. Then, it starts to process BAN action calculation to determine the first BAN action, whether it keeps BAN per conditions, and when will UNBAN action occur. Example, "31/Dec/2018:23:56:56 +0800" BAN 58.236.203.13 for 10 mins. It will keep BAN if there meet the condition on the next min. It means it will not UNBAN on "01/Jan/2019:00:06:57 +0800" until it has no match on all 3 conditions.

### Testing result
```
[ec2-user@ip-172-31-19-20 test01]$ time ./rate_limit.sh TestQ1.log 
1546271816,BAN,58.236.203.13
1546277422,BAN,221.17.254.20
1546281160,UNBAN,221.17.254.20
1546285801,BAN,210.133.208.189
1546293527,UNBAN,210.133.208.189
1546297454,BAN,221.17.254.20
1546301068,UNBAN,221.17.254.20
1546310858,UNBAN,58.236.203.13

real	8m1.372s
user	6m12.014s
sys	1m31.402s
[ec2-user@ip-172-31-19-20 test01]$ 
```
[1546293527,UNBAN,210.133.208.189] has 60 sec difference with model answer [1546293587,UNBAN,210.133.208.189]

Anaysis:
```
Timestamp=1546286326,no.of /login requests past 10 min=3,BAN for 2 hour,Release time=1546293527,IP=210.133.208.189
```
BAN time from the above result is 01/Jan/2019:03:58:46 +0800.

If we use ban for 2 hours to calculate model answer BAN time. It should be 01/Jan/2019:03:59:46 +0800. However, there is no such request on raw logs. We can only find 01/Jan/2019:03:58:46 +0800 request from 210.133.208.189.
```
[ec2-user@ip-172-31-19-20 test01]$ grep 210.133.208.189 TestQ1.log | grep 2019:03:58: -A 2 -B 2
210.133.208.189 - - [01/Jan/2019:03:56:36 +0800] "GET /trending HTTP/1.1" 200 578 "" ""
210.133.208.189 - - [01/Jan/2019:03:57:03 +0800] "POST /gag/8703156 HTTP/1.1" 200 1566 "" ""
210.133.208.189 - - [01/Jan/2019:03:58:39 +0800] "POST /explore HTTP/1.1" 200 3091 "" ""
210.133.208.189 - - [01/Jan/2019:03:58:41 +0800] "GET /login HTTP/1.1" 200 1885 "" ""
210.133.208.189 - - [01/Jan/2019:03:58:46 +0800] "GET /search HTTP/1.1" 301 2005 "" ""
210.133.208.189 - - [01/Jan/2019:04:00:20 +0800] "GET /fresh HTTP/1.1" 500 2928 "" ""
210.133.208.189 - - [01/Jan/2019:04:00:26 +0800] "GET /search HTTP/1.1" 200 1956 "" ""
```
[1546301068,UNBAN,221.17.254.20] has 2 sec difference with model answer [1546301070,UNBAN,221.17.254.20]

Anaysis:
```
Timestamp=1546297467,no.of requests past 10 min=11,BAN for 1 hour,Release time=1546301068,IP=221.17.254.20
```
BAN time from the above result is 01/Jan/2019:07:04:27 +0800.

If we use ban for 1 hours to calculate model answer BAN time. It should be 01/Jan/2019:07:04:29 +0800. However, there is no such request on raw logs. We can only find 01/Jan/2019:07:04:27 +0800 request from 221.17.254.20.
```
[ec2-user@ip-172-31-19-20 test01]$ grep 221.17.254.20 TestQ1.log | grep 2019:07:04:2 -A 2 -B 2
221.17.254.20 - - [01/Jan/2019:07:04:16 +0800] "HEAD /upload HTTP/1.1" 200 2261 "" ""
221.17.254.20 - - [01/Jan/2019:07:04:17 +0800] "GET /trending HTTP/1.1" 200 1269 "" ""
221.17.254.20 - - [01/Jan/2019:07:04:26 +0800] "GET /upload HTTP/1.1" 200 1287 "" ""
221.17.254.20 - - [01/Jan/2019:07:04:27 +0800] "GET /gag/1950633 HTTP/1.1" 200 3339 "" ""
221.17.254.20 - - [01/Jan/2019:07:04:33 +0800] "GET /gag/1608993 HTTP/1.1" 200 3575 "" ""
221.17.254.20 - - [01/Jan/2019:07:04:41 +0800] "GET /explore HTTP/1.1" 200 1847 "" ""

```

### Limitation
The reason why I choose bash script is because I usually use bash script for Linux operation. But Bash script is not good to handle complex logic requirment. However, it is good for automation scripting or startup script for userdata.

### Remark
I have attached the debug log to a file called execution.log


### Contributor 

Ivan Wong (2022-May-5)