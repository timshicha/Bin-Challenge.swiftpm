
# Bin Challenge
Timofey Shichalin
October 2024

---
## Summary
This project has 2 parts:
- iPhone app
- physical system consisting of:
    - lightweight microcontroller (with WiFi)
    - two angle measuring modules

The app and the physical system work together to measure the angle at which the arm is raised relative to the ground. The system is plugged into a power source and the (severely modified) angle modules are strapped to the person's forearm and bicep. The app connects to the system's microcontroller and fetches the angles. These angles are displayed numerically along with a stick-figure preview to show what the arm looks like. The user can start a timer that will automatically stop when the angle of the arm becomes too low or too high.

---
## Inspiration
Losing sucks. Losing because a competition was ruled unfairly sucks even more.

I am currently an electical assembly technician, so we can and scrap tons of wire. A few weeks ago I walked up to my lead's table like I would do dozens of times a day. The big yellow garbage-like bin that he used for his scrap wire was sitting next to his table as usual. There were only a few wires in it, so I picked it up by one of the handles and held it in front of me. My lead came up with a brilliant idea: make a leaderboard of how long people in the company can hold the (empty) bin straight in front of them. For practicality, I attached a pipe horizontally, and the competition began.

I had the best time (just under a minute) by a sliver for about a week. Most of us held the bin straight in front of us, but I saw a few people drop their arm below 30 degrees. I argued those times shouldn't be counted. But we still had an issue: how do we judge whether the bin is too low? That's too subjective. And then, I came to work one day and saw that my record was beaten by an alledged Cross-Fitter from our office. My lead claimed that he held his arm straight, which isn't unbelievable, but I still wanted to implement a system that would serve us justice.

---
## Detailed Description
#### Physical System
The physical system consists of an [ESP32 NodeMCU-32S WiFi-supported microcontroller](https://www.amazon.com/dp/B0C8H6ZGRR?ref=ppx_yo2ov_dt_b_fed_asin_title&th=1) and two [angle sensor modules](https://www.amazon.com/dp/B0BXH9B6X1?ref=ppx_yo2ov_dt_b_fed_asin_title). The microcontroller powers the angle sensors and every x milliseconds stores the values that are returned. It provides two endpoints, one for the forearm and one for the bicep.

#### iPhone App
The iPhone app makes the data obtained by the physical system useful. Every x milliseconds, the app makes requests to the microcontroller's endpoints to fetch the values produced by the angle sensors. The values are converted from a 12-bit integer into an angle that users can understand. The state of the arm is displayed in the app along with the angles. The user can start a timer that will start running when both sections of the arm are in the green "perfect" area (ex: -5 to 5 degrees). If either section goes outside of the orange "warning" area and into the red "failure" area, the timer stops and the attempt is over.