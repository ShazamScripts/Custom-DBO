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

        tyrBot["getAttackingCreature"] = tyrBot["getAttackingCreature"] or function()
            local game = g_game or (modules and modules["_G"] and modules["_G"]["g_game"]);
            if (game and type(game["getAttackingCreature"]) == "function") then
                return game["getAttackingCreature"]();
            end
            return nil;
        end;

        tyrBot["doAttack"] = tyrBot["doAttack"] or function(creature)
            if (not creature) then return false; end
            local game = g_game or (modules and modules["_G"] and modules["_G"]["g_game"]);
            if (game and type(game["attack"]) == "function") then
                game["attack"](creature);
                return true;
            end
            return false;
        end;

        tyrBot["getSpectators"] = tyrBot["getSpectators"] or function(...)
            if (type(getSpectators) == "function") then
                return getSpectators(...);
            end
            return {};
        end;

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

        tyrBot["friendList"] = tyrBot["friendList"] or {};
        tyrBot["friendList"]["isFriend"] = tyrBot["friendList"]["isFriend"] or function(name)
            if (type(name) ~= "string" and name and type(name.getName) == "function") then
                name = name:getName();
            end
            name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");
            local names = global_storage and global_storage["tyrFriendlist"] or storage and storage["tyrFriendlist"] or {};
            for _, friendName in ipairs(names) do
                local normalized = tostring(friendName):lower():gsub("^%s+", ""):gsub("%s+$", "");
                if (normalized == name) then
                    return true;
                end
            end
            return false;
        end;
        tyrBot["friendList"]["window"] = tyrBot["friendList"]["window"] or {
            show = function() end
        };
    end
end

FREE_ENSURE_TYRBOT_COMPAT();

-- Garante a tabela ANTES de qualquer uso (evita "bad argument #1 to
-- 'ipairs' (table expected, got nil)" se algo limpar o storage antes
-- deste modulo carregar).
global_storage["tyrFriendlist"] = global_storage["tyrFriendlist"] or {};

-- ============================================================
-- PERSISTENCIA PROPRIA (nao depende mais so do saveConfig nativo)
-- ============================================================
-- Problema real: "tyrFriendlist" e salva dentro do profile_N.json nativo.
-- Quando voce roda VARIAS contas na mesma pasta de custom, esse arquivo
-- e compartilhado por todas elas. Se a conta B salvar por QUALQUER outro
-- motivo (mudou uma config, fechou o client) enquanto ainda tem em
-- memoria a lista de amigos ANTIGA (sem o nome que voce acabou de
-- adicionar na conta A), essa gravacao da conta B sobrescreve o arquivo
-- inteiro e o nome novo desaparece -- mesmo com o saveConfig() sendo
-- chamado corretamente no addButton/remove.
--
-- Agora a lista tambem vive num arquivo proprio (fora do profile_N.json),
-- compartilhado por todas as contas do MESMO mundo, e cada conta faz
-- merge (nunca sobrescreve cegamente) com o que estiver no arquivo.
local worldName = tyrBot["getWorldName"] and tyrBot["getWorldName"]() or "";
local friendListDir = "/shazam_scripts/storage/" .. worldName;
local friendListFile = friendListDir .. "/_friendlist.json";

if not g_resources.directoryExists("/shazam_scripts") then
	g_resources.makeDir("/shazam_scripts");
end
if not g_resources.directoryExists("/shazam_scripts/storage") then
	g_resources.makeDir("/shazam_scripts/storage");
end
if not g_resources.directoryExists(friendListDir) then
	g_resources.makeDir(friendListDir);
end

local readSharedFriendList = function()
	if not g_resources.fileExists(friendListFile) then
		return {};
	end
	local ok, data = pcall(function()
		return json.decode(g_resources.readFileContents(friendListFile));
	end)
	if ok and type(data) == "table" then
		return data;
	end
	return {};
end

local writeSharedFriendList = function(list)
	local ok, encoded = pcall(function()
		return json.encode(list);
	end)
	if ok then
		g_resources.writeFileContents(friendListFile, encoded);
	else
		print("[Shazam Scripts] Aviso: falha ao salvar friend list: " .. tostring(encoded));
	end
end

-- Junta duas listas sem duplicar (case-insensitive), sem nunca perder um
-- nome que ja exista em qualquer uma das duas.
local mergeFriendLists = function(listA, listB)
	local merged = {};
	local seen = {};
	for _, list in ipairs({listA, listB}) do
		for _, name in ipairs(list) do
			local key = tostring(name):trim():lower();
			if key:len() > 0 and not seen[key] then
				seen[key] = true;
				table["insert"](merged, name);
			end
		end
	end
	return merged;
end

-- Na entrada: junta o que ja estava em memoria (vindo do profile_N.json)
-- com o que estiver no arquivo compartilhado, e grava o resultado nos
-- dois lugares. Isso recupera nomes que tenham sido "apagados" do
-- profile_N.json por outra conta, desde que o arquivo compartilhado
-- ainda os tenha.
global_storage["tyrFriendlist"] = mergeFriendLists(global_storage["tyrFriendlist"], readSharedFriendList());
writeSharedFriendList(global_storage["tyrFriendlist"]);

local friendList = {};

friendList["nameEntry"] = "UIWidget\n  background-color: alpha\n  text-offset: 3 1\n  focusable: true\n  height: 16\n  font: verdana-11px-rounded\n  text-align: left\n\n  $focus:\n    background-color: #00000055\n\n  Button\n    id: remove\n    !text: tr('X')\n    anchors.right: parent.right\n    anchors.verticalCenter: parent.verticalCenter\n    width: 14\n    height: 14\n    margin-right: 15\n    text-align: center\n    text-offset: 0 1\n    tooltip: Remover o nome da lista.\n";

friendList["window"] = setupUI("MainWindow\n  size: 180 295\n  !text: tr(\"Friend list\")\n  @onEscape: self:hide()\n\n  Panel\n    id: mainPanel\n    image-source: /images/ui/panel_flat\n    anchors.top: parent.top\n    anchors.bottom: parent.bottom\n    anchors.left: parent.left\n    anchors.right: parent.right\n    image-border: 6\n\n    Button\n      id: addButton\n      text: Add\n      anchors.top: parent.top\n      anchors.right: parent.right\n      size: 35 20\n\n    TextEdit\n      id: addText\n      anchors.top: prev.top\n      anchors.left: parent.left\n      anchors.right: prev.left\n      height: 20\n\n    TextList\n      id: playersList\n      anchors.left: parent.left\n      anchors.right: parent.right\n      anchors.top: prev.bottom\n      margin-top: 5\n      height: 180\n      image-border: 3\n      image-source: /images/ui/textedit\n      vertical-scrollbar: playersListScroll\n\n    VerticalScrollBar\n      id: playersListScroll\n      anchors.top: playersList.top\n      anchors.bottom: playersList.bottom\n      anchors.right: playersList.right\n      step: 10\n      pixels-scroll: true\n\n  Button\n    id: closeButton\n    !text: tr(\"Close\")\n    anchors.left: parent.left\n    anchors.right: parent.right\n    anchors.bottom: parent.bottom\n    @onClick: self:getParent():hide()\n", g_ui["getRootWidget"]());

friendList["window"]:setColor("white");
friendList["window"]:hide();
friendList["nameCache"] = {};

function friendList:parse()
	self["nameCache"] = {};
	global_storage["tyrFriendlist"] = global_storage["tyrFriendlist"] or {};
	for index, name in ipairs(global_storage["tyrFriendlist"]) do
		local newName = name:trim():lower();
		if (newName:len() == 0) then
			table["remove"](global_storage["tyrFriendlist"], name);
			return self:parse();
		end
		self["nameCache"][newName] = true;
	end
end

friendList["window"]["mainPanel"]["addButton"]["onClick"] = function()
	local widget = friendList["window"]["mainPanel"]["addText"];
	local name = widget:getText():trim();
	
	if (#name == 0) then return; end
	
	if (friendList["nameCache"][name:lower()]) then return; end
	
	table["insert"](global_storage["tyrFriendlist"], name);
	widget:setText("");
	friendList["refreshNames"]();
	-- Mantido por compatibilidade (grava no profile_N.json tambem), mas
	-- quem garante que o nome NAO se perde e a gravacao no arquivo
	-- proprio logo abaixo, que nao e sobrescrita por outra conta.
	if (type(saveConfig) == "function") then
		saveConfig();
	end
	writeSharedFriendList(global_storage["tyrFriendlist"]);
end

friendList["refreshNames"] = function()
	friendList:parse();
	
	for _, child in ipairs(friendList["window"]["mainPanel"]["playersList"]:getChildren()) do
		child:destroy();
	end
	
	for index, name in ipairs(global_storage["tyrFriendlist"]) do
		local widget = setupUI(friendList["nameEntry"], friendList["window"]["mainPanel"]["playersList"]);
		widget:setText(name:ucwords());
		widget["remove"]["onClick"] = function()
			table["remove"](global_storage["tyrFriendlist"], index);
			friendList["window"]["mainPanel"]["addText"]:setText(name:ucwords());
			friendList["refreshNames"]();
			if (type(saveConfig) == "function") then
				saveConfig();
			end
			writeSharedFriendList(global_storage["tyrFriendlist"]);
		end
		widget["onDoubleClick"] = widget["remove"]["onClick"];
	end
end

friendList["isFriend"] = function(name)
	if (type(name) ~= "string") then
		name = name:getName();
	end

	name = name:trim():lower();
	return friendList["nameCache"][name] ~= nil;
end

tyrBot["friendList"] = friendList;

if (global_storage["tyrFriendlist"] == nil) then
	global_storage["tyrFriendlist"] = {};
end

friendList["refreshNames"]();

-- Sincronizacao periodica: se outra conta (mesmo mundo) adicionar um
-- amigo enquanto esta conta ja esta logada, essa conta pega o nome novo
-- sem precisar desligar/religar o bot. So ADICIONA nomes novos do
-- arquivo (nunca remove nada automaticamente por causa de outra conta).
local function syncSharedFriendList()
	local shared = readSharedFriendList();
	local merged = mergeFriendLists(global_storage["tyrFriendlist"], shared);
	if #merged ~= #global_storage["tyrFriendlist"] then
		global_storage["tyrFriendlist"] = merged;
		friendList["refreshNames"]();
		writeSharedFriendList(merged);
	end
	schedule(20000, syncSharedFriendList);
end
schedule(20000, syncSharedFriendList);
