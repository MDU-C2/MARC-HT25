## EGM Setup

To be able to run EGM on the virtual controller, you first need to add a UDP transmission protocol and add the External motion data option for the controller. This section walks through how to do just that.

### Add External Motion

First extend the **Configuration** tab in the active station and do the following:

1. Double click **Motion**
2. Press **External Motion Interface Data**
3. Right click in the window and press **New External Motion....**

![EGMmotionAdd](/media/images/EGMmotionAdd.png)

4. In the name window enter: **EGMsensor:**
>Note: This name needs to match the **ExtConfigName** used in the **EGMSetupUC** process, located in the **EGMprocesses** module, in order to work.

5. Set the level to either **Raw** or **Filtered**
>Note: **Raw**/**Filtered** is used for **Position Guidance** (or any EGM option with position streaming). If you plan to use **Path Correction** you need to set the level option to **Path**. 

6. Select **Yes** for "Do not Restart after Motors Off"

7. Click **OK**

![EGMmotionsettings](/media/images/EGMmotionsettings.png)

### Add Transmission protocol

First extend the Configuration tab in the active station and do the following:

1. Double click **Communication**

2. Press **Transmission Protocol**

3. Right click in the window and press **New Transmission Protocol...**

![UDPadd](/media/images/UDPadd.png)

4. In the name window enter: **UCdevice**
>Note: This name needs to match the **UCdevice** used in the **EGMSetupUC** process, located in the **EGMprocesses** module, in order to work.

5. Choose type **UDPUC**

6. Remote Address: **127.0.0.1** (localhost IP address)

7. Remote port number: **6510**

8. Clocl **OK**

![UDPsettings](/media/images/UDPsettings.png)