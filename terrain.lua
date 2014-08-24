terrain = {}

--[[
  
  0 = vide
  1_ = plat, niveau 0
  1u = ◢
  1d = ◣
  1^ = ■ (plat, niveau 1)
  2u = ◢ (deux blocs)
  2d = ◣ (deux blocs)
  2^ = ■ (deux blocs)
  
--]]
--[[terrain.t = {
	[-4] = "2^",
	[-3] = "2d",
	[-2] = "1d",
	[-1] = "1_",
	[0]  = "1_",
	[1]  = "1_",
	[2]  = "1u",
	[3]  = "1^",
	[4]  = "1d",
}]]
function terrain.init()
	terrain.t = {
		[0]  = "1_",
	}
	terrain.left = 0
	terrain.right = 0
	terrain.tunder = {
		[0] = "1_",
	}
	
	terrain.gen("gauche", 30)
	terrain.gen("droite", 30)
	
end
--[[ Règles de génération du terrain :
	
	  1_	gauche → "1_", "1d"
			droite → "1_", "1u"
	  
	  1u	gauche → "1_"
	  		droite → "2u", "1^"
	  
	  1d	gauche → "2d", "1^"
	  		droite → "1_"
	  
	  1^	gauche → "1^", "1u", "2d"
	  		droite → "1^", "1d", "2u"
	  
	  2u	gauche → "1u", "1^"
	  		droite → "2^", "2d"
	  
	  2d	gauche → "2^", "2u"
	  		droite → "1d", "1^"
	  
	  2^	gauche → "2^", "2u"
	  		droite → "2^", "2d"
	
--]]

gen_rules = {
	["1_"] = {gauche = {"1_", "1d"}, droite = {"1_", "1u"} },
	["1u"] = {gauche = {"1_"}, droite = {"2u", "1^"} }, 
	["1d"] = {gauche = {"2d", "1^"}, droite = {"1_"} },
	["1^"] = {gauche = {"1^", "1u", "2d"}, droite = {"1^", "1d", "2u"} },
	["2u"] = {gauche = {"1u", "1^"}, droite = {"2^", "2d"} },
	["2d"] = {gauche = {"2^", "2u"}, droite = {"1d", "1^"} },
	["2^"] = {gauche = {"2^", "2u"}, droite = {"2^", "2d"} }, 
}

function sup(t1, t2)
	-- doit renvoyer, de t1 ou t2, celui qui est le plus haut quand on est à la jonction des deux
end

function terrain.gen(dir, nb)
	local restant = nb or 10
	local start, possibles
	local pos
	
	love.math.setRandomSeed(love.timer.getTime())
	
	if dir == "gauche" then
		pos = terrain.left - 1
		
		while restant > 0 do
			possibles = gen_rules[terrain.t[pos+1]].gauche
			terrain.t[pos] = possibles[math.random(1,#possibles)]
			restant = restant-1
			pos = pos-1
		end
		terrain.left = pos+1
		
	elseif dir == "droite" then
		pos = terrain.right + 1
		
		while restant > 0 do
			possibles = gen_rules[terrain.t[pos-1]].droite
			terrain.t[pos] = possibles[math.random(1,#possibles)]
			restant = restant-1
			pos = pos+1
		end
		terrain.right = pos-1
	end
end

function terrain.collisions(x, y)
	--[[ plusieurs cas :
			- entièrement à l’intérieur d’une « case »
				- plate
				- pentue à gauche
				- pentue à droite
				[possibilité futures de murs verticaux ? gérer l’arrêt et non le téléportage en haut du mur]
			- à cheval sur deux cases
				- identiques
				- différentes : repérer laquelle est la plus haute
	
		OU ALORS :
			Ne pas se faire chier à regarder les cas où on est à cheval sur deux cases.
			On considère uniquement le point de référence du player (= entre les deux pieds).
		→ suffira peut-être pour la génération de terrain actuelle, mais pas avec les potentiels futurs murs verticaux
			→ possibilité de gérer à part ce cas particulier ?
	]]
	-- TODO: adapter la fonction à l’Underworld
	
	local newX = x
	local newY = y
	
	-- TODO: Régler la rotation
	local r = 0
	
	if not g.pjumping then
	
		g.t = terrain.t[math.floor(x)]
		g.rely = y-math.floor(y)
		g.relx = x-math.floor(x)
		if g.t == "1_" then
			if y < 0 then -- TODO: À l’avenir il faudra une certaine épaisseur au sol, mais peut-être que ça pourra rester en dessous du zéro ?
				newY = 0
				stopY()
			end
		elseif g.t == "1^" then
			if y <= 1 then
				newY = 1
				stopY()
			end
			
		elseif g.t == "2^" then
			if y < 2 then
				newY = 2
				stopY()
			end
			
		elseif g.t == "1u" then
			if y <= g.relx then
				newY = g.relx
				stopY()
				r = -45
			else
				g.pstanding = false
			end
			
		elseif g.t == "1d" then
			if y <= 1-g.relx then
				newY = 1-g.relx
				stopY()
				r = 45
			else
				g.pstanding = false
			end
			
		elseif g.t == "2u" then
			if y < 1 or (y < 2 and g.rely <= g.relx) then
				--print("if")
				newY = g.relx+1
				stopY()
				r = -45
			else
				-- problème quand g.rely > g.relx
				newY = newY+0.01
				g.pstanding = false
			end
		elseif g.t == "2d" then
			if y < 1 or (y < 2 and g.rely <= 1-g.relx) then
				newY = 2-g.relx
				stopY()
				r = 45
			else
				g.pstanding = false
			end
		end
	end
	
	return newX, newY, r
end

function stopY()
	g.pstanding = true
	g.pjumping = false
	g.pvY = 0
end	

function terrain.draw()
	local marge_sol = 5 -- 5 pixels de marge en bas
	for i,t in pairs(terrain.t) do
		if t == "2^" or t == "2u" or t == "2d" then
			off = 2*g.tile
		else
			off = g.tile
		end
		--print(t)
		love.graphics.draw(imgs_terrain[t], (i*g.tile + g.offsetX), (g.offsetY-off), 0, g.zoom, g.zoom)
	end
end