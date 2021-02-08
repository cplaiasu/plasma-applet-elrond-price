/***************************************************************************
 *   Copyright (C) 2017 by MakG <makg@makg.eu>                             *
 ***************************************************************************/

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import "../code/elrond.js" as Elrond

Item {
	id: root
	
	Layout.fillHeight: true
	
	property string elrondRate: '...'
	property bool showIcon: plasmoid.configuration.showIcon
	property bool showText: plasmoid.configuration.showText
	property bool updatingRate: false
	
	Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
	Plasmoid.toolTipTextFormat: Text.RichText
	Plasmoid.backgroundHints: plasmoid.configuration.showBackground ? "StandardBackground" : "NoBackground"
	
	Plasmoid.compactRepresentation: Item {
		property int textMargin: elrondIcon.height * 0.25
		property int minWidth: {
			if(root.showIcon && root.showText) {
				return elrondValue.paintedWidth + elrondIcon.width + textMargin;
			}
			else if(root.showIcon) {
				return elrondIcon.width;
			} else {
				return elrondValue.paintedWidth
			}
		}
		
		Layout.fillWidth: false
		Layout.minimumWidth: minWidth

		MouseArea {
			id: mouseArea
			anchors.fill: parent
			hoverEnabled: true
			onClicked: {
				switch(plasmoid.configuration.onClickAction) {
					case 'website':
						action_website();
						break;
					
					case 'refresh':
					default:
						action_refresh();
						break;
				}
			}
		}
		
		BusyIndicator {
			width: parent.height
			height: parent.height
			anchors.horizontalCenter: root.showIcon ? elrondIcon.horizontalCenter : elrondValue.horizontalCenter
			running: updatingRate
			visible: updatingRate
		}
		
		Image {
			id: elrondIcon
			width: parent.height * 0.9
			height: parent.height * 0.9
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.topMargin: parent.height * 0.05
			anchors.leftMargin: root.showText ? parent.height * 0.05 : 0
			
			source: "../images/elrond.png"
			visible: root.showIcon
			opacity: root.updatingRate ? 0.2 : mouseArea.containsMouse ? 0.8 : 1.0
		}
		
		PlasmaComponents.Label {
			id: elrondValue
			height: parent.height
			anchors.left: root.showIcon ? elrondIcon.right : parent.left
			anchors.right: parent.right
			anchors.leftMargin: root.showIcon ? textMargin : 0
			
			horizontalAlignment: root.showIcon ? Text.AlignLeft : Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			
			visible: root.showText
			opacity: root.updatingRate ? 0.2 : mouseArea.containsMouse ? 0.8 : 1.0
			
			fontSizeMode: Text.Fit
			minimumPixelSize: elrondIcon.width * 0.7
			font.pixelSize: 72			
			text: root.elrondRate
		}
	}
	
	Component.onCompleted: {
		plasmoid.setAction('refresh', i18n("Refresh"), 'view-refresh')
		plasmoid.setAction('website', i18n("Open market's website"), 'internet-services')
	}
	
	Connections {
		target: plasmoid.configuration
		
		onCurrencyChanged: {
			elrondTimer.restart();
		}
		onSourceChanged: {
			elrondTimer.restart();
		}
		onRefreshRateChanged: {
			elrondTimer.restart();
		}
		onShowDecimalsChanged: {
			elrondTimer.restart();
		}
	}
	
	Timer {
		id: elrondTimer
		interval: plasmoid.configuration.refreshRate * 60 * 1000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			root.updatingRate = true;
			
			var result = Elrond.getRate(plasmoid.configuration.source, plasmoid.configuration.currency, function(rate) {
				if(!plasmoid.configuration.showDecimals) rate = Math.floor(rate);
				
				var rateText = Number(rate).toLocaleCurrencyString(Qt.locale(), Elrond.currencySymbols[plasmoid.configuration.currency]);
				
				if(!plasmoid.configuration.showDecimals) rateText = rateText.replace(Qt.locale().decimalPoint + '00', '');
				
				root.elrondRate = rateText;
				
				var toolTipSubText = '<b>' + root.elrondRate + '</b>';
				toolTipSubText += '<br />';
				toolTipSubText += i18n('Market:') + ' ' + plasmoid.configuration.source;
				
				plasmoid.toolTipSubText = toolTipSubText;
				
				root.updatingRate = false;
			});
		}
	}
	
	function action_refresh() {
		elrondTimer.restart();
	}
	
	function action_website() {
		Qt.openUrlExternally(Elrond.getSourceByName(plasmoid.configuration.source).homepage);
	}
}
