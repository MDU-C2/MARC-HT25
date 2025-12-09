
<h1 align="center">
  Dishwasher Loading And Unloading Robot
  <br>
  <br>
  <img src="media/images/marc.png" alt="MARC Logo" width="400">
  <br>
  <br>
  <br>
</h1>

<h4 align="center">A robot arm with a vision system capable of picking up and placing cups. </h4>



<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#license">License</a>
</p>

![screenshot](/media/images/banner.gif)

The project aims to create a robotic system capable of dynamically locating different kinds of mugs in different orientations and correctly picking them up using a **Dual Arm YuMi**.
## Key Features

* Dynamic robot capable of picking up and placing mugs in a predefined position.

* Object awareness
  - Identifies mugs, their postion and pose.

* Components used
  - YUMI IRB14000
  - OAK-D PRO Camera
* Languages used
  - Python
  - RAPID



## Requirements
  - Python 3.11
    - OpenCV
    - DepthAI
    - Numpy
<!--
  Lägg in mer här?
-->
  - Robotstudio

## How To Use

Clone this repo , you'll need [Git](https://git-scm.com) installed on your computer. From your command line:

```bash
# Clone this repository
$ git clone https://github.com/MDU-C2/MARC-HT25.git

# Go into the repository
$ cd MARC-HT25
```
> [!Note]
> Everything in this guide was tested on windows

<!-- There are two parts to this software, the Robot side (RAPID) and the camera side (Python). Follow the [YuMi IRB 14000](/media/Guide/Yumi%20IRB%2014000/README.md) guide for how to work with the robot. [Python guide](/media/Guide/Python/README.md) for setting up Python and the camera to communicate with the robot. -->

<!-- When working with the software there are two main parts, the robot side (RAPID) and the camera side (Python).  -->

## Setting Up Python & Camera
To get started you should follow the [Python guide](/media/Guide/Python/README.md) which will go through all steps necessary for setting up the Python environment, calibrating the camera and running the Python side of the software. 

## Starting The Robot
If you need help with starting or working with the robot follow the [YuMi IRB 14000](/media/Guide/Yumi%20IRB%2014000/README.md) guide.


## License

MIT

---




## Other

Readme template by Amit Merchant