-- Estado compartido del lock on entre los scripts del cliente.

local LockOn = {}

LockOn.Target = nil :: Model?

-- Posición a la que apuntar: el objetivo fijado si lo hay, si no, lo que haya bajo el ratón.
function LockOn.AimPosition(mouse: Mouse): Vector3
	local target = LockOn.Target
	local root = target and target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		return root.Position
	end
	return mouse.Hit.Position
end

return LockOn
