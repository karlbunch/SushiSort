
local L = {}
local bankSort = false;
local guildSort = false;
local moves = {};
local depth = 0;
local frame = CreateFrame("Frame");
local t = 0;
local interval = 0.01;
local current = nil;
local log = {};
local debugFrame = tekDebug and tekDebug:GetFrame("SushiSort")

local DETAIL_DEBUG = "DEBUG";
local DETAIL_BAG = "BAG";
local DETAIL_MISC = "MISC";
local DETAIL_SORT = "SORT";
local DETAIL_MOVE = "MOVE";
local DETAIL_COMPARE = "COMPARE";
local DETAIL_EVENT = "EVENT";
local DETAIL_STARTUP = "STARTUP";

local function Log(detail, msg)
--    if detail == DETAIL_DEBUG then
--        DEFAULT_CHAT_FRAME:AddMessage(detail..":"..msg);
--    end
--
--    table.insert(log, msg);
--
--    if SUSHISORT ~= nil then
--        SUSHISORT.log = log;
--    end
end

local function ClearLog()
    log = {};
end

local function GetIDFromLink(link)
    Log(DETAIL_MISC, "GetIDFromLink("..tostring(link)..")");
    return link and tonumber(string.match(link, "item:(%d+)"));
end

local function DoMoves()
    Log(DETAIL_MOVE, "DoMoves()");

    while (current ~= nil or #moves > 0) do
	DEFAULT_CHAT_FRAME:AddMessage("Sorter Moves left: " .. #moves);
        if current ~= nil then    
            Log(DETAIL_MOVE, "current.id = "..tostring(current.id));
            if CursorHasItem() then
                Log(DETAIL_MOVE, "Cursor Has Item");
                local type, id = GetCursorInfo();
                Log(DETAIL_MOVE, "type = "..tostring(type)..", id = "..tostring(id));
                if current ~= nil and current.id == id then
                    if current.sourcebag ~= nil then
                        Log(DETAIL_MOVE, "PickupContainerItem("..current.targetbag..", "..current.targetslot..")");

                        PickupContainerItem(current.targetbag, current.targetslot);

            	        local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                        if current.id ~= GetIDFromLink(link) then
                            return;
                        end
                    end
                else
                    Log(DETAIL_MOVE, "Sort Aborted");
                    DEFAULT_CHAT_FRAME:AddMessage(SUSHISORT_STATUS_SORT_ABORTED);
                    moves = {};
                    current = nil;
                    frame:Hide();
                    return;
                end
            else
                if current.sourcebag ~= nil then
        	        local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                    if current.id ~= GetIDFromLink(link) then
                        Log(DETAIL_MOVE, "Got Here");
                        return;
                    end
                end
                current = nil;
            end
        else      
            Log(DETAIL_MOVE, "current == nil");
            if #moves > 0 then
                Log(DETAIL_MOVE, #moves.." > 0");
        
                current = table.remove(moves, 1);

                if current.sourcebag ~= nil then
                    Log(DETAIL_MOVE, "PickupContainerItem("..current.sourcebag..", "..current.sourceslot..")");
                    PickupContainerItem(current.sourcebag, current.sourceslot);
                    if CursorHasItem() == false then
                        return;
                    end 
                    
                    Log(DETAIL_MOVE, "PickupContainerItem("..current.targetbag..", "..current.targetslot..")");
                    PickupContainerItem(current.targetbag, current.targetslot);
        	        local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                    if current.id == GetIDFromLink(link) then
                        Log(DETAIL_MOVE, "current = nil");
                        current = nil;
                    else
                        return;
                    end
                else
                    Log(DETAIL_MOVE, "PickupGuildBankItem("..current.sourcetab..", "..current.sourceslot..")");
                    PickupGuildBankItem(current.sourcetab, current.sourceslot);    
                    Log(DETAIL_MOVE, "PickupGuildBankItem("..current.targettab..", "..current.targetslot..")");
                    PickupGuildBankItem(current.targettab, current.targetslot);    
                    if CursorHasItem() then
                        PickupGuildBankItem(current.sourcetab, current.sourceslot);    
                    end
                    current = nil;
                    return;
                end

            end        
        end
    end
    Log(DETAIL_MOVE, "Sorted!");
    DEFAULT_CHAT_FRAME:AddMessage(SUSHISORT_STATUS_SORTED);
    frame:Hide();
end

local function CompareItems(lItem, rItem)
    Log(DETAIL_COMPARE, "CompareItems("..lItem.name..", "..rItem.name..")");

    if rItem.id == nil then
        Log(DETAIL_COMPARE, "rItem.id == nil");
        return true;
    elseif lItem.id == nil then
        Log(DETAIL_COMPARE, "lItem.id == nil");
        return false;
    elseif lItem.quality ~= rItem.quality then
        Log(DETAIL_COMPARE, "lItem.quality ~= rItem.quality");
        return (lItem.quality > rItem.quality);
    elseif lItem.class ~= rItem.class then
        Log(DETAIL_COMPARE, "lItem.class ~= rItem.class");
        return (lItem.class < rItem.class);
    elseif lItem.subclass ~= rItem.subclass then
        Log(DETAIL_COMPARE, "lItem.subclass ~= rItem.subclass");
        return (lItem.subclass < rItem.subclass);
    elseif lItem.name ~= rItem.name then
        Log(DETAIL_COMPARE, "lItem.name ~= rItem.name");
        return (lItem.name < rItem.name);
    elseif lItem.count ~= rItem.count then
        Log(DETAIL_COMPARE, "lItem.count ~= rItem.count");
        return (lItem.count >= rItem.count);
    else
        Log(DETAIL_COMPARE, "return true");
        return true;
    end
end

local function BeginSort()
    Log(DETAIL_MISC, "BeginSort()");
    current = nil;
    moves = {};
    ClearCursor();
end

local function CreateMove(source, target)
    local move = {};
    if source.id ~= nil then
        move.id = source.id;
        move.name = source.name;
        move.sourcebag = source.bag;
        move.sourcetab = source.tab;
        move.sourceslot = source.slot;
        move.targetbag = target.bag;
        move.targettab = target.tab;
        move.targetslot = target.slot;
    else
        move.id = target.id;
        move.name = target.name;
        move.sourcebag = target.bag;
        move.sourcetab = target.tab;
        move.sourceslot = target.slot;
        move.targetbag = source.bag;
        move.targettab = source.tab;
        move.targetslot = source.slot;
    end
    return move;    
end

local function SortBag(bag)
    Log(DETAIL_SORT, "SortBag(bag)");
    
    for i=1,#bag,1 do
        Log(DETAIL_SORT, "i = "..i);
        local lowest = i;
        for j = #bag, i + 1, -1 do
            Log(DETAIL_SORT, "j = "..j);
            if (CompareItems(bag[lowest],bag[j]) == false) then
                Log(DETAIL_SORT, "lowest = "..j);
                lowest = j;
            end
        end
        if i ~= lowest then
            Log(DETAIL_SORT, "i ~= lowest");

            -- store move
            local move = CreateMove(bag[lowest], bag[i]);
            table.insert(moves, move);
            Log(DETAIL_SORT, "move "..move.name.." from "..move.sourceslot.." to "..move.targetslot);
            
            -- swap items
            local tmp = bag[i];
            bag[i] = bag[lowest];
            bag[lowest] = tmp;

            Log(DETAIL_SORT, "bag[i] = "..bag[i].name.."("..bag[i].slot.."), bag[lowest] = "..bag[lowest].name.."("..bag[lowest].slot..")");

            -- swap slots
            tmp = bag[i].slot;
            bag[i].slot = bag[lowest].slot;
            bag[lowest].slot = tmp;
            tmp = bag[i].bag;
            bag[i].bag = bag[lowest].bag;
            bag[lowest].bag = tmp;
            tmp = bag[i].tab;
            bag[i].tab = bag[lowest].tab;
            bag[lowest].tab = tmp;

            Log(DETAIL_SORT, "bag[i] = "..bag[i].name.."("..bag[i].slot.."), bag[lowest] = "..bag[lowest].name.."("..bag[lowest].slot..")");
        end
    end
end

local function SortBagReverse(bag)
    Log(DETAIL_SORT, "SortBag(bag)");
    
    for i=#bag, 1, -1 do
        Log(DETAIL_SORT, "i = "..i);
        local lowest = i;
        for j = 1, i - 1, 1 do
            Log(DETAIL_SORT, "j = "..j);
            if (CompareItems(bag[lowest],bag[j]) == false) then
                Log(DETAIL_SORT, "lowest = "..j);
                lowest = j;
            end
        end
        if i ~= lowest then
            Log(DETAIL_SORT, "i ~= lowest");

            -- store move
            local move = CreateMove(bag[lowest], bag[i]);
            table.insert(moves, move);
            Log(DETAIL_SORT, "move "..move.name.." from "..move.sourceslot.." to "..move.targetslot);
            
            -- swap items
            local tmp = bag[i];
            bag[i] = bag[lowest];
            bag[lowest] = tmp;

            Log(DETAIL_SORT, "bag[i] = "..bag[i].name.."("..bag[i].slot.."), bag[lowest] = "..bag[lowest].name.."("..bag[lowest].slot..")");

            -- swap slots
            tmp = bag[i].slot;
            bag[i].slot = bag[lowest].slot;
            bag[lowest].slot = tmp;
            tmp = bag[i].bag;
            bag[i].bag = bag[lowest].bag;
            bag[lowest].bag = tmp;
            tmp = bag[i].tab;
            bag[i].tab = bag[lowest].tab;
            bag[lowest].tab = tmp;

            Log(DETAIL_SORT, "bag[i] = "..bag[i].name.."("..bag[i].slot.."), bag[lowest] = "..bag[lowest].name.."("..bag[lowest].slot..")");
        end
    end
end

local function CreateBagFromID(bagID)
    Log(DETAIL_BAG, "CreateBagFromID("..bagID..")");

    local items = GetContainerNumSlots(bagID);
    local bag = {};

    Log(DETAIL_BAG, "items = "..items);

	for i=1, items, 1 do
	    local item = {};

        Log(DETAIL_BAG, "i = "..i);

	    local _, count, _, _, _, _, link = GetContainerItemInfo(bagID, i);
	    item.bag = bagID;
	    item.slot = i;
	    item.name = "<EMPTY>";
        item.id = GetIDFromLink(link);
        if item.id ~= nil then
            item.count = count;
            item.name, _, item.quality, _, _, item.class, item.subclass, _, item.type, _, item.price = GetItemInfo(item.id);
        end

        Log(DETAIL_BAG, "item = "..item.name);

        table.insert(bag, item);
    end
    return bag;
end

local function CreateBagFromTab(tab)
    Log(DETAIL_BAG, "CreateBagFromTab("..tab..")");

    local items = MAX_GUILDBANK_SLOTS_PER_TAB or 98;
    local bag = {};

    Log(DETAIL_BAG, "items = "..items);

	for i=1, items, 1 do
	    local item = {};

        Log(DETAIL_BAG, "i = "..i);

	    local _, count = GetGuildBankItemInfo(tab, i);
	    local link = GetGuildBankItemLink(tab, i);
	    item.tab = tab;
	    item.slot = i;
	    item.name = "<EMPTY>";
        item.id = GetIDFromLink(link);
        if item.id ~= nil then
            item.count = count;
            item.name, _, item.quality, _, _, item.class, item.subclass, _, item.type, _, item.price = GetItemInfo(item.id);
        end
        table.insert(bag, item);

        Log(DETAIL_BAG, "item = "..item.name);
    end
    return bag;
end

local function SUSHISORT_BagSortButton(self) 
    ClearLog();

    Log(DETAIL_MISC, "SUSHISORT_BagSortButton(self)");
    local bags = {};

	for i=0, NUM_BAG_FRAMES, 1 do
	    local framenum = i + 1;
        if _G["ContainerFrame"..framenum.."SortCheck"]:GetChecked() then
            Log(DETAIL_MISC, "Bag #"..i.." is checked");
            local bag = CreateBagFromID(i);
            local type = select(2, GetContainerNumFreeSlots(i));

            type = tostring(type);
            Log(DETAIL_MISC, "type = "..type);

            if bags[type] == nil then
                Log(DETAIL_MISC, "bags[type] == nil");
                bags[type] = bag; 
            else
                Log(DETAIL_MISC, "bags[type] ~= nil");
                Log(DETAIL_MISC, "#bags[type] = "..#bags[type]);
                for j=1, #bag, 1 do
                    table.insert(bags[type], bag[j]);
                end
                Log(DETAIL_MISC, "#bags[type] = "..#bags[type]);
            end
        end
    end

    BeginSort();
    for k,v in pairs(bags) do
	    if v ~= nil then
            Log(DETAIL_MISC, "k = "..k..", v ~= nli");
            if SUSHISORT.Reverse then
                SortBagReverse(v);
            else
    	        SortBag(v);
    	    end
	    end   
    end        
    interval = 0.01;
    frame:Show();
end

local function SUSHISORT_BankSortButton(self) 
    ClearLog();

    Log(DETAIL_MISC, "SUSHISORT_BankSortButton(self)");
    local bags = {};

    if _G["BankFrameSortCheck"]:GetChecked() then
          Log(DETAIL_MISC, "Bank is checked");
        bags["0"] = CreateBagFromID(-1);
    end
    
	for i=NUM_BAG_FRAMES+1, NUM_CONTAINER_FRAMES, 1 do
	    local framenum = i + 1;
	    local frame = _G["ContainerFrame"..framenum.."SortCheck"];
        if frame ~= nil and frame:GetChecked() then
            Log(DETAIL_MISC, "Bag #"..i.." is checked");
            local bag = CreateBagFromID(i);
            local type = select(2, GetContainerNumFreeSlots(i));

            type = tostring(type);
            Log(DETAIL_MISC, "type = "..type);

            if bags[type] == nil then
                Log(DETAIL_MISC, "bags[type] == nil");
                bags[type] = bag; 
            else
                Log(DETAIL_MISC, "bags[type] ~= nil");
                Log(DETAIL_MISC, "#bags[type] = "..#bags[type]);
                for j=1, #bag, 1 do
                    table.insert(bags[type], bag[j]);
                end
                Log(DETAIL_MISC, "#bags[type] = "..#bags[type]);
            end
        end
    end

    BeginSort();
    for k,v in pairs(bags) do
	    if v ~= nil then
            Log(DETAIL_MISC, "k = "..k..", v ~= nli");
            if SUSHISORT.Reverse then
                SortBagReverse(v);
            else
    	        SortBag(v);
    	    end
	    end   
    end        
    interval = 0.01;
    frame:Show();
end

local function SUSHISORT_GuildSortButton(self) 
    ClearLog();

    Log(DETAIL_MISC, "SUSHISORT_GuildSortButton(self)");
    local bag = CreateBagFromTab(GetCurrentGuildBankTab());
    if SUSHISORT.Reverse then
        SortBagReverse(bag);
    else
        SortBag(bag);
    end
    interval = 1;
    frame:Show();
end

function SUSHISORT_SlashCommand(cmd, arg2)
    Log(DETAIL_EVENT, "SUSHISORT_SlashCommand("..tostring(cmd)..", "..tostring(arg2)..")");
    if cmd == "bags" then
        SUSHISORT_BagSortButton(nil);
    elseif cmd == "bank" then
        SUSHISORT_BankSortButton(nil);
    elseif cmd == "gbank" then
        SUSHISORT_GuildSortButton(nil);
    else
        InterfaceOptionsFrame_OpenToCategory(SUSHISORT_TITLE); 
    end
end

local function CreateSortCheck(name, parent, x, y)
    Log(DETAIL_STARTUP, "CreateSortCheck("..name..", parent, "..x..", "..y..", handler)");

    local checkButton = CreateFrame("CheckButton", name, parent, "SUSHISORTCheckTemplate");
    checkButton.parentFrame = parent;
    checkButton:SetChecked(true);
	checkButton.tooltipText = SUSHISORT_INCLUDE_TIP;
    checkButton:ClearAllPoints();
    checkButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);

    if SUSHISORT.IsEnabled == true then
        Log(DETAIL_STARTUP, "Showing Check Button");
        checkButton:Show();
    else
        Log(DETAIL_STARTUP, "Hiding Check Button");
        checkButton:Hide();
    end
end

local function CreateSortButton(name, parent, x, y, handler)
    Log(DETAIL_STARTUP, "CreateSortButton("..name..", parent, "..x..", "..y..", handler)");

    local sortButton = CreateFrame("Button", name, parent, "UIPanelButtonTemplate");
    sortButton.parentFrame = parent;
    sortButton:SetWidth(100);
    sortButton:SetHeight(16);
    sortButton:SetText(SUSHISORT_SORT);
    sortButton:ClearAllPoints();
    sortButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);

    if SUSHISORT.IsEnabled == true then
        Log(DETAIL_STARTUP, "Showing Sort Button");
        sortButton:Show();
    else
        Log(DETAIL_STARTUP, "Hiding Sort Button");
        sortButton:Hide();
    end

    sortButton:SetScript("OnClick", handler);
end

function SUSHISORT_MainFrame_OnLoad(self)
    Log(DETAIL_STARTUP, "SUSHISORT_MainFrame_OnLoad(self)");

    local fEnable = true;
    local fReverse = false;
    local fAltLoc = false;
    if SUSHISORT ~= nil and SUSHISORT.IsEnabled ~= nil then
        Log(DETAIL_STARTUP, "SUSHISORT ~= nil and SUSHISORT.IsEnabled ~= nil");
        fEnable = SUSHISORT.IsEnabled;
        fReverse = SUSHISORT.Reverse; 
        fAltLoc = SUSHISORT.AltLoc;
    end

    SUSHISORT = {};
    Log(DETAIL_STARTUP, "SUSHISORT = {};");
    SUSHISORT.IsEnabled = fEnable;
    Log(DETAIL_STARTUP, "SUSHISORT.IsEnabled = "..tostring(SUSHISORT.IsEnabled));
    SUSHISORT.Reverse = fReverse;
    Log(DETAIL_STARTUP, "SUSHISORT.Reverse = "..tostring(SUSHISORT.Reverse));
    SUSHISORT.AltLoc = fAltLoc;
    Log(DETAIL_STARTUP, "SUSHISORT.AltLoc = "..tostring(SUSHISORT.AltLoc));

    L = 
    {
	    SUSHISORT_OPTIONSPANEL_CREDITS1 = "Sushi Sort was designed and built by the guildies of <Sushi Regular> on US-Draka.",
    	SUSHISORT_OPTIONSPANEL_CREDITS2 = "Check out our website at http://www.sushi-regular.com",
    	SUSHISORT_OPTIONSPANEL_ENABLE = "Enable Sort",
    	SUSHISORT_OPTIONSPANEL_ENABLE_TIP = "Enable or disable this addon without uninstalling it.",
    	SUSHISORT_OPTIONSPANEL_REVERSE = "Reverse Order",
    	SUSHISORT_OPTIONSPANEL_REVERSE_TIP = "Reverse the order of the sort so grey items and empty space ends up in your backpack.",
    	SUSHISORT_OPTIONSPANEL_ALTGUILD = "Alternate Location",
    	SUSHISORT_OPTIONSPANEL_ALTGUILD_TIP = "Use an alternate location for the sort button on the guild bank tab.",
    	SUSHISORT_OPTIONSPANEL_SETTINGS = "Sushi Sort Settings",
        SUSHISORT_SORT = "Sort";
        SUSHISORT_INCLUDE_TIP = "Include this bag when sorting?";
    	SUSHISORT_TITLE = "Sushi Sort",
        SUSHISORT_STATUS_SORTED = "Sorted!";
        SUSHISORT_STATUS_SORT_ABORTED = "Sort Aborted";
    	SUSHISORT_LOAD_BANNER_1 = "Sushi Sort 3.3.5 Loaded";
    	SUSHISORT_LOAD_BANNER_2 = "To access settings use \"/ss\"";
    	SUSHISORT_BROKER_TIP_1 = "<Left Click> to sort your inventory";
        SUSHISORT_BROKER_TIP_2 = "<Shift Left Click> to sort your bank";
        SUSHISORT_BROKER_TIP_3 = "<Alt Left Click> to sort your guild bank";
        SUSHISORT_BROKER_TIP_4 = "<Right Click> to open options menu";
    }

    SUSHISORT_OPTIONSPANEL_CREDITS1 = L["SUSHISORT_OPTIONSPANEL_CREDITS1"];
	SUSHISORT_OPTIONSPANEL_CREDITS2 = L["SUSHISORT_OPTIONSPANEL_CREDITS2"];
	SUSHISORT_OPTIONSPANEL_ENABLE = L["SUSHISORT_OPTIONSPANEL_ENABLE"];
	SUSHISORT_OPTIONSPANEL_ENABLE_TIP = L["SUSHISORT_OPTIONSPANEL_ENABLE_TIP"];
	SUSHISORT_OPTIONSPANEL_REVERSE = L["SUSHISORT_OPTIONSPANEL_REVERSE"];
	SUSHISORT_OPTIONSPANEL_REVERSE_TIP = L["SUSHISORT_OPTIONSPANEL_REVERSE_TIP"];
   	SUSHISORT_OPTIONSPANEL_ALTGUILD = L["SUSHISORT_OPTIONSPANEL_ALTGUILD"];
   	SUSHISORT_OPTIONSPANEL_ALTGUILD_TIP = L["SUSHISORT_OPTIONSPANEL_ALTGUILD_TIP"];
	SUSHISORT_OPTIONSPANEL_SETTINGS = L["SUSHISORT_OPTIONSPANEL_SETTINGS"];
    SUSHISORT_SORT = L["SUSHISORT_SORT"];
    SUSHISORT_INCLUDE_TIP = L["SUSHISORT_INCLUDE_TIP"];
	SUSHISORT_TITLE = L["SUSHISORT_TITLE"];
    SUSHISORT_STATUS_SORTED = L["SUSHISORT_STATUS_SORTED"];
    SUSHISORT_STATUS_SORT_ABORTED = L["SUSHISORT_STATUS_SORT_ABORTED"];
	SUSHISORT_LOAD_BANNER_1 = L["SUSHISORT_LOAD_BANNER_1"];
	SUSHISORT_LOAD_BANNER_2 = L["SUSHISORT_LOAD_BANNER_2"];
	SUSHISORT_BROKER_TIP_1 = L["SUSHISORT_BROKER_TIP_1"];
    SUSHISORT_BROKER_TIP_2 = L["SUSHISORT_BROKER_TIP_2"];
    SUSHISORT_BROKER_TIP_3 = L["SUSHISORT_BROKER_TIP_3"];
    SUSHISORT_BROKER_TIP_4 = L["SUSHISORT_BROKER_TIP_4"];

	for i = 1, NUM_CONTAINER_FRAMES, 1 do
	    if i > 1 then
            CreateSortCheck("ContainerFrame"..i.."SortCheck", _G["ContainerFrame"..i], 42, -25)
	    else
            CreateSortCheck("ContainerFrame"..i.."SortCheck", _G["ContainerFrame"..i], 44, -4)
	    end
    end

    CreateSortButton("ContainerFrame1SortButton", _G["ContainerFrame1"], 64, -8, SUSHISORT_BagSortButton);

    frame:SetScript("OnUpdate", function(self, elapsed)
        Log(DETAIL_EVENT, "OnUpdate("..elapsed..")");
    	t = t + elapsed;
        Log(DETAIL_EVENT, "t = "..t);
    	if t > interval then
            Log(DETAIL_EVENT, "t > interval");
    		t = 0
            DoMoves();
    	end
    end)
    frame:Hide();

    if Bagnon ~= nil then
        Log(DETAIL_STARTUP, "Bagnon detected");
    	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	    if LDB ~= nil then
            Log(DETAIL_STARTUP, "LibStub found");
        	LDB:NewDataObject('SushiSortLauncher', {
        		type = 'launcher',
        		icon = [[Interface\Icons\INV_Misc_Bag_07]],
        		OnClick = function(_, button)
        			if button == 'LeftButton' then
		        		if IsShiftKeyDown() then
                            SUSHISORT_BankSortButton(nil);
        				elseif IsAltKeyDown() then
                            SUSHISORT_GuildSortButton(nil);
        				else
                            SUSHISORT_BagSortButton(nil);
        				end
        			elseif button == 'RightButton' then
                        InterfaceOptionsFrame_OpenToCategory(SUSHISORT_TITLE); 
        			end
        		end,
        		OnTooltipShow = function(tooltip)
        			if not tooltip or not tooltip.AddLine then return end
        			tooltip:AddLine(SUSHISORT_TITLE)
        			tooltip:AddLine(SUSHISORT_BROKER_TIP_1, 1, 1, 1)
        			tooltip:AddLine(SUSHISORT_BROKER_TIP_2, 1, 1, 1)
        			tooltip:AddLine(SUSHISORT_BROKER_TIP_3, 1, 1, 1)
        			tooltip:AddLine(SUSHISORT_BROKER_TIP_4, 1, 1, 1)
		        end,
        	})
        end
    end

    Log(DETAIL_STARTUP, "Displaying Banner");
    DEFAULT_CHAT_FRAME:AddMessage(SUSHISORT_LOAD_BANNER_1);
    DEFAULT_CHAT_FRAME:AddMessage(SUSHISORT_LOAD_BANNER_2);
    	
    Log(DETAIL_STARTUP, "Registering Events");
	self:RegisterEvent("BANKFRAME_OPENED");
	self:RegisterEvent("GUILDBANKFRAME_OPENED");
    self:RegisterEvent("VARIABLES_LOADED");
end

local function hook_GuildBankTab_OnClick(...)
    Log(DETAIL_EVENT, "hook_GuildBankTab_OnClick(...)");
    
    local tab = GetCurrentGuildBankTab();
    if tab > GetNumGuildBankTabs() then
        Log(DETAIL_EVENT, "(tab > GetNumGuildBankTabs())");
        _G["GBankFrameSortButton"]:Disable();
    else
        Log(DETAIL_EVENT, "else");
        _G["GBankFrameSortButton"]:Enable();
    end
end

function SUSHISORT_MainFrame_OnEvent(self, event, ...)
    Log(DETAIL_EVENT, "SUSHISORT_MainFrame_OnEvent(self, "..event..", ...)");
	if event == "BANKFRAME_OPENED" then 
        Log(DETAIL_EVENT, "event == BANKFRAME_OPENED");
	    if bankSort == false then
            Log(DETAIL_EVENT, "bankSort == false");
	        bankSort = true;
	        if _G["BankFrame"] ~= nil then
                CreateSortCheck("BankFrameSortCheck", _G["BankFrame"], 68, -10)
        	    CreateSortButton("BankFrameSortButton", _G["BankFrame"], 125, -35, SUSHISORT_BankSortButton);
        	end    
        end
        if SUSHISORT.IsEnabled == true then 
            Log(DETAIL_EVENT, "Show Bank Buttons");
            _G["BankFrameSortCheck"]:Show();
            _G["BankFrameSortButton"]:Show();
        else
            Log(DETAIL_EVENT, "Hide Bank Buttons");
            _G["BankFrameSortCheck"]:Hide();
            _G["BankFrameSortButton"]:Hide();
        end
	elseif event == "GUILDBANKFRAME_OPENED" then 
        Log(DETAIL_EVENT, "event == GUILDBANKFRAME_OPENED");
	    if guildSort == false then
            Log(DETAIL_EVENT, "guildSort == false");
	        guildSort = true;
	        if _G["GuildBankFrame"] ~= nil then
                if SUSHISORT.AltLoc == true then 
            	    CreateSortButton("GBankFrameSortButton", _G["GuildBankFrame"], 16, -380, SUSHISORT_GuildSortButton);
            	else
            	    CreateSortButton("GBankFrameSortButton", _G["GuildBankFrame"], 490, -36, SUSHISORT_GuildSortButton);
            	end
                hooksecurefunc("GuildBankTab_OnClick", hook_GuildBankTab_OnClick)
            end                
        end
        if SUSHISORT.IsEnabled == true then 
            Log(DETAIL_EVENT, "Show GBank Buttons");
            _G["GBankFrameSortButton"]:Show();
        else
            Log(DETAIL_EVENT, "Hide GBank Buttons");
            _G["GBankFrameSortButton"]:Hide();
        end
    elseif event == "VARIABLES_LOADED" then
        Log(DETAIL_EVENT, "event == VARIABLES_LOADED");
        InterfaceOptions_AddCategory(SUSHISORT_OptionsPanel);
	end
end

function SUSHISORT_OptionsPanel_OnOk(self)
    Log(DETAIL_EVENT, "SUSHISORT_OptionsPanel_OnOk(self)");

    SUSHISORT.IsEnabled = SUSHISORT_OptionsPanel_SortEnabled:GetChecked();
    Log(DETAIL_EVENT, "SUSHISORT.IsEnabled == "..tostring(SUSHISORT.IsEnabled));

    SUSHISORT.Reverse = SUSHISORT_OptionsPanel_ReverseOrder:GetChecked();
    Log(DETAIL_EVENT, "SUSHISORT.Reverse == "..tostring(SUSHISORT.Reverse));

    SUSHISORT.AltLoc = SUSHISORT_OptionsPanel_AltGuildButton:GetChecked();
    Log(DETAIL_EVENT, "SUSHISORT.AltLoc == "..tostring(SUSHISORT.AltLoc));

    if SUSHISORT.IsEnabled == true then
        Log(DETAIL_EVENT, "Enabling UI");
        _G["ContainerFrame1SortButton"]:Show();
        for i=1, NUM_CONTAINER_FRAMES, 1 do
    	    _G["ContainerFrame"..i.."SortCheck"]:Show();
        end

        if _G["BankFrameSortCheck"] ~= nil then 
            _G["BankFrameSortCheck"]:Show();
        end
        if _G["BankFrameSortButton"] ~= nill then 
            _G["BankFrameSortButton"]:Show();
        end
        if _G["GBankFrameSortButton"] ~= nil then 
            _G["GBankFrameSortButton"]:Show();
        end
    else
        Log(DETAIL_EVENT, "Hiding UI");
        _G["ContainerFrame1SortButton"]:Hide();
    	for i=1, NUM_CONTAINER_FRAMES, 1 do
    	    _G["ContainerFrame"..i.."SortCheck"]:Hide();
        end

        if _G["BankFrameSortCheck"] ~= nil then 
            _G["BankFrameSortCheck"]:Hide();
        end
        if _G["BankFrameSortButton"] ~= nill then 
            _G["BankFrameSortButton"]:Hide();
        end
        if _G["GBankFrameSortButton"] ~= nil then 
            _G["GBankFrameSortButton"]:Hide();
        end
    end
 end

function SUSHISORT_OptionsPanel_OnCancel(self)
    Log(DETAIL_EVENT, "SUSHISORT_OptionsPanel_OnCancel(self)");
    SUSHISORT_OptionsPanel_SortEnabled:SetChecked(SUSHISORT.IsEnabled);
    SUSHISORT_OptionsPanel_ReverseOrder:SetChecked(SUSHISORT.Reverse);
    SUSHISORT_OptionsPanel_AltGuildButton:SetChecked(SUSHISORT.AltLoc);
 end

function SUSHISORT_OptionsPanel_OnDefault(self)
    Log(DETAIL_EVENT, "SUSHISORT_OptionsPanel_OnDefault(self)");
    SUSHISORT.IsEnabled = true;
    SUSHISORT.Reverse = false;
    SUSHISORT_OptionsPanel_OnCancel()
 end

function SUSHISORT_OptionsPanel_OnRefresh(self)
    Log(DETAIL_EVENT, "SUSHISORT_OptionsPanel_OnRefresh(self)");
    SUSHISORT_OptionsPanel_OnCancel()
end

function SUSHISORT_OptionsPanel_OnLoad(panel)
    Log(DETAIL_EVENT, "SUSHISORT_OptionsPanel_OnLoad(panel)");
    panel.name = SUSHISORT_TITLE;
    panel.okay = SUSHISORT_OptionsPanel_OnOk;
    panel.cancel = SUSHISORT_OptionsPanel_OnCancel;
    panel.default = SUSHISORT_OptionsPanel_OnDefault;
    panel.refresh = SUSHISORT_OptionsPanel_OnRefresh;
    SUSHISORT_OptionsPanel_OnCancel();
end

SLASH_SUSHISORT1, SLASH_SUSHISORT2 = "/SS", "/SushiSort";
SlashCmdList["SUSHISORT"] = SUSHISORT_SlashCommand;

