<h1 align="center">
  <br>
  <br>
  <img src="../../../media/images/python-3.svg" alt="MARC Logo" width="400">
  <br>
  <br>
  Camera & Python guide
  <br>
</h1>

## Installation

You need to install [Python 3.11](https://www.python.org/downloads/release/python-3110/)

In the installer check the box to add Python to the PATH.


Next step is to set up a virtual Python environment.
>[!Note]
> Make sure you are in the MARC directory when creating the virtual Python environment
```bash
# Create a virtual environment with Python 3.11 (Python 3.11 is needed for some libraries used)
> py -3.11 -m venv .venv

# Activate the virtual environment (make sure you are in the folder with the .venv when doing this)
> .venv\Scripts\activate
```

## Requirements
To run the codes provided in this repository multiple Python libraries needs to be installed. These are:

* OpenCV
* DepthAI
* Numpy

This is done by running the **requirements.txt** file located in the **Vision_System** folder included in the Git repository.

```bash
#Go to the correct directory
> cd Python\Vision_System
#Run the requirements.txt file
> pip install -r requirements.txt
```
Now the setup is complete and you should be able to run the code by following this [walkthrough](/media/Guide/Python/running_code.md).
