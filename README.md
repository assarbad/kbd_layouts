# Oliver's customized keyboard layouts

Feel free to use these in any way you want under one of the permissive (non-Copyleft) licenses approved by the OSI or CC0 terms. If unsure, simply ask.

I am providing code-signed versions of the setups in the [download section](https://bitbucket.org/assarbad/kbd_layouts/downloads).

## English extended (`kbdus_xx`) - Windows version

The Windows keyboard layout has evolved over quite some time. The (currently) final incarnation is what I call `kbdus_xx`. Whereas the `kbd` is for "keyboard", `us` refers to the fact that it's based on the "English (US)" layout and `xx` refers to the extensive
nature of the layout compared to the base version.

Now I prefer using a US-English keyboard for my typing during the daily programming and debugging chores. However, that has the downside that certain symbols are never available on any of the variants of that keyboard layout.

Fortunately Microsoft offers the so-called [Microsoft keyboard layout creator (MSKLC)](https://msdn.microsoft.com/en-us/goglobal/bb964665.aspx), and has done so for quite some years now. This program allows to load an existing keyboard layout and adjust it to ones own needs. And so I did. The first time before Vista was even out.

Now this suits my needs, it may not suit yours. Still it could provide a basis for your own customizations or even just point you to the very fact that it's possible.

**Note:** these `.klc` files are text files. But they are UTF-16 (LE), so they may appear like binary files at first glance. The Notepad version that comes with Windows as well as any other decent text editor should be able to edit them.

Here's how the layout looks in the various states a keyboard can have ...

### Small letters (no combination with special keys)

![Small letters (no combination with special keys)](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdus_xx/01_no_modifiers.png)

### Capital letters, Shift pressed

![Capital letters, Shift pressed](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdus_xx/02_plus_shift.png)

### AltGr (Ctrl+Alt), that's the one right of the space bar, pressed

![AltGr (Ctrl+Alt), that's the one right of the space bar, pressed](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdus_xx/03_plus_altgr.png)

### AltGr+Shift (Ctrl+Alt+Shift) pressed

![AltGr+Shift (Ctrl+Alt+Shift) pressed](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdus_xx/04_plus_shift_altgr.png)

## xkb version (X11) of `kbdus_xx` (`us_ext`)

This one I have tested on Kubuntu 12.04 and lately on Linux Mint 18.1 (which is based on Ubuntu 16.04). There are lots and lots of resources on how to do it on Ubuntu, but I ended up with different steps anyway in the end. Regardless, [this article](http://michal.kosmulski.org/computing/articles/custom-keyboard-layouts-xkb.html) was probably the single-most useful one in the process. Mind the fact that it has a resource section at the bottom, pointing to further useful resources.

Unlike the Windows version which is a keyboard layout in its own right, the way X11 and `xkb` work allows us to *extend* existing definitions. This is much more convenient and also allows for a more readable way of expressing this. I call it `us_ext`.

Find it under [`./X11`](https://bitbucket.org/assarbad/kbd_layouts/src//X11/).

### Installation on Kubuntu 12.04, Linux Mint 18.1 (which is based on Ubuntu 16.04)

Since I was unable to install the layout in the way described on the linked page, here's how to install it on Kubuntu 12.04 or Linux Mint 18.1 (and presumably Ubuntu 16.04).

Files to modify:

* `/usr/share/X11/xkb/symbols/us_ext`
* `/usr/share/X11/xkb/rules/evdev.lst`
* `/usr/share/X11/xkb/rules/evdev.xml`

First thing is to copy the `us_ext` file from this repository into `/usr/share/X11/xkb/symbols/`. E.g. via:

    sudo cp ./us_ext /usr/share/X11/xkb/symbols/

Once that is taken care of, invoke your favorite editor (mine is Vim with tabs enabled) to edit two configuration files belonging to `xkb`, so for me it was:

    sudo vim -p /usr/share/X11/xkb/rules/evdev.{lst,xml}

in the `.lst` file insert the following line:

    us_ext          English v8 (US + DE, IS, PL, Nordic)

right under `us` in the `! layout` section. Here's a screenshot:

![The screenshot](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/evdev_lst.png)

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

![The screenshot](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/evdev_xml.png)

**Note:** if you replaced an older version of `us_ext` by a newer version, to reload the keyboard layout without restarting X11, run: `setxkbmap -layout us_ext`.

## Russian phonetic (`kbdru_us`) - Windows version

This is a kind of phonetic keyboard layout that tries to squeeze as many Cyrillic (not just Russian) characters onto a keyboard layout. Obviously for practical reasons I *had* to assign some characters in ways that are not exactly phonetic. But I tried to be pragmatic about it.

Here's how the layout looks in the various states a keyboard can have ...

### Small letters (no combination with special keys)

![Small letters (no combination with special keys)](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdru_us/01_no_modifiers.png)

### Capital letters, Shift pressed

![Capital letters, Shift pressed](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdru_us/02_plus_shift.png)

### AltGr (Ctrl+Alt), that's the one right of the space bar, pressed

![AltGr (Ctrl+Alt), that's the one right of the space bar, pressed](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdru_us/03_plus_altgr.png)

### AltGr+Shift (Ctrl+Alt+Shift) pressed

![AltGr+Shift (Ctrl+Alt+Shift) pressed](https://bitbucket.org/assarbad/kbd_layouts/raw/tip/images/kbdru_us/04_plus_shift_altgr.png)
