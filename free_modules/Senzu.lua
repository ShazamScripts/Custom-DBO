-- FREE: compatibilidade segura para executar sem o loader tyrBot original.
if (type(tyrBot) ~= "table") then
    tyrBot = {};
end

if (type(FREE_ENSURE_TYRBOT_COMPAT) ~= "function") then
    FREE_ENSURE_TYRBOT_COMPAT = function()
        if (type(tyrBot) ~= "table") then
            tyrBot = {};
        end

        tyrBot["configData"] = tyrBot["configData"] or {};
        tyrBot["storage"] = tyrBot["storage"] or storage or {};

        local compatStorage = tyrBot["storage"];
        compatStorage["task"] = compatStorage["task"] or {};
        compatStorage["taskData"] = compatStorage["taskData"] or {};
        compatStorage["widgetPos"] = compatStorage["widgetPos"] or {};
        compatStorage["checkBoxs"] = compatStorage["checkBoxs"] or {};
        compatStorage["_configs"] = compatStorage["_configs"] or {};
        compatStorage["_configs"]["cavebot_configs"] = compatStorage["_configs"]["cavebot_configs"] or {};
        compatStorage["_configs"]["targetbot_configs"] = compatStorage["_configs"]["targetbot_configs"] or {};

        tyrBot["getWorldName"] = tyrBot["getWorldName"] or function()
            local game = g_game or (modules and modules["_G"] and modules["_G"]["g_game"]);
            local worldName = game and type(game["getWorldName"]) == "function" and game["getWorldName"]() or "";
            return tostring(worldName):gsub("[^%w%s]", "");
        end;

        tyrBot["saveStorage"] = tyrBot["saveStorage"] or function()
            if (type(saveConfig) == "function") then
                return saveConfig();
            end
        end;
    end
end

FREE_ENSURE_TYRBOT_COMPAT();
if (tyrBot["configData"] == nil) then
  tyrBot["configData"] = {};
end
local configData = tyrBot["configData"];
configData["senzu"] = {};

-- ==========================================================
-- PAINEL PEQUENO (switch mestre, igual ao Mystic) — interface original
-- ==========================================================
local botUI = setupUI("Panel\n  height: 17\n\n  BotSwitch\n    id: switch\n    anchors.top: parent.top\n    anchors.left: parent.left\n    anchors.right: parent.right\n    text-align: center\n    !text: tr(\"Senzu\")\n\n    image-source:\n\n    $on:\n      color: green\n\n    $!on:\n      color: white\n");

-- ==========================================================
-- JANELA DE CONFIGURAÇÃO (3 senzus: Red / Green / Root) — interface original
-- ==========================================================
local mainUI = setupUI("MainWindow\n  size: 250 400\n  color: #A020F0\n  !text: tr(\"Senzu - Shazam Scripts\")\n  @onEscape: self:hide();\n\n  Panel\n    id: mainPanel\n    image-source: /images/ui/panel_flat\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    anchors.left: parent.left\n    anchors.right: parent.right\n    image-border: 6\n\n    Panel\n      id: redPanel\n      anchors.top: parent.top\n      anchors.left: parent.left\n      anchors.right: parent.right\n      margin-top: 5\n      margin-left: 5\n      margin-right: 5\n      height: 90\n\n      Item\n        id: icon\n        anchors.top: parent.top\n        anchors.left: parent.left\n        size: 24 24\n\n      Label\n        !text: tr(\"Senzu Red\")\n        anchors.top: parent.top\n        anchors.left: icon.right\n        margin-left: 6\n\n      CheckBox\n        id: enabled\n        !tooltip: tr(\"Disable\")\n        anchors.top: parent.top\n        anchors.right: parent.right\n\n      Label\n        !text: tr(\"HP\")\n        anchors.top: icon.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: hpScroll\n        anchors.top: icon.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n      Label\n        !text: tr(\"Mana\")\n        anchors.top: hpScroll.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: manaScroll\n        anchors.top: hpScroll.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n      Label\n        !text: tr(\"CD ms\")\n        anchors.top: manaScroll.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: cooldownScroll\n        anchors.top: manaScroll.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n    Panel\n      id: greenPanel\n      anchors.top: redPanel.bottom\n      anchors.left: parent.left\n      anchors.right: parent.right\n      margin-top: 5\n      margin-left: 5\n      margin-right: 5\n      height: 90\n\n      Item\n        id: icon\n        anchors.top: parent.top\n        anchors.left: parent.left\n        size: 24 24\n\n      Label\n        !text: tr(\"Senzu Green\")\n        anchors.top: parent.top\n        anchors.left: icon.right\n        margin-left: 6\n\n      CheckBox\n        id: enabled\n        !tooltip: tr(\"Disable\")\n        anchors.top: parent.top\n        anchors.right: parent.right\n\n      Label\n        !text: tr(\"HP\")\n        anchors.top: icon.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: hpScroll\n        anchors.top: icon.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n      Label\n        !text: tr(\"Mana\")\n        anchors.top: hpScroll.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: manaScroll\n        anchors.top: hpScroll.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n      Label\n        !text: tr(\"CD ms\")\n        anchors.top: manaScroll.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: cooldownScroll\n        anchors.top: manaScroll.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n    Panel\n      id: rootPanel\n      anchors.top: greenPanel.bottom\n      anchors.left: parent.left\n      anchors.right: parent.right\n      margin-top: 5\n      margin-left: 5\n      margin-right: 5\n      height: 90\n\n      Item\n        id: icon\n        anchors.top: parent.top\n        anchors.left: parent.left\n        size: 24 24\n\n      Label\n        !text: tr(\"Senzu Root\")\n        anchors.top: parent.top\n        anchors.left: icon.right\n        margin-left: 6\n\n      CheckBox\n        id: enabled\n        !tooltip: tr(\"Disable\")\n        anchors.top: parent.top\n        anchors.right: parent.right\n\n      Label\n        !text: tr(\"HP\")\n        anchors.top: icon.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: hpScroll\n        anchors.top: icon.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n      Label\n        !text: tr(\"Mana\")\n        anchors.top: hpScroll.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: manaScroll\n        anchors.top: hpScroll.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n      Label\n        !text: tr(\"CD ms\")\n        anchors.top: manaScroll.bottom\n        anchors.left: parent.left\n        margin-top: 5\n\n      HorizontalScrollBar\n        id: cooldownScroll\n        anchors.top: manaScroll.bottom\n        anchors.right: parent.right\n        anchors.left: prev.right\n        margin-top: 5\n        margin-left: 5\n\n    Button\n      id: closeButton\n      !text: tr(\"Close\")\n      anchors.right: parent.right\n      anchors.left: parent.left\n      anchors.bottom: parent.bottom\n      margin-top: 2\n      height: 20\n", g_ui["getRootWidget"]());

-- ==========================================================
-- CONFIG / STORAGE
-- ==========================================================
if (type(storage["configSenzu"]) ~= "table") then
  storage["configSenzu"] = {
    macroActive = false;

    red = {
      itemId = 11863;
      name = "Senzu Red";
      enabled = true;
      hpCast = 100;
      manaCast = 99;
      cooldown = 5000;
      time = 0;
    };
    green = {
      itemId = 11862;
      name = "Senzu Green";
      enabled = true;
      hpCast = 100;
      manaCast = 99;
      cooldown = 5000;
      time = 0;
    };
    root = {
      itemId = 11861;
      name = "Senzu Root";
      enabled = true;
      hpCast = 100;
      manaCast = 99;
      cooldown = 5000;
      time = 0;
    };
  };
end

local config = storage["configSenzu"];

-- texto que aparece na tela quando a senzu é usada (igual pras 3)
local possibleTexts = {
  "aaahhh! bem melhor!",
  "aaahhh!",
  "bem melhor!",
};

local potionOrder = {"red", "green", "root"};
local lastUsedKey = nil;

-- ==========================================================
-- LIGA OS WIDGETS DE CADA PAINEL AOS DADOS DO STORAGE (igual antes)
-- ==========================================================
local setupScroll = function(widget, targetTable, id, step, minimum, maximum, ms)
  widget:setStep(step or 1);
  widget:setMinimum(minimum or 0);
  widget:setMaximum(maximum or 100);

  local eol = ms and "ms" or "%";
  widget["onValueChange"] = function(widget, value)
    widget:setValue(value);
    widget:setText(value .. eol);
    targetTable[id] = value;
  end
  widget:onValueChange(targetTable[id]);
end

local setupCheckBox = function(widget, targetTable, id)
  widget["onCheckChange"] = function(widget, checked)
    widget:setChecked(checked);
    targetTable[id] = checked;
    widget:setTooltip(checked and tr("Disable") or tr("Enable"));
  end
  widget:onCheckChange(targetTable[id]);
end

local setupPotionPanel = function(panel, data)
  panel["icon"]:setItemId(data["itemId"]);
  setupCheckBox(panel["enabled"], data, "enabled");
  setupScroll(panel["hpScroll"], data, "hpCast", 1, 0, 100);
  setupScroll(panel["manaScroll"], data, "manaCast", 1, 0, 100);
  setupScroll(panel["cooldownScroll"], data, "cooldown", 100, 0, 30000, true);
end

setupPotionPanel(mainUI["mainPanel"]["redPanel"], config["red"]);
setupPotionPanel(mainUI["mainPanel"]["greenPanel"], config["green"]);
setupPotionPanel(mainUI["mainPanel"]["rootPanel"], config["root"]);

-- ==========================================================
-- SWITCH MESTRE + ABRIR CONFIG COM BOTÃO DIREITO (igual antes)
-- ==========================================================
botUI["switch"]["onClick"] = function()
  local status = not config["macroActive"];
  botUI["switch"]:setOn(status);
  config["macroActive"] = status;
end

botUI["onMouseRelease"] = function(self, mousePos, mouseButton)
  if mouseButton == 2 then
    mainUI:show();
  end
end

mainUI["mainPanel"]["closeButton"]["onClick"] = function(widget)
  mainUI:hide();
end

botUI["switch"]:setOn(config["macroActive"]);
mainUI:hide();

-- ==========================================================
-- ÍCONES NA TELA (addIcon, nativo do bot) — só ativa/desativa
-- cada senzu; não muda em nada a interface acima.
-- ==========================================================
local addSenzuScreenIcon = function(key)
  local data = config[key];

  addIcon(key, {item = data["itemId"], text = data["name"]}, function(icon, isOn)
    data["enabled"] = isOn;

    -- mantém o checkbox da janela de config sincronizado
    local panel = mainUI["mainPanel"][key .. "Panel"];
    if (panel and panel["enabled"]) then
      panel["enabled"]:setChecked(isOn);
    end

    -- botão direito no ícone também abre a janela de config
    icon["onMouseRelease"] = function(widget, mousePos, mouseButton)
      if (mouseButton == 2) then
        mainUI:show();
      end
    end
  end);
end

addSenzuScreenIcon("red");
addSenzuScreenIcon("green");
addSenzuScreenIcon("root");

-- ==========================================================
-- MACRO PRINCIPAL (igual antes)
-- ==========================================================
macro(100, function()
  if (not config["macroActive"]) then return; end

  local selfHealth, selfMana = hppercent(), manapercent();

  for _, key in ipairs(potionOrder) do
    local data = config[key];
    if (data["enabled"]) then
      local onCooldown = data["time"] > now;
      if (not onCooldown) then
        if (selfHealth <= data["hpCast"] or selfMana <= data["manaCast"]) then
          lastUsedKey = key;
          useWith(data["itemId"], player);
          break; -- usa só uma por ciclo
        end
      end
    end
  end
end);

-- ==========================================================
-- APLICA O COOLDOWN QUANDO A MENSAGEM DE CONFIRMAÇÃO APARECE
-- ==========================================================
onTalk(function(name, level, mode, text, channelId, pos)
  if (player:getName() ~= name) then return; end

  text = text:trim():lower();
  for _, possibleText in ipairs(possibleTexts) do
    local filterText = possibleText:trim():lower();
    if (text:find(filterText)) then
      if (lastUsedKey and config[lastUsedKey]) then
        config[lastUsedKey]["time"] = now + config[lastUsedKey]["cooldown"];
      end
      break;
    end
  end
end);

configData["senzu"]["macro"] = botUI["switch"];