local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.Utilities.Signal) -- Require your own module hierarchy (or other)
local Connections = require(ReplicatedStorage.Utilities.Connections) -- ^
local WaitForChildOfClassAsync = require(ReplicatedStorage.Utilities.WaitForChildOfClassAsync) -- ^^
local CharacterLoadedWrapper = {}
CharacterLoadedWrapper.__index = CharacterLoadedWrapper

local function isPrimaryPartSet(character: Model)
	return if character.PrimaryPart then true else false
end

local function isHumanoidRootPartSet(humanoid: Humanoid)
	return if humanoid.RootPart then true else false
end

local function getHumanoid(character: Model)
	return character:FindFirstChildOfClass("Humanoid")
end

local function isHumanoidAlive(character: Model)
	local undHumanoid = getHumanoid(character)
	
	if not undHumanoid then
		return false
	end
	local humanoid = undHumanoid :: Humanoid
	
	return isHumanoidRootPartSet(humanoid) and humanoid.Health > 0
end




export type ClassType = typeof(setmetatable(
	{} :: {
		loaded: Signal.ClassType,
		died: Signal.ClassType,
		_player: Player,
		_destroyed: boolean,
		_connections: Connections.ClassType
	}, CharacterLoadedWrapper))


function CharacterLoadedWrapper.new(player: Player): ClassType
	local self = {
		loaded = Signal.new(),
		died = Signal.new(),
		_player = player,
		_destroyed = false,
		_connections = Connections.new()
	}
	setmetatable(self, CharacterLoadedWrapper)
	self:_listenForCharacterAdded()

	return self
end


function CharacterLoadedWrapper.isLoaded(self: ClassType, optionalCharacter: Model?)
	local undCharacter = optionalCharacter or self._player.Character 
	print("Undefined character is currently", undCharacter)
	if not undCharacter then
		print("Returned false from 'undefined character' check.")
		return false
	end
	
	local character = undCharacter :: Model
	
	print("Returned true from 'PrimaryPart', 'HumanoidAlive', and 'Descendant' check.")
	return isPrimaryPartSet(character) and isHumanoidAlive(character) and character:IsDescendantOf(Workspace)
end

function CharacterLoadedWrapper._listenForCharacterAdded(self: ClassType)
	task.spawn(function()
		local character = self._player.Character
		
		if character then
			if self:isLoaded() then
				self:_listenForDeath(character)
			else
				self:_waitForLoadedAsync(character)
			end
		end		
		
			local characterAddedConnection = self._player.CharacterAdded:Connect(function(newCharacter: Model)
				self:_waitForLoadedAsync(newCharacter)
			end)
			self._connections:add(characterAddedConnection)
	end)
end


function CharacterLoadedWrapper._waitForLoadedAsync(self: ClassType, character: Model)
	if not self:isLoaded() then
		if not character:IsDescendantOf(workspace) then
			character.AncestryChanged:Wait()
		end
		
		if character.Parent then
			if not isPrimaryPartSet(character) then
				character:GetPropertyChangedSignal("PrimaryPart"):Wait()
			end
			
			local undHumanoid = getHumanoid(character)
			if not undHumanoid then
				undHumanoid = WaitForChildOfClassAsync(character, "Humanoid")
			end
			
			local humanoid = undHumanoid :: Humanoid
			while not isHumanoidRootPartSet(humanoid) do
				humanoid.Changed:Wait()
			end
			
			if not self:isLoaded(character) then
				return
			end
		end
	end 
	
	if self._destroyed then
		return
	end
	
	self:_listenforDeath(character)
	self.loaded:Fire(character)
end

function CharacterLoadedWrapper._listenforDeath(self: ClassType, character: Model)
	local humanoid = getHumanoid(character) :: Humanoid
	local dead = false
	
	local diedConnection, removedConnection
	
	local function onDied()
		if dead then
			return
		end
		dead = true
		
		diedConnection:Disconnect()
		removedConnection:Disconnect()
		self.died:Fire(character)
	end
	diedConnection = humanoid.Died:Connect(onDied)
	removedConnection = character.AncestryChanged:Connect(function()
		if character.Parent == nil then
			onDied()
		end
	end)
	
	self._connections:add(diedConnection, removedConnection)
end

function CharacterLoadedWrapper.destroy(self: ClassType)
	self.loaded:DisconnectAll()
	self.died:DisconnectAll()
	self._destroyed = true
	
	self._connections:disconnect()
end


	

return CharacterLoadedWrapper
