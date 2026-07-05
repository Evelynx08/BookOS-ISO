var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [],
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
            "applets": [],
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
                    "plugin": "bookos-launchpad"
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
                            "launchers": "preferred://filemanager"
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
            "lengthMode": "fit",
            "location": "bottom",
            "floating": true,
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
                    "plugin": "bookos-menu"
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
                    "config": {},
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "503",
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
                    "plugin": "bookos-battery"
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
                            "popupHeight": "173",
                            "popupWidth": "320"
                        }
                    },
                    "plugin": "bookos-bluetooth"
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
                            "popupHeight": "179",
                            "popupWidth": "330"
                        }
                    },
                    "plugin": "bookos-network"
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
                            "popupHeight": "277",
                            "popupWidth": "300"
                        }
                    },
                    "plugin": "bookos-brightness"
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
                            "popupHeight": "271",
                            "popupWidth": "300"
                        }
                    },
                    "plugin": "bookos-volume"
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
                            "popupHeight": "509",
                            "popupWidth": "320"
                        }
                    },
                    "plugin": "bookos-notifications"
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
                            "popupHeight": "473",
                            "popupWidth": "360"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "631",
                            "DialogWidth": "810"
                        }
                    },
                    "plugin": "bookos-controlcenter"
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
            "lengthMode": "fill",
            "location": "top",
            "floating": false,
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

