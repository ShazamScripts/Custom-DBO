local queue = {};
local addEvent = modules["_G"]["addEvent"];

isOnQueue = function(func)
	return table["find"](queue, func);
end

putOnQueue = function(func)
	if (isOnQueue(func)) then
		return;
	end
	
	table["insert"](queue, func);
end

macro(50, function() 
	local currentCall = queue[1];
	if (currentCall == nil) then return; end
	
	addEvent(currentCall, true);
	table["remove"](queue, 1);
end)
-- FIX (Slow macro): antes esta macro tinha ["timeout"] = 1, ou seja,
-- qualquer execucao acima de 1ms (mesmo uma oscilacao normal do client)
-- disparava o aviso "Slow macro". O padrao do bot (~100ms) ja e suficiente
-- para esta macro, que so olha o topo da fila e despacha 1 chamada.