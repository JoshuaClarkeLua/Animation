local Debug = {}

function Debug.drawRay(origin: Vector3, direction: Vector3, autoDestroy: boolean?)
	local p = Instance.new('Part')
	p.Size = Vector3.new(.1,.1,direction.Magnitude)
	p.CFrame = CFrame.new(origin, origin + direction) * CFrame.new(0,0,-p.Size.Z/2)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	task.defer(function()
		p.Parent = workspace
		if autoDestroy then
			task.delay(.1, function()
				p:Destroy()
			end)
		end
	end)
	return p
end

return Debug