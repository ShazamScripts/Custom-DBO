antiRedUI = {};
-- Usa a tabela "storage" nativa do bot (salva por personagem/perfil,
-- igual o ComboUP faz) em vez de escrever um arquivo .json manualmente.
storage.antired_data = storage.antired_data or {
    enabled = true,
    amountOfMonsters = 2,
    targetSpells = {},
    areaSpells = {}
};
antired_data = storage.antired_data;
antired_data.targetSpells = antired_data.targetSpells or {};
antired_data.areaSpells = antired_data.areaSpells or {};

antiRedUI.save = function()
    if (type(saveConfig) == "function") then
        saveConfig();
    end
end

-- ============================================================
-- Widget flutuante "Area blocked for Xs" (igual o ANTI RED original)
-- ============================================================
storage.widgetPos = storage.widgetPos or {}

local antiRedTimeWidget = setupUI([[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
]], g_ui.getRootWidget())

local isMobile = modules._G.g_app.isMobile()
g_keyboard = g_keyboard or modules.corelib.g_keyboard

local isDragKeyPressed = function()
  return isMobile and g_keyboard.isKeyPressed("F2") or g_keyboard.isCtrlPressed()
end

antiRedTimeWidget.onDragEnter = function(widget, mousePos)
  if (not isDragKeyPressed()) then return end
  widget:breakAnchors()
  local widgetPos = widget:getPosition()
  widget.movingReference = {x = mousePos.x - widgetPos.x, y = mousePos.y - widgetPos.y}
  return true
end

antiRedTimeWidget.onDragMove = function(widget, mousePos, moved)
  local parentRect = widget:getParent():getRect()
  local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
  local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
  widget:move(x, y)
  storage.widgetPos.antiRedTime = {x = x, y = y}
  return true
end

local widgetName = "antiRedTime"
storage.widgetPos[widgetName] = storage.widgetPos[widgetName] or {}
antiRedTimeWidget:setPosition({x = storage.widgetPos[widgetName].x or 50, y = storage.widgetPos[widgetName].y or 50})

-- Suporte a getSpectators custom
-- IMPORTANTE: NUNCA sobrescrever a "getSpectators" GLOBAL. Fazer isso
-- (como estava antes) trocava a funcao nativa do client -- usada por
-- TODOS os outros modulos (Enemy, TargetBot, Combo, etc.) -- por uma
-- versao feita em Lua puro, bem mais lenta. Isso deixava a custom
-- inteira pesada, nao so o AntiRed. Alem disso, o gatilho antigo
-- (#getSpectators(true) == 0) disparava por engano sempre que voce
-- simplesmente estivesse sozinho num canto sem ninguem por perto.
--
-- Agora e uma funcao LOCAL, so usada aqui dentro, e so entra em acao
-- se a nativa realmente nao existir (o que na pratica nao deve
-- acontecer nesse client, mas fica de seguranca).
local localGetSpectatorsFallback = function()
  local specs = {}
  local tiles = g_map.getTiles(posz())
  for i = 1, #tiles do
    local tile = tiles[i]
    local creatures = tile:getCreatures()
    for _, creature in ipairs(creatures) do
      table.insert(specs, creature)
    end
  end
  return specs
end
local safeGetSpectators = (type(getSpectators) == "function") and getSpectators or localGetSpectatorsFallback

if (not storage.antiRedTime or storage.antiRedTime - 0 > now) then
  storage.antiRedTime = 0
end

local addAntiRedTime = function()
  storage.antiRedTime = now + 2000
end

local toInteger = function(number)
  number = tostring(number)
  number = number:split(".")
  return tonumber(number[1])
end

-- ============================================================
-- UI (igual o ComboUP): lista de magias de Target e de Area,
-- adicione quantas quiser, com cooldown opcional por magia.
-- ============================================================
local entryTemplateAntiRed = [[
UIWidget
  background-color: alpha
  text-offset: 18 0
  focusable: true
  height: 16

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 3

  Label
    id: text
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 25
    font: terminus-14px-bold

  $focus:
    background-color: #00000055

  Button
    id: remove
    !text: tr('X')
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 18
    width: 15
    height: 15
    tooltip: Remover
]];

antiRedUI.buttons = setupUI([[
Panel
  height: 17
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    !text: tr('Anti Red')

    image-source:

    $on:
      color: green

    $!on:
      color: white
]]);

antiRedUI.interface = setupUI([[
MainWindow
  !text: tr('Anti Red - BY Shazam')
  size: 480 340

  Panel
    id: leftPanel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: bottomBar.top
    margin-top: 10
    margin-left: 10
    margin-bottom: 10
    width: 220
    image-border: 6
    padding: 3

    Label
      id: targetTitle
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      text-align: center
      font: sans-bold-16px
      color: orange
      margin-top: 5
      text: Target

    ScrollablePanel
      id: targetList
      layout:
        type: verticalBox
      anchors.top: targetTitle.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: targetAddButton.top
      margin-top: 5
      margin-bottom: 5
      vertical-scrollbar: targetListScroll

    VerticalScrollBar
      id: targetListScroll
      anchors.top: targetList.top
      anchors.bottom: targetList.bottom
      anchors.right: targetList.right
      step: 14
      pixels-scroll: true

    TextEdit
      id: targetNameField
      tooltip: Nome da magia de ataque (target)
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      margin-bottom: 5
      width: 130

    Button
      id: targetAddButton
      !text: tr('+')
      anchors.left: targetNameField.right
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-left: 3
      margin-bottom: 5

  Panel
    id: rightPanel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: leftPanel.right
    anchors.right: parent.right
    anchors.bottom: bottomBar.top
    margin-top: 10
    margin-left: 10
    margin-right: 10
    margin-bottom: 10
    image-border: 6
    padding: 3

    Label
      id: areaTitle
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      text-align: center
      font: sans-bold-16px
      color: orange
      margin-top: 5
      text: Area

    ScrollablePanel
      id: areaList
      layout:
        type: verticalBox
      anchors.top: areaTitle.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: areaAddButton.top
      margin-top: 5
      margin-bottom: 5
      vertical-scrollbar: areaListScroll

    VerticalScrollBar
      id: areaListScroll
      anchors.top: areaList.top
      anchors.bottom: areaList.bottom
      anchors.right: areaList.right
      step: 14
      pixels-scroll: true

    TextEdit
      id: areaNameField
      tooltip: Nome da magia de area
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      margin-bottom: 5
      width: 130

    Button
      id: areaAddButton
      !text: tr('+')
      anchors.left: areaNameField.right
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-left: 3
      margin-bottom: 5

  Panel
    id: bottomBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 60

    Label
      id: amountLabel
      anchors.top: parent.top
      anchors.left: parent.left
      margin-left: 10
      margin-top: 3
      text: Qtd. monstros (area)

    HorizontalScrollBar
      id: amount
      anchors.top: amountLabel.bottom
      anchors.left: parent.left
      margin-left: 10
      width: 110
      minimum: 1
      maximum: 15
      step: 1

    Label
      id: amountValue
      anchors.verticalCenter: amount.verticalCenter
      anchors.left: amount.right
      margin-left: 6
      width: 20
      text: '0'

    Button
      id: closeButton
      !text: tr('Fechar')
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      margin-bottom: 5
      size: 70 21

  Panel
    id: cooldownPopup
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.centerIn: parent
    size: 240 130
    visible: false

    Label
      id: title
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 8
      font: sans-bold-16px
      color: orange
      text: Cooldown da magia

    Label
      id: spellNameLabel
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 8
      margin-left: 10
      margin-right: 10
      text-align: center
      text-auto-resize: true
      text-wrap: true
      color: white
      text: ''

    Label
      id: cooldownLabel
      anchors.top: prev.bottom
      anchors.left: parent.left
      margin-left: 15
      margin-top: 10
      text: Cooldown (seg)

    HorizontalScrollBar
      id: cooldown
      anchors.top: prev.bottom
      anchors.left: parent.left
      margin-left: 15
      margin-top: 3
      width: 130
      minimum: 0
      maximum: 120
      step: 1

    Label
      id: cooldownValue
      anchors.verticalCenter: cooldown.verticalCenter
      anchors.left: cooldown.right
      margin-left: 6
      width: 25
      text: '0'

    Button
      id: confirmButton
      !text: tr('Adicionar')
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.right: cancelButton.left
      margin-left: 10
      margin-right: 5
      margin-bottom: 8

    Button
      id: cancelButton
      !text: tr('Cancelar')
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      margin-bottom: 8
      width: 70
]], g_ui.getRootWidget());
antiRedUI.interface:hide();

local function hideLogicAntiRed()
    if not antiRedUI.interface:isVisible() then
        antiRedUI.interface:show();
    else
        antiRedUI.interface.cooldownPopup:setVisible(false);
        antiRedUI.interface:hide();
        antiRedUI.save();
    end
end

antiRedUI.interface.bottomBar.closeButton.onClick = hideLogicAntiRed;

antiRedUI.buttons.title.onClick = function(widget)
    antired_data.enabled = not antired_data.enabled;
    widget:setOn(antired_data.enabled);
    antiRedUI.save();
end

-- Abre a config com botao direito em qualquer parte da linha (painel, nao so o switch)
antiRedUI.buttons.onMouseRelease = function(self, mousePos, mouseButton)
    if mouseButton == 2 then
        hideLogicAntiRed();
    end
end

local function buildEntryAntiRed(parentList, listKey, entry, index)
    local label = setupUI(entryTemplateAntiRed, parentList);
    local cooldownTotal = entry.cooldownTotal or 0;
    label.text:setText(entry.spellName);
    if (cooldownTotal > 0) then
        label:setTooltip("Cooldown: " .. cooldownTotal .. "s");
    else
        label:setTooltip("Sem cooldown");
    end
    label.enabled:setChecked(entry.enabled);
    label.enabled.onClick = function()
        entry.enabled = not entry.enabled;
        label.enabled:setChecked(entry.enabled);
        antiRedUI.save();
    end
    label.remove.onClick = function()
        table.remove(antired_data[listKey], index);
        antiRedUI.save();
        antiRedUI.refreshLists();
    end
end

antiRedUI.refreshLists = function()
    antiRedUI.interface.leftPanel.targetList:destroyChildren();
    for index, entry in ipairs(antired_data.targetSpells) do
        buildEntryAntiRed(antiRedUI.interface.leftPanel.targetList, "targetSpells", entry, index);
    end
    antiRedUI.interface.rightPanel.areaList:destroyChildren();
    for index, entry in ipairs(antired_data.areaSpells) do
        buildEntryAntiRed(antiRedUI.interface.rightPanel.areaList, "areaSpells", entry, index);
    end
end

-- Guarda qual lista (targetSpells/areaSpells) e qual nome de magia
-- esta pendente enquanto o popup de cooldown esta aberto.
local pendingListKey = nil;
local pendingSpellName = nil;

local function openCooldownPopup(listKey, spellName)
    pendingListKey = listKey;
    pendingSpellName = spellName;
    local popup = antiRedUI.interface.cooldownPopup;
    popup.spellNameLabel:setText(spellName);
    popup.cooldown:setValue(0);
    popup.cooldownValue:setText('0');
    popup:setVisible(true);
end

antiRedUI.interface.cooldownPopup.cooldown.onValueChange = function(widget, value)
    antiRedUI.interface.cooldownPopup.cooldownValue:setText(tostring(value));
end

antiRedUI.interface.cooldownPopup.cancelButton.onClick = function()
    antiRedUI.interface.cooldownPopup:setVisible(false);
    pendingListKey = nil;
    pendingSpellName = nil;
end

antiRedUI.interface.cooldownPopup.confirmButton.onClick = function()
    if (not pendingListKey or not pendingSpellName) then
        antiRedUI.interface.cooldownPopup:setVisible(false);
        return;
    end
    local cooldownTotal = antiRedUI.interface.cooldownPopup.cooldown:getValue();
    table.insert(antired_data[pendingListKey], {
        spellName = pendingSpellName,
        enabled = true,
        cooldownTotal = cooldownTotal,
        cooldownTime = nil
    });
    antiRedUI.interface.cooldownPopup:setVisible(false);
    pendingListKey = nil;
    pendingSpellName = nil;
    antiRedUI.save();
    antiRedUI.refreshLists();
end

antiRedUI.interface.leftPanel.targetAddButton.onClick = function()
    local field = antiRedUI.interface.leftPanel.targetNameField;
    local spellName = field:getText():trim();
    if (not spellName or spellName:len() == 0) then return; end
    field:setText("");
    openCooldownPopup("targetSpells", spellName);
end

antiRedUI.interface.rightPanel.areaAddButton.onClick = function()
    local field = antiRedUI.interface.rightPanel.areaNameField;
    local spellName = field:getText():trim();
    if (not spellName or spellName:len() == 0) then return; end
    field:setText("");
    openCooldownPopup("areaSpells", spellName);
end

antiRedUI.interface.bottomBar.amount.onValueChange = function(widget, value)
    antired_data.amountOfMonsters = value;
    antiRedUI.interface.bottomBar.amountValue:setText(tostring(value));
    antiRedUI.save();
end

antiRedUI.onLoading = function()
    antiRedUI.buttons.title:setOn(antired_data.enabled);
    antiRedUI.interface.bottomBar.amount:setValue(antired_data.amountOfMonsters or 2);
    antiRedUI.interface.bottomBar.amountValue:setText(tostring(antired_data.amountOfMonsters or 2));
    antiRedUI.refreshLists();
end
antiRedUI.onLoading();

-- ============================================================
-- Macro principal (Anti-Red)
-- Macro anônima (sem nome) de propósito, pra não criar uma
-- entrada duplicada na lista de macros do bot além do painel
-- "Anti Red" (switch) que já representa este módulo.
-- A protecao (widget de bloqueio por causa de skull vermelho)
-- roda sempre. O cast automatico de magias (target/area) so
-- roda se o painel estiver habilitado (switch "Anti Red").
-- ============================================================
-- Rodava a 1ms (praticamente todo frame) fazendo um loop de spectators
-- inteiro a cada execucao -- isso sozinho ja gerava os "Slow macro"
-- que voce viu. 50ms (20x por segundo) e mais que rapido o suficiente
-- pra deteccao de red skull e reduz bastante o uso de CPU.
macro(50, function()
  local pos, monstersCount = pos(), 0
  if (player:getSkull() >= 3) then
    addAntiRedTime()
  end

  local specs = safeGetSpectators(true)
  for _, spec in ipairs(specs) do
    local specPos = spec:getPosition()
    local floorDiff = math.abs(specPos.z - pos.z)
    if (floorDiff > 3) then goto continue end

    if (spec ~= player and spec:isPlayer() and spec:getEmblem() ~= 1 and spec:getShield() < 3) then
      addAntiRedTime()
      break
    elseif (floorDiff == 0 and spec:isMonster() and getDistanceBetween(specPos, pos) == 1) then
      monstersCount = monstersCount + 1
    end
    ::continue::
  end

  if (storage.antiRedTime >= now) then
    antiRedTimeWidget:show()
    local diff = storage.antiRedTime - now
    diff = diff / 1000
    antiRedTimeWidget:setText(tr("Area blocked for %ds.", toInteger(diff)))
    antiRedTimeWidget:setColor("red")
  elseif (not antiRedTimeWidget:isHidden()) then
    antiRedTimeWidget:hide()
  end

  if (not antired_data.enabled) then return end

  local castNow = os.time();
  local function castIfReady(entry)
      if (not entry.enabled) then return; end
      if (entry.cooldownTime and entry.cooldownTime > castNow) then return; end
      -- "-1" pula o delay de "digitacao" padrao do say(), igual o
      -- Combo.lua e o haste do Misc.lua ja fazem para magias que
      -- precisam ser instantaneas. Sem isso, trocar de magia de area
      -- pra target (ou vice-versa) fica preso no delay padrao do say().
      say(entry.spellName, -1);
      local cooldownTotal = entry.cooldownTotal or 0;
      if (cooldownTotal > 0) then
          entry.cooldownTime = castNow + cooldownTotal;
      end
  end

  -- Se permitido, usa os feitiços de área (respeita a quantidade de monstros configurada)
  if (monstersCount >= (antired_data.amountOfMonsters or 2) and storage.antiRedTime < now) then
    for _, entry in ipairs(antired_data.areaSpells) do
      castIfReady(entry);
    end
    return
  end

  -- Se está atacando, usa os feitiços de target
  if (not g_game.isAttacking()) then return end
  for _, entry in ipairs(antired_data.targetSpells) do
    castIfReady(entry);
  end
end)
