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
local tab = string["char"](9);
local lineBreak = string["char"](10);
local quote = string["char"](34);
local comma = string["char"](44);
local _G = modules["_G"];

local make_indent = function(state)
	return tab:rep(state["currentIndentLevel"] * state["indent"]);
end

local encode_table = function(val, state)
	local res = {};
	
	local pretty = state["indent"] > 0;
	
	local close_indent = make_indent(state);
	local comma = pretty and comma .. lineBreak or comma;
	local equals = pretty and " = " or "=";
	local open_brace = pretty and "{" .. lineBreak or "{";
	local close_brace = pretty and (lineBreak .. close_indent .. "}") or "}";
	
	
	local is_list = table["isList"](val);
	
	if (is_list) then
	
		for _, v in ipairs(val) do
			state["currentIndentLevel"] = state["currentIndentLevel"] + 1;
			table["insert"](res, make_indent(state) .. __encode__(v, state));
			state["currentIndentLevel"] = state["currentIndentLevel"] - 1;
		end
	else
		
		for k, v in pairs(val) do
			state["currentIndentLevel"] = state["currentIndentLevel"] + 1;
			table["insert"](res, make_indent(state) .. "[" .. __encode__(k, state) .. "]" .. equals .. __encode__(v, state));
			state["currentIndentLevel"] = state["currentIndentLevel"] - 1;
		end
	
	end
	
	
	return open_brace .. table["concat"](res, comma) .. close_brace;
end

local encoding_map = {
	["nil"] = tostring,
	["boolean"] = tostring,
	["number"] = tostring,
	["string"] = function(str, state)
		return json["encode"](str, state["indent"]);
	end,
	["table"] = encode_table
};

__encode__ = function(obj, state)
	local obj_type = type(obj);
	local f = encoding_map[obj_type];
	
	if (f) then
		return f(obj, state);
	end
	
	return "";
end

tyrBot["encodeLua"] = function(obj, indent)
	local state = {
		indent = indent or 0,
		currentIndentLevel = 0
	};
	return __encode__(obj, state);
end

local load_script = "\tlocal data = %s;\n\tif (table.recursivecopy ~= nil) then\n\t\treturn table.recursivecopy(data);\n\tend\n\treturn data;\n";

tyrBot["decodeLua"] = function(file)
	local status, result = pcall(function()
		local content = g_resources["readFileContents"](file);
		return assert(load(tr(load_script, content)))(); 
	end)
	
	if (not status) then
		modules["_G"]["error"]("Erro enquanto lia a config de " .. file .. ". Resultado: " .. result .. ", Voc\195\170 pode deletar o arquivo para resolver o problema.");
		return;
	end
	return result;
end

local worldNameFile = "/shazam_scripts/world_name.txt";
local oldWorldNameFile = "/shazam_scripts/misc/world_name.txt";
tyrBot["getWorldName"] = function()
	if (not g_resources["fileExists"](worldNameFile)) then
		local worldName = g_game["getWorldName"]():trim();
		if (g_resources["fileExists"](oldWorldNameFile)) then
			worldName = g_resources["readFileContents"](oldWorldNameFile);
			g_resources["deleteFile"](oldWorldNameFile);
		end
		g_resources["writeFileContents"](worldNameFile, worldName);
	end
	
	local worldName = g_resources["readFileContents"](worldNameFile);
	return worldName:gsub("[^%w%s]", "");
end

local worldName = tyrBot["getWorldName"]();
local characterName = g_game["getCharacterName"]();
local addEvent = (_G or modules["_G"])["addEvent"];

tyrBot["storage"] = {};

tyrBot["getStoragePath"] = function(file)
	if (file == nil) then
		file = characterName;
	end
	local path = tr("/shazam_scripts/storage/%s/%s.lua", worldName, file);
	return path;
end


tyrBot["loadStorage"] = function(file)
	if (file == nil) then
		file = characterName;
	end
	local path = tyrBot["getStoragePath"](file);
	if (g_resources["fileExists"](path)) then
		tyrBot["storage"] = tyrBot["decodeLua"](path);
	end
end

tyrBot["saveStorage"] = function()
	local path = tyrBot["getStoragePath"](characterName);

	local content = tyrBot["encodeLua"](tyrBot["storage"], 1);
	g_resources["writeFileContents"](path, content);
end

if (not g_resources["fileExists"](tyrBot["getStoragePath"]())) then
	local storage_dir = "/shazam_scripts/storage";
	local server_dir = storage_dir .. "/" .. worldName;
	local dirs = {storage_dir, server_dir};
	for _, dir in ipairs(dirs) do
		if (not g_resources["directoryExists"](dir)) then
			g_resources["makeDir"](dir);
		end
	end
	tyrBot["saveStorage"]();
end

tyrBot["loadStorage"]();
onExitRegister(tyrBot["saveStorage"]);




	



	
	
		
	
