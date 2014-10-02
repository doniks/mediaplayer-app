/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * Authors:
 *  Ugo Riboni <ugo.riboni@canonical.com>
 *  Michał Sawicz <michal.sawicz@canonical.com>
 *  Renato Araujo Oliveira Filho <renato@canonical.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import QtMultimedia 5.0
import Ubuntu.Unity.Action 1.1 as UnityActions
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0 as Popups


Rectangle {
    id: mediaPlayer
    width: screenWidth
    height: screenHeight

    property string orientation: "0"
    property string formFactor: "phone"
    property real volume: playerLoader.item.volume
    property bool appActive: Qt.application.active

    property variant nativeOrientation: Screen.primaryOrientation

    onAppActiveChanged: {
        if (!appActive &&
            !mpApplication.desktopMode &&
            playerLoader.item &&
            playerLoader.item.playing) {
            playerLoader.item.pause()
        }
    }

    Screen.onOrientationChanged: {
        // Rotate the UI when the device orientation changes
        mediaPlayer.orientation = Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    }

    Component.onCompleted: {
        i18n.domain = "mediaplayer-app"
    }

    Component {
        id: dialogNoUrl

        Popups.Dialog {
            id: dialogue
            objectName: "noMediaDialog"

            title: i18n.tr("Error")
            text: i18n.tr("No video selected to play. Connect your phone to your computer to transfer videos to the phone. Then select video from Videos scope.")

            Button {
                text: i18n.tr("Ok")
                gradient: UbuntuColors.greyGradient
                onClicked: Qt.quit()
            }
        }
    }

    Loader {
        id: playerLoader

        source: "player/VideoPlayer.qml"
        focus: true
        anchors.fill: parent
        clip: true
        onLoaded: {
            item.focus = true
            item.rotating = Qt.binding(function () { return rotatingTransition.running } )
            if (playUri != "") {
                item.playUri(playUri)
            } else {
                if (mpApplication.desktopMode) {
                    var videoFile = mpApplication.chooseFile()
                    if (videoFile != "") {
                        item.playUri(videoFile)
                    }
                } else {
                    PopupUtils.open(dialogNoUrl, null)
                }
            }
        }

        state: mediaPlayer.orientation != "" ? mediaPlayer.orientation : (screenHeight <= screenWidth ? "0" : "270")
        Component.onCompleted: {
            state = Qt.binding(function () {
                return mediaPlayer.orientation != "" ? mediaPlayer.orientation : (screenHeight <= screenWidth ? "0" : "270")
            })
        }

        states:  [
          State {
            name: "0"
            PropertyChanges {
              target: mediaPlayer
              rotation: 0
              width: screenWidth
              height: screenHeight
              x: 0
              y: 0
            }
          },
          State {
            name: "180"
            PropertyChanges {
              target: mediaPlayer
              rotation: 180
              width: screenWidth
              height: screenHeight
              x: 0
              y: 0
            }
          },
          State {
            name: "270"
            PropertyChanges {
              target: mediaPlayer
              rotation: 270
              width: screenHeight
              height: screenWidth
              x: (screenWidth - screenHeight) / 2
              y: -(screenWidth - screenHeight) / 2
            }
          },
          State {
            name: "90"
            PropertyChanges {
              target: mediaPlayer
              rotation: 90
              width: screenHeight
              height: screenWidth
              x: (screenWidth - screenHeight) / 2
              y: -(screenWidth - screenHeight) / 2
            }
          }
        ]

        transitions: [
          Transition {
            id: rotatingTransition
            ParallelAnimation {
              RotationAnimation {
                properties: "rotation"
                duration: 250
                direction: RotationAnimation.Shortest
              }
              PropertyAnimation {
                target: mediaPlayer
                properties: "x,y,width,height"
                duration: 250
              }
            }
          }
        ]
    }

    Connections {
        target: playerLoader.item
        onStatusChanged: {
            if (playerLoader.item.status === MediaPlayer.EndOfMedia) {
                playerLoader.item.stop()
                playerLoader.item.controlsActive = true
            }
        }
    }

    UnityActions.ActionManager {
        actions: [
            UnityActions.Action {
                text: i18n.tr("Play / Pause")
                keywords: i18n.tr("Pause or Resume Playhead")
                onTriggered: playerLoader.item.playPause()
            },
            UnityActions.Action {
                text: i18n.tr("Share")
                keywords: i18n.tr("Post;Upload;Attach")
                onTriggered: playerLoader.item.startSharing()
            }
        ]
    }

    function rotateClockwise() {
        if (orientation == "") orientation = playerLoader.state
        if (orientation == "0") orientation = "270"
        else if (orientation == "270") orientation = "180"
        else if (orientation == "180") orientation = "90"
        else orientation = "0"
    }

    function rotateCounterClockwise() {
        if (orientation == "") orientation = playerLoader.state
        if (orientation == "0") orientation = "90"
        else if (orientation == "90") orientation = "180"
        else if (orientation == "180") orientation = "270"
        else orientation = "0"
    }

    Keys.onReleased: {
        if (!event.isAutoRepeat
            && (event.key == Qt.Key_F11 || event.key == Qt.Key_F)) {
            event.accepted = true
            application.toggleFullscreen();
        } else if (!event.isAutoRepeat && event.key == Qt.Key_BracketLeft) {
            event.accepted = true
            rotateClockwise()
        } else if (!event.isAutoRepeat && event.key == Qt.Key_BracketRight) {
            event.accepted = true
            rotateCounterClockwise()
        }
    }

    Connections {
        target: UriHandler
        onOpened: {
            for (var i = 0; i < uris.length; ++i) {
                playerLoader.item.playUri(uris[i])
            }
        }
    }
}
