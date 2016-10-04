Enable HiDPI on OS X
============

Hola, this is an ongoing project targets at enable the support of HiDPI for display with a high resolution under OS X(10.9, 10.10, 10.11). AFAIK, there is various way to patch/force the HiDPI mode, however, I want to create a more precise and clean way to patch the system. That's why I start to build this project. 

I know there's still long way to go, but this time, I want to share this patch ASAP. All the suggestions are welcome. I just added a new function(or say more precisely, a more complete script) which can add as much as HiDPI resolutions you want at the same time. Wish you will enjoy! lighting/syscl/Yating Zhou :-)

How to use?
----------------
Download the latest enable-HiDPI.sh by entering the following command in a terminal window:

``` sh
curl -o ~/enable-HiDPI.sh https://raw.githubusercontent.com/syscl/Enable-HiDPI-OSX/master/enable-HiDPI.sh
```


This will download enable-HiDPI.sh to your home directory (~) and the next step is to change the permissions of the file (add +x) so that it can be run.
 
``` sh
chmod +x ~/enable-HiDPI.sh
```


Run the script in a terminal window by:

``` sh
~/enable-HiDPI.sh
```

Once you finish injecting the HiDPI values, reboot your OS X and use Retina Menu Display to choose the resolution you want.

Change Log
----------------
2016-10-4

- Fixed Artoria2e5's typo credit @jqqqqqqqqqq

2016-10-1

- Fixed variable errors/typo, fully support for 4K display credit @Artoria2e5.

2016-7-30

- Optimised message display, more precise and easier to read credit @transtone.

2016-5-24

- Fixed major bug.
- Optimised code.

2016-5-23

- Fixed logical issue that causes backup failure.
- Optimised code.

2016-5-22

- Added multi monitors/displays support credit @liusunpan see issue #4.
- Optimised code.

2016-3-4

- Fixed a logical problem that casue the enable failure. Tested sucessfully on my HP 2009f @1600x900(now it can be switched to 1366x768, 1440x810.)

2016-3-3

- You can use the enable-HiDPI.sh directly to fully enable HiDPI on your OS X.

- Note: This is the first version of enable-HiDPI, I just tested it on 10.11.3, more function will be added late. If you find bugs please let me know through the "Issuses" tab.

////
