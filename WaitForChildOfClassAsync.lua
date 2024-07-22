local function WaitForChildOfClassAsync(instance: Instance, className: string)
	local child = instance:FindFirstChildOfClass(className)
	
	while not child do
		child = instance.ChildAdded:Wait()
		child = instance:FindFirstChildOfClass(className)
	end
	return child
end

return WaitForChildOfClassAsync

