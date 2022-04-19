# Oliver's customized keyboard layouts (xkb version)

## xkb version (X11) of `kbdus_xx` (`us_ext`)

This one I have tested on Kubuntu 12.04 and lately on Linux Mint 18.1 and 19 (which are based on Ubuntu 16.04 and 18.04 respectively). There are lots and lots of resources on how to do it on Ubuntu, but I ended up with different steps anyway in the end. Regardless, [this article](http://michal.kosmulski.org/computing/articles/custom-keyboard-layouts-xkb.html) was probably the single-most useful one in the process. Mind the fact that it has a resource section at the bottom, pointing to further useful resources.

Unlike the Windows version which is a keyboard layout in its own right, the way X11 and `xkb` work allows us to *extend* existing definitions. This is much more convenient and also allows for a more readable way of expressing this. I call it `us_ext`.

![Full layout](../images/us_ext.png)

Find it under `./X11`.

### Installation on Kubuntu 12.04, Linux Mint 18.1 and 19 (Ubuntu 16.04 and 18.04)

Since I was unable to install the layout in the way described on the linked page, here's how to install it on Kubuntu 12.04 or Linux Mint 18.1 (and presumably Ubuntu 16.04).

Files to modify:

* `/usr/share/X11/xkb/symbols/us_ext`
* `/usr/share/X11/xkb/rules/evdev.lst` (and _optionally_ `/usr/share/X11/xkb/rules/xorg.lst`)
* `/usr/share/X11/xkb/rules/evdev.xml`

First thing is to copy the `us_ext` file from this repository into `/usr/share/X11/xkb/symbols/`. E.g. via:

    sudo cp ./us_ext /usr/share/X11/xkb/symbols/

Once that is taken care of, invoke your favorite editor (mine is Vim with tabs enabled) to edit two (or optionally three) configuration files belonging to `xkb`, so for me it was:

    sudo vim -p /usr/share/X11/xkb/rules/evdev.{lst,xml}

in the `.lst` file insert the following line:

    us_ext          English (US + DE, IS, PL, Nordic)

right under `us` in the `! layout` section. Here's a screenshot:

![The screenshot](../images/evdev_lst.png)

and in the `.xml` file insert the following block (or a sane variation thereof):

```
    <layout>
      <configItem>
        <name>us_ext</name>

        <shortDescription>en</shortDescription>
        <description>English (US + DE, IS, PL, Nordic)</description>
        <languageList>
          <iso639Id>eng</iso639Id>
        </languageList>
      </configItem>
     <variantList />
    </layout>
```

here's how that looks in Vim:

![The screenshot](../images/evdev_xml.png)

### Further actions to take

**Note:** if you replaced an older version of `us_ext` by a newer version, to reload the keyboard layout without restarting X11, run: `setxkbmap -layout us_ext`.

You may have to edit `/etc/default/keyboard` to say:

```
XKBLAYOUT=us_ext
```

... if you want it to be the default.

Additionally if you want this to take effect on the console, you may have to run `setupcon`. To have it (hopefully) take effect without reboot run `udevadm trigger --subsystem-match=input --action=change`.

Sometimes, when your keyboard layout doesn't show up you may want to use `dpkg-reconfigure xkb-data` to make your changes known.

### Choosing the layout

On (vanilla) Ubuntu I had to _first_ select "English (United States)" which brought me into a list of "variants" which included my layout as "English (US + DE, IS, PL, Nordic)".

## Miscellaneous notes

* Use `xev` to see the key codes.

## Further reading

* [Custom keyboard layout definitions](https://help.ubuntu.com/community/Custom%20keyboard%20layout%20definitions)
* [XKB](https://www.x.org/wiki/XKB/) documentation on X.org
* [Custom Keyboard in Linux/X11](http://people.uleth.ca/~daniel.odonnell/Blog/custom-keyboard-in-linuxx11)
* [Creating custom keyboard layouts for X11 using XKB](https://michal.kosmulski.org/computing/articles/custom-keyboard-layouts-xkb.html)
* [an X11 keyboard layout for scholars of old germanic](https://swanrad.ch/an-x11-keyboard-layout-for-scholars-of-old-germanic/)
