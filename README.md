# Video Capture AT91

Video Capture AT91 is a collection of scripts that can be used to configure
AT91 video capture devices.

1 Requirements
================================================================================

## 1.1 Shell scripts

Scripts are written in shell, can be run using the standard _sh_ shell.

2 Usage
================================================================================

Scripts can be run directly from command line.
The root file system dedicated to a specific target board should only
install the specific board scripts.
The scripts are held in a \<MPU\>/\<sensor\>/ directory tree.

3 Contributing
================================================================================

To contribute to video-capture-at91 you should submit the patches for review to
the github pull-request facility directly.
Linux4SAM Website:

https://www.linux4sam.org

Linux4SAM Github repository, with interface for opening issues and pull requests:

https://github.com/linux4sam

Microchip Linux for MPUs Forum:

https://www.microchip.com/forums/f542.aspx

Maintainers:

Eugen Hristev <eugen.hristev@microchip.com>

When creating patches insert the [video-capture-at91] tag in the subject,
for example use something like:

    git format-patch -s --subject-prefix='video-capture-at91][PATCH' <origin>

9 License
================================================================================

Video-capture-at91 is licensed under the MIT license.

License text file is available under LICENSES directory in the source code tree.

-End-
