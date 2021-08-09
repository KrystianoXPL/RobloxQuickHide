-- Author: MrKrystianoPL (aka. Lion Doge)

local TAG_PREFIX = "quickhide_4bf165c0_" -- Using random hex to limit the possibility of collision of tags.
local TAG_HIDDEN = "hidden"
local TAG_PARENT = "parent"

local selection = game:GetService("Selection")
local sStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local toolbar = plugin:CreateToolbar("QuickHide")
local hideButton = toolbar:CreateButton("Hide Selection", "Hides every selected object from view.", "")
hideButton.ClickableWhenViewportHidden = false
local unHideButton = toolbar:CreateButton("UnHide", "Unhides every object that was hidden.", "")
unHideButton.ClickableWhenViewportHidden = false

function HideSelection()
	local selectedObjects = selection:Get()
	
	local hiddenFolder = sStorage:FindFirstChild(TAG_PREFIX .. TAG_HIDDEN)
	if not hiddenFolder then
		hiddenFolder = Instance.new("Folder")
		hiddenFolder.Name = TAG_PREFIX .. TAG_HIDDEN
		hiddenFolder.Parent = sStorage
	end
	
	local success, result = pcall(function()
		if #selectedObjects > 0 then
			for idx, obj in pairs(selectedObjects) do
				if not obj:FindFirstChild(TAG_PREFIX .. TAG_PARENT) then
					local parentTag = Instance.new("ObjectValue")
					parentTag.Value = obj.Parent -- Saves the previous parent so that we know where to restore it to later.
					parentTag.Name = TAG_PREFIX .. TAG_PARENT
					parentTag.Parent = obj
					
					obj.Parent = hiddenFolder
				end
			end
		else
			print("QuickHide: No selected objects to hide!")
		end
	end)
	local waypointMessage = nil
	
	if success then
		selection:Remove(selectedObjects)
		waypointMessage = "Hidden " .. tostring(#selectedObjects) .. " objects"
	else
		print("QuickHide: ERROR! Some objects could not be hidden!")
		waypointMessage = "QuickHide Hide error"
	end
	
	ChangeHistoryService:SetWaypoint(waypointMessage)
end

function UnHide()
	local hiddenFolder = sStorage:FindFirstChild(TAG_PREFIX .. TAG_HIDDEN)
	if hiddenFolder then
		local hiddenFolderContents = hiddenFolder:GetChildren()
		if not hiddenFolder or #hiddenFolderContents <= 0 then
			print("QuickHide: Nothing to unhide")
			return
		end
		
		local success, result = pcall(function()
			for idx, obj in pairs(hiddenFolderContents) do
				local hiddenParentValue = obj:FindFirstChild(TAG_PREFIX .. TAG_PARENT)
				if not hiddenParentValue then
					print("QuickHide:" ,obj, "does not have the parent saved. It will be parented to Workspace instead.")
					obj.Parent = game.Workspace
				else
					obj.Parent = hiddenParentValue.Value
					hiddenParentValue:Destroy()
				end
			end
		end)
		
		
		local waypointMessage = nil
		
		local function onError()
			print("QuickHide: ERROR! Some objects could not be unhidden!")
			waypointMessage = "QuickHide Unhide error"
		end
		
		if success then
			-- Make extra sure that everything was restored properly
			if #hiddenFolder:GetChildren() <= 0 then
				hiddenFolder:Destroy()
			else
				onError()
			end
			waypointMessage = "Unhidden " .. tostring(#hiddenFolderContents) .. " objects"
			selection:Set(hiddenFolderContents)
		else
			onError()
		end
		
		ChangeHistoryService:SetWaypoint(waypointMessage)
	else
		print("QuickHide: Nothing to unhide!")
	end
end

hideButton.Click:connect(HideSelection)
unHideButton.Click:connect(UnHide)

