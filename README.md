# SDCard_NEXYS
Author : Maxime Gernet

The goal of this project is to read a raw image on a SD Card and to display it on a screen through a VGA port.\n
It is designed for the NEXYS 4.

The image format on the SD Card has to be 640*480, with 24 bits per pixel coded in RGB.\n
It is possible to store up to three images on the card, and to switch the image displayed by using the left and right buttons of the NEXYS 4.
The project has been tested with SDHC and SDSC cards.

To store an image on the SD card, follow these steps...

Step 1: If you are using windows, erase the first sector of the SD card so that windows won't recognize the file system. Otherwise,
        windows won't allow you to write directly to the card.

Step 2: Copy the raw image data to the SD card. It is possible to do it by using HxD.
        Remember the number of the first sector of the image.

Step 3: Change the value of one of the three offsets in the first process of the file FSM.vhd (line 59).
        The offset is the first sector of the image.
