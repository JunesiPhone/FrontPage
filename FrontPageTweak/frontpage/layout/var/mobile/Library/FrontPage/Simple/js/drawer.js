/**
 * Drawer 0.0.1
 * App drawer for FrontPage Themes
 *
 * http://junesiphone.com/frontpage/themes
 *
 * Copyright 2017, Edward Winget
 *
 * Released on: October 7, 2017
 */

/*global FPI, alert, setupDock, console */
(function () {
    'use strict';
    var Drawer = function (params) {
        var main = document.querySelector('.drawer_main'),
            idPrefix = params.idPrefix || "DDApp",
            iconWidth = params.iconWidth || 30,
            iconMargin = params.iconMargin || 10,
            pagingAmount = params.pagingAmount || 30,
            pageSpacing = params.pageSpacing || 10,
            pagePadding = params.pagePadding || 0,
            snapPoint = 100 + pageSpacing,
            labelTopPadding = params.labelTopPadding || 0,
            drawer = null,
            page = null,
            drawerCreate = null,
            registerPopupEvents = function (div, params) {
                div.addEventListener(params.event, params.callback);
            },
            createDOM = function (params) {
                var d = document.createElement(params.type);
                if (params.className) {
                    d.setAttribute('class', params.className);
                }
                if (params.id) {
                    d.id = params.id;
                }
                if (params.innerHTML) {
                    d.innerHTML = params.innerHTML;
                }
                if (params.attribute) {
                    d.setAttribute(params.attribute[0], params.attribute[1]);
                }
                return d;
            },
            popup = function (message, funcYes, btnTxtYes, btnTxtNo, closeALL) {
                var systemPopup = createDOM({
                        type: 'div',
                        id: 'systemPopup'
                    }),
                    systemMessage = createDOM({
                        type: 'div',
                        id: 'systemMessage',
                        innerHTML: message
                    }),
                    systemOptions = createDOM({
                        type: 'div',
                        className: 'systemOptions'
                    }),
                    systemYes = createDOM({
                        type: 'div',
                        id: 'systemYes',
                        innerHTML: btnTxtYes,
                        attribute: ['title', btnTxtYes]
                    }),
                    systemNo = createDOM({
                        type: 'div',
                        id: 'systemNo',
                        innerHTML: btnTxtNo,
                        attribute: ['title', btnTxtNo]
                    });

                systemPopup.appendChild(systemMessage);
                systemOptions.appendChild(systemYes);
                systemOptions.appendChild(systemNo);
                systemPopup.appendChild(systemOptions);
                document.body.appendChild(systemPopup);

                registerPopupEvents(systemYes, {
                    event: 'touchend',
                    callback: function () {
                        funcYes();
                        if (closeALL) {
                            systemPopup.remove();
                        }
                    }
                });
                registerPopupEvents(systemNo, {
                    event: 'touchend',
                    callback: function () {
                        systemPopup.remove();
                    }
                });

            };

        if (main) {
            document.body.removeChild(document.querySelector('.drawer_close_button'));
            document.body.removeChild(document.getElementById('ICONS'));
            document.body.removeChild(main);
        }

        window.uninstall = function () {
            if (FPI.bundle[window.selectedApp].systemApp === "no") {
                window.location = 'frontpage:uninstallApp:' + window.selectedApp;
            } else {
                alert("You cannot delete a system app from here.");
            }
        };

        drawerCreate = function (methods) {
            var array = FPI.apps.all,
                count = null,
                bundle = null,
                name = null,
                icon = null,
                paging = 0;

            array = array.sort(function (a, b) {
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
            });

            page = document.createElement('div');

            function addEvents(div) {
                var moving = false,
                    holdTimer = null,
                    holding = false,
                    startY = 0,
                    startX = 0,
                    X = null,
                    Y = null,
                    endedTouch = function () {
                        clearTimeout(holdTimer);
                        if (!moving && !holding) {
                            var bndle = event.target.id.replace(idPrefix, '');
                            if (bndle) {
                                if (window.appChanging) {
                                    window[window.divID] = bndle;
                                    localStorage[window.divID] = bndle;
                                    methods.toggleDrawer();
                                    setupDock();
                                    window.appChanging = null;
                                } else {
                                    window.location = 'frontpage:openApp:' + bndle;
                                    setTimeout(methods.toggleDrawer, 400);
                                }
                            }
                        }
                        moving = false;
                        holding = false;
                    },
                    startedTouch = function (el) {
                        window.selectedApp = el.target.id.replace('APP', '');
                        moving = false;
                        startY = event.touches[0].clientY;
                        startX = event.touches[0].clientX;
                        holdTimer = setTimeout(function () {
                            holding = true;
                            popup('Uninstall the app ' + window.selectedApp + '?', window.uninstall, "Yes", "No", true);
                        }, 2000);
                    },
                    movedTouch = function () {
                        clearTimeout(holdTimer);
                        X = Math.abs(startX - event.touches[0].clientX);
                        Y = Math.abs(startY - event.touches[0].clientY);
                        if (X > 20 || Y > 20) {
                            moving = true;
                        }
                    },
                    scroll = function () {
                        var result = Math.round((snapPoint / 100) * drawer.clientWidth),
                            pageNumber;
                        if (event.target.scrollLeft % result === 0) {
                            pageNumber = (event.target.scrollLeft / result) + 1;
                            console.log(pageNumber);
                        }
                    };
                div.addEventListener('touchstart', startedTouch);
                div.addEventListener('touchmove', movedTouch);
                div.addEventListener('touchend', endedTouch);
                div.addEventListener('scroll', scroll);
            }

            function createCloser() {
                var closeButton = document.createElement('div');
                closeButton.className = 'drawer_close_button';
                document.body.appendChild(closeButton);
                closeButton.addEventListener('touchstart', methods.toggleDrawer);
            }

            function setAfterStyles() {
                var style = document.createElement('style'),
                    label = iconWidth + 4,
                    left = ((iconWidth * screen.width / 100) - (label * screen.width / 100)) / 2,
                    labelTop = labelTopPadding + iconWidth,
                    css = ".drawer_icon::after{font-size:" + (iconWidth * 0.10) + "%;margin-left:" + left + "px;margin-top:" + labelTop + "vw; width: " + label + "vw;}";
                css += ".drawer_icon::before{}";
                style.type = 'text/css';
                style.id = 'ICONS';
                style.appendChild(document.createTextNode(css));
                document.body.appendChild(style);
            }


            function createIcons() {
                var i, div, spacer, mA, sel;
                mA = FPI.apps.all.sort(function (a, b) {
                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
                });
                drawer = document.createElement('div');
                drawer.className = 'drawer_main';
                drawer.style.cssText += "-webkit-scroll-snap-points-x: repeat(" + snapPoint + "%);";

                for (i = 0; i < mA.length; i += 1) {
                    paging += 1;
                    sel = FPI.bundle[mA[i].bundle];
                    name = sel.name;
                    count = sel.badge;
                    bundle = mA[i].bundle;
                    icon = '/var/mobile/Library/FrontPageCache/' + bundle + '.png';
                    div = document.createElement('div');
                    div.id = idPrefix + bundle;
                    div.setAttribute('letter', name.charAt(0));
                    div.className = "drawer_icon";
                    div.style.cssText += "margin:" + iconMargin + ";width: " + iconWidth + "vw;height: " + iconWidth + "vw;";
                    div.style.backgroundImage = 'url("' + icon + '")';
                    div.setAttribute('badge', (count >= 1) ? count : "");
                    div.setAttribute('name', name);
                    page.appendChild(div);
                    if (paging === pagingAmount || i === mA.length - 1) {
                        paging = 0;
                        page.className = 'drawer_page';
                        if (i === mA.length - 1) { //lastpage
                            page.style.cssText += "padding:" + pagePadding + "px; margin-right:0px;";

                        } else {
                            page.style.cssText += "padding:" + pagePadding + "px; margin-right:" + pageSpacing + "%;";
                        }
                        if (params.labels === false) {
                            page.style.color = 'transparent';
                        }
                        drawer.appendChild(page);

                        if (i === array.length - 1) { //lastpage
                            spacer = document.createElement('div');
                            spacer.className = 'drawer_page';
                            spacer.style.cssText += "margin-left:-5px;opacity:0;width:0;height:0;";
                            drawer.appendChild(spacer);
                        }

                        page.title = page.children[0].getAttribute('letter') + '-' + page.children[page.children.length - 1].getAttribute('letter');
                        page = document.createElement('div');
                    }
                }
                document.body.appendChild(drawer);
                //make sure last element (not counting spacer) has the same height as the rest.
                //It may not conain a full set of icons.
                drawer.lastChild.previousElementSibling.style.cssText += 'height:' + drawer.firstChild.offsetHeight + 'px';
                addEvents(drawer);
                createCloser();
            }

            createIcons();
            methods.reloadIcons = function () {
                var drawerDiv = document.querySelector('.drawer_main'),
                    closer = document.querySelector('.drawer_close_button');
                if (drawerDiv) {
                    document.body.removeChild(drawerDiv);
                    document.body.removeChild(closer);
                }
                return createIcons();
            };

            setAfterStyles();
            return methods;
        };

        this.toggleDrawer = function () {
            var button = document.querySelector('.drawer_close_button');
            document.querySelector('.drawer_main').classList.toggle('drawer_open');
            if (button) {
                button.classList.toggle('drawer_close_button_show');
            }
        };

        this.hideLabels = function () {
            document.querySelector('.drawer_page').style.color = 'transparent';
        };

        this.showLabels = function (color) {
            document.querySelector('.drawer_page').style.color = color || 'white';
        };

        this.updateBadge = function (bundle) {
            var badge = (FPI.bundle[bundle].badge === 0) ? "" : FPI.bundle[bundle].badge;
            if (document.getElementById(idPrefix + bundle)) {
                document.getElementById(idPrefix + bundle).setAttribute('badge', badge);
            }
        };

        return drawerCreate(this);
    };
    window.Drawer = Drawer;
}());
