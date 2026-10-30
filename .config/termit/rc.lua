colormaps = require("termit.colormaps")
utils = require("termit.utils")

defaults = {}
defaults.windowTitle = 'Termit'
defaults.tabName = 'Terminal'
defaults.foregroundColor = 'White'
defaults.backgroundColor = '#85aab9'
defaults.showScrollbar = true
defaults.hideSingleTab = true
defaults.hideTabbar = false
defaults.showBorder = true
defaults.hideMenubar = false
defaults.fillTabbar = true
--defaults.scrollbackLines = 4096
--defaults.geometry = '40x24'
defaults.allowChangingTitle = false
--defaults.backspaceBinding = 'AsciiBksp'
--defaults.deleteBinding = 'AsciiDel'
defaults.cursorBlinkMode = 'BlinkOn'
--defaults.setStatusbar = function (tabInd)
--    tab = tabs[tabInd]
--    if tab then
--        return tab.encoding..'  Bksp: '..tab.backspaceBinding..'  Del: '..tab.deleteBinding
--    end
--    return ''
--end
defaults.colormap = colormaps.delicate
defaults.matches = {['http[-:/.\\w]+'] = function (url) print('Matching url: '..url) end}
setOptions(defaults)

bindKey('Ctrl-Page_Up', prevTab)
bindKey('Ctrl-Page_Down', nextTab)
bindKey('Ctrl-F', findDlg)
bindKey('Ctrl-2', function () print('Hello2!') end)
bindKey('Ctrl-3', function () print('Hello3!') end)
bindKey('Ctrl-3', nil) -- remove previous binding

setKbPolicy('keycode')

-- 
userMenu = {}
table.insert(userMenu, {name='Close tab', action=closeTab})
-- table.insert(userMenu, {name='New tab name', action=function () setTabTitle('New tab name') end})

--mi = {}
--mi.name = 'Zsh tab'
--mi.action = function ()
--    tabInfo = {}
--    tabInfo.title = 'Zsh tab'
--    tabInfo.command = 'zsh'
--    tabInfo.encoding = 'UTF-8'
--    tabInfo.workingDir = '/tmp'
--    tabInfo.backspaceBinding = 'AsciiBksp'
--    tabInfo.deleteBinding = 'EraseDel'
--    openTab(tabInfo)
--end

table.insert(userMenu, mi)

--table.insert(userMenu, {name='set red color', action=function () setTabForegroundColor('red') end})
table.insert(userMenu, {name='Reconfigure', action=reconfigure, accel='Ctrl-r'})
table.insert(userMenu, {name='Selection', action=function () print(selection()) end})
--table.insert(userMenu, {name='Save Fession to File', action=function () forEachRow(print) end})
--table.insert(userMenu, {name='Save Visible to File',
--    action=function () utils.dumpToFile(forEachVisibleRow, '/tmp/termit.dump') end})
table.insert(userMenu, {name='Find Next', action=findNext, accel='Alt-n'})
table.insert(userMenu, {name='Find Previous', action=findPrev, accel='Alt-p'})
--table.insert(userMenu, {name='new colormap', action=function () setColormap(colormaps.mikado) end})
table.insert(userMenu, {name='Toggle Menubar', action=function () toggleMenubar() end})
table.insert(userMenu, {name='Toggle Tabbar', action=function () toggleTabbar()  end})

--mi = {}
--mi.name = 'Get tab info'
--mi.action = function ()
--    tab = tabs[currentTabIndex()]
--    if tab then
--        utils.printTable(tab, '  ')
--    end
--end
table.insert(userMenu, mi)

function round(float)
    return math.floor(float + .5)
end

function changeTabFontSize(delta)
    tab = tabs[currentTabIndex()]
    fontSize = round(tab.fontSize)
    setTabFont(string.sub(tab.font, 1, string.find(tab.font, '%d+$') - 1)..(fontSize + delta))
end

table.insert(userMenu, {name='Increase Font size', action=function () changeTabFontSize(1) end})
table.insert(userMenu, {name='Decrease Font size', action=function () changeTabFontSize(-1) end})
--table.insert(userMenu, {name='feed example', action=function () feed('example') end})
--table.insert(userMenu, {name='feedChild example', action=function () feedChild('date\n') end})
--table.insert(userMenu, {name='move tab left', action=function () setTabPos(currentTabIndex() - 1) end})
--table.insert(userMenu, {name='move tab right', action=function () setTabPos(currentTabIndex() + 1) end})
--table.insert(userMenu, {name='User quit', action=quit})

addMenu(userMenu, "Other")
addPopupMenu(userMenu, "Other")

--addMenu(utils.encMenu(), "Encodings")
--addPopupMenu(utils.encMenu(), "Encodings")
