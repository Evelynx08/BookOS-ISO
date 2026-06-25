var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
            ],
            "config": {
                "/": {
                    "ItemGeometries-1280x720": "Applet-163:512,16,640,304,0;",
                    "ItemGeometries-1646x1029": "",
                    "ItemGeometries-1800x1125": "",
                    "ItemGeometries-1829x1029": "Applet-88:496,0,656,304,0;",
                    "ItemGeometries-2259x1271": "Applet-88:464,0,688,352,0;",
                    "ItemGeometriesHorizontal": "",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/ConfigDialog": {
                    "DialogHeight": "983",
                    "DialogWidth": "1638"
                },
                "/General": {
                    "changedPositions": "{}",
                    "lastResolution": "1646x1029",
                    "positions": "{\"1646x1029\":[\"1\",\"15\"]}",
                    "sortMode": "-1"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": "file:///usr/share/backgrounds/bookos/Light/blue.png",
                    "SlidePaths": "/usr/share/backgrounds/bookos/,/usr/share/wallpapers/"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        },
        {
            "applets": [
            ],
            "config": {
                "/": {
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "1",
                    "wallpaperplugin": "org.kde.image"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": "file:///usr/share/backgrounds/bookos/Light/blue.png"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        }
    ],
    "panels": [
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/": {
                            "popupHeight": "681",
                            "popupWidth": "580"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "631",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "blurRadius": "28",
                            "foldersJson": "[{\"name\":\"New folder\",\"members\":[\"Cachy-Update\",\"Btrfs Assistant\"],\"color\":\"#3F51B5\"}]"
                        }
                    },
                    "plugin": "com.bookos.launchpad"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "631",
                            "DialogWidth": "810"
                        }
                    },
                    "plugin": "org.kde.plasma.marginsseparator"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "launchers": "applications:bookos-settings.desktop,preferred://filemanager,applications:firefox.desktop"
                        }
                    },
                    "plugin": "org.kde.plasma.icontasks"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "height": 2.888888888888889,
            "hiding": "dodgewindows",
            "floating": true,
            "lengthMode": "fit",
            "location": "bottom",
            "maximumLength": 91.44444444444444,
            "minimumLength": 91.44444444444444,
            "offset": 0,
            "opacity": "opaque"
        },
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "5"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "236",
                            "popupWidth": "210"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "631",
                            "DialogWidth": "810"
                        }
                    },
                    "plugin": "com.bookos.menu"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "5"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "632",
                            "popupWidth": "340"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "848",
                            "DialogWidth": "843"
                        },
                        "/General": {
                            "animRainbowSpeed": "2000",
                            "balancedColor": "#5E5CE6",
                            "customFont": "SN Pro ExtraBold",
                            "customIconRadius": "15",
                            "forceManager": "1",
                            "normalColor": "#30D158",
                            "percentPosition": "1",
                            "pluggedFullColor": "#59C734",
                            "popupStyle": "1",
                            "profile1Cmd": "/usr/bin/samsung-galaxybook-extras --fan-mode=silent",
                            "profile2Cmd": "/usr/bin/samsung-galaxybook-extras --fan-mode=auto",
                            "profile3Cmd": "/usr/bin/samsung-galaxybook-extras --fan-mode=turbo",
                            "useCustomIconRadius": "true"
                        }
                    },
                    "plugin": "com.mi.widget.bateria"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "433",
                            "popupWidth": "432"
                        },
                        "/General": {
                            "expanding": "false",
                            "length": "5"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "400",
                            "popupWidth": "560"
                        }
                    },
                    "plugin": "org.kde.plasma.bluetooth"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "5"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "404",
                            "popupWidth": "564"
                        }
                    },
                    "plugin": "org.kde.plasma.networkmanagement"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "5"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "404",
                            "popupWidth": "564"
                        }
                    },
                    "plugin": "org.kde.plasma.brightness"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "5"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "243",
                            "popupWidth": "296"
                        },
                        "/General": {
                            "migrated": "true"
                        }
                    },
                    "plugin": "org.kde.plasma.volume"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "10"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "433",
                            "popupWidth": "324"
                        }
                    },
                    "plugin": "org.kde.plasma.notifications"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "10"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "659",
                            "popupWidth": "380"
                        },
                        "/Appearance": {
                            "animations": "true",
                            "cmdIcon1": "night-light-disabled-10-symbolic",
                            "cmdRun1": "bash ~/.toggle-luz.sh",
                            "cmdTitle1": "Luz Nocturna",
                            "customButtonImage": "",
                            "darkGlobalTheme": "BookOS Dark",
                            "darkTheme": "BookOSDark",
                            "hideWidgetOnScreenshot": "true",
                            "layout": "5",
                            "lightGlobalTheme": "BookOS Light1",
                            "lightTheme": "BookOSLight",
                            "preferChangeGlobalTheme": "true",
                            "showBorders": "false",
                            "showPercentage": "true",
                            "transparency": "true",
                            "transparencyLevel": "30"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "983",
                            "DialogWidth": "1638"
                        }
                    },
                    "plugin": "KdeControlStation"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "10"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "451",
                            "popupWidth": "810"
                        },
                        "/Appearance": {
                            "autoFontAndSize": "false",
                            "customDateFormat": "ddd d ",
                            "dateDisplayFormat": "BesideTime",
                            "displayTimezoneFormat": "UTCOffset",
                            "enabledCalendarPlugins": "pimevents",
                            "firstDayOfWeek": "1",
                            "fontFamily": "SN Pro",
                            "fontStyleName": "Medium",
                            "fontWeight": "500"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "631",
                            "DialogWidth": "811"
                        }
                    },
                    "plugin": "org.kde.plasma.digitalclock"
                },
                {
                    "config": {
                        "/General": {
                            "expanding": "false",
                            "length": "10"
                        }
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "height": 1.7777777777777777,
            "hiding": "dodgewindows",
            "floating": true,
            "lengthMode": "fill",
            "location": "top",
            "maximumLength": 91.44444444444444,
            "minimumLength": 91.44444444444444,
            "offset": 0,
            "opacity": "opaque"
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);

