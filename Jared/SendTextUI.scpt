JsOsaDAS1.001.00bplist00�Vscript_(let systemEvents = Application('System Events')

var messages = systemEvents.applicationProcesses.byName('Messages');
let textArea = messages.windows.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(1).groups.at(0).groups.at(0).groups.at(0).groups.at(3).groups.at(0).groups.at(2).scrollAreas.at(0).textFields.at(0)
let toField = messages.windows.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(0).groups.at(1).groups.at(0).groups.at(0).groups.at(0).groups.at(2).groups.at(0).groups.at(0).scrollAreas.at(0).groups.at(0).textFields.at(0)

let messagesMenus = messages.menuBars[0].menuBarItems;
let newMessageMenu = messagesMenus.byName('File').menus[0].menuItems.byName('New Message')

function run(input) {
	Application('Messages').activate()
	delay(0.1)
	newMessageMenu.click()
	textArea.click()
	textArea.value = input[0]
	delay(0.1)
	toField.click()
	toField.value = input[1]
	systemEvents.keyCode(43);
	delay(0.01)
	systemEvents.keyCode(48);
	delay(0.01)
	systemEvents.keyCode(36);
}                              >jscr  ��ޭ