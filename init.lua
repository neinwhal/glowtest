-- Jungletree mod by Bas080.
-- License WTFPL.

	-- Forked by paramat.
	-- Perlin Jungletrees Ongen 0.1.0.
	-- License WTFPL as before, see license.txt file.

	-- Deleted habitat mod.
	-- Only find ground level in randomly chosen columns within biome.
	-- Only check for grass away from trunks when altitude <= MAXALT.
	-- Increased roots depth to 2 or 5 nodes.
	-- Fixed bug "if height <= 0 then" line 131.
	-- Jungletree function defined and spawn jungletrees on generated chunk.
	-- Deleted laggy "find_node_near" functions with large radius that checked for water and sand, now only check trunk spacing.
	-- Added debug messages option.
	-- Added remove default trees option.
	-- Perlin matched to snow biomes perlin(112, 3, 0.5, 150) to keep jungle away from snow biomes.
	-- Noise range for more biome shapes.
	-- Added abm to grow saplings into jungletrees.
	-- ONGEN option.
	-- Variables MINSPA and MAXSPA to control denstity at centre and edge.
	-- More red and yellow leaves.

local MAXALT = 23 -- 23 -- Maximum altitude.
local MINSPA = 2 -- 2 -- Minimum spacing to other trunks or roots in deep jungle.
local MAXSPA = 11 -- 11 -- Average spacing to other trunks or roots at jungle edge.
local NORMPLANT = 16

-- Snowy perlin. Should match your snow biomes mod perlin.
local SEEDDIFF = 112 -- 112 -- World specific perlin seed = world seed + seeddiff.
local OCTAVES = 3 -- 3 -- Each higher octave adds variation on a scale half as big.
local PERSISTENCE = 0.5 -- 0.5 -- Relative amplitude of each higher octave.
local SCALE = 150 -- 150 -- Scale of largest pattern variation.

local NOISEH = -0.6 -- -0.6 ]
local NOISEL = -1.2 -- -1.2 ] Noise range for jungle biome. Negative values keep jungle away from snow biomes. Snow biomes when noise > 0.53.

local SAPLING_ABM_INTERVAL = 23 -- 23
local SAPLING_ABM_CHANCE = 13 -- 13

local ONGEN = true -- Spawn jungletrees on generated chunk? (true / false).
local REMOVE_TREES = true -- Remove default trees on generated chunk in jungle biomes?
local DEBUG = true

local colchamin = MINSPA ^ 2
local factor = (MAXSPA ^ 2 - colchamin) * 4
local nav = (NOISEH + NOISEL) / 2
local nra = NOISEH - NOISEL

if ONGEN then
	minetest.register_on_generated(function(minp, maxp, seed)
		-- If generated chunk is a surface chunk
		if minp.y == -32 then
			-- Define perlin noise, co-ords of min and max points, chunk dimensions.
			local perlin = minetest.env:get_perlin(SEEDDIFF, OCTAVES, PERSISTENCE, SCALE)
			local x0 = minp.x
			local z0 = minp.z
			local x1 = maxp.x
			local z1 = maxp.z
			local xl = x1 - x0
			local zl = z1 - z0
			-- Speed hack: checks 9 points in chunk for conifer biome.
			if not (perlin:get2d({x=x0, y=z0}) > NOISEL and perlin:get2d({x=x0, y=z0}) < NOISEH)
			and not (perlin:get2d({x=x0, y=z1}) > NOISEL and perlin:get2d({x=x0, y=z1}) < NOISEH)
			and not (perlin:get2d({x=x1, y=z0}) > NOISEL and perlin:get2d({x=x1, y=z0}) < NOISEH)
			and not (perlin:get2d({x=x1, y=z1}) > NOISEL and perlin:get2d({x=x1, y=z1}) < NOISEH)
			and not (perlin:get2d({x=x0, y=z0+(zl/2)}) > NOISEL and perlin:get2d({x=x0, y=z0+(zl/2)}) < NOISEH)
			and not (perlin:get2d({x=x1, y=z0+(zl/2)}) > NOISEL and perlin:get2d({x=x1, y=z0+(zl/2)}) < NOISEH)
			and not (perlin:get2d({x=x0+(xl/2), y=z0}) > NOISEL and perlin:get2d({x=x0+(xl/2), y=z0}) < NOISEH)
			and not (perlin:get2d({x=x0+(xl/2), y=z1}) > NOISEL and perlin:get2d({x=x0+(xl/2), y=z1}) < NOISEH)
			and not (perlin:get2d({x=x0+(xl/2), y=z0+(zl/2)}) > NOISEL and perlin:get2d({x=x0+(xl/2), y=z0+(zl/2)}) < NOISEH) then
				return
			end

			if REMOVE_TREES == true then
				-- Remove default trees in chunk.
				local trees = minetest.env:find_nodes_in_area(minp, maxp, {"default:leaves","default:tree","default:apple"})
				for i,v in pairs(trees) do
					minetest.env:remove_node(v)
				end
				if DEBUG then
					print ("[jungletree] Trees removed ("..minp.x.." "..minp.y.." "..minp.z..")")
				end
			end
			-- Loop through all columns in chunk, for each column do.
			for i = 0, xl do
			for j = 0, zl do
				local x = x0 + i
				local z = z0 + j
				local noise = perlin:get2d({x = x, y = z})
				if noise > NOISEL and noise < NOISEH then
					-- Calculate column chance for varying tree density.
					local colcha = colchamin + math.floor(factor * (math.abs(noise - nav) / nra) ^ 2)
					if math.random(1,colcha) == 1 then
						-- Find ground level y.
						local ground_y = nil
						for y=maxp.y,minp.y,-1 do
							local nodename = minetest.env:get_node({x=x,y=y,z=z}).name
							if nodename ~= "air" and nodename ~= "default:water_source" then
								ground_y = y
								break
							end
						end
						-- Check if ground, check altitude
						if ground_y and ground_y <= MAXALT  then
							-- Check for grass, check trunk spacing
							local nodename = minetest.env:get_node({x=x,y=ground_y,z=z}).name
							local junnear = minetest.env:find_node_near({x=x,y=ground_y,z=z}, MINSPA, "default:jungletree")
							local defnear = minetest.env:find_node_near({x=x,y=ground_y,z=z}, MINSPA, "default:tree")
							if nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 16 then
								glowtest_sgreentree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 2 then
                                        glowtest_mgreentree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 3 then
                                        glowtest_lgreentree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 4 then
                                        glowtest_sbluetree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 5 then
                                        glowtest_mbluetree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 6 then
                                        glowtest_lbluetree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 7 then
                                        glowtest_spinktree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 8 then
                                        glowtest_mpinktree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 9 then
                                        glowtest_lpinktree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 10 then
                                        glowtest_syellowtree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 11 then
                                        glowtest_myellowtree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 12 then
                                        glowtest_lyellowtree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 13 then
                                        glowtest_swhitetree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 14 then
                                        glowtest_mwhitetree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:dirt_with_grass" and junnear == nil and defnear == nil and math.random(NORMPLANT) == 15 then
                                        glowtest_lwhitetree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:desert_sand" and math.random(NORMPLANT) == 16 then
								glowtest_sredtree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:desert_sand" and math.random(NORMPLANT) == 2 then
                                        glowtest_mredtree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:desert_sand" and math.random(NORMPLANT) == 3 then
                                        glowtest_lredtree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:desert_sand" and math.random(NORMPLANT) == 4 then
                                        glowtest_sblacktree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:desert_sand" and math.random(NORMPLANT) == 5 then
                                        glowtest_mblacktree({x=x,y=ground_y+1,z=z})
                                        elseif nodename == "default:desert_sand" and math.random(NORMPLANT) == 6 then
                                        glowtest_lblacktree({x=x,y=ground_y+1,z=z})
							end
						end
					end
				end
			end
			end
		end
	end)
end

minetest.register_node("glowtest:tree", {
	description = "Glowing Tree",
	tiles = {"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
	paramtype2 = "facedir",
	light_source = 8,
	groups = {tree=1,choppy=2,oddly_breakable_by_hand=1,flammable=2},
	sounds = default.node_sound_wood_defaults(),
     drop = "default:tree",
	on_place = minetest.rotate_node
})

minetest.register_node("glowtest:stonetree", {
	description = "Glowing Stone Tree",
	tiles = {"default_stone.png"},
	paramtype2 = "facedir",
	light_source = 8,
	groups = {tree=1,cracky=3},
	sounds = default.node_sound_wood_defaults(),
     drop = "default:stone",
	on_place = minetest.rotate_node
})

minetest.register_node("glowtest:blueleaf", {
	description = "Glowing Blue Leaf",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"glowtest_blueleaf.png"},
	paramtype = "light",
	light_source = 8,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{ items = {'glowtest:sbluesapling'}, rarity = 20},
			{ items = {'glowtest:mbluesapling'}, rarity = 40},
			{ items = {'glowtest:lbluesapling'}, rarity = 60},
			{ items = {'glowtest:blueleaf'} }
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("glowtest:redleaf", {
	description = "Glowing Blood Leaf",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"glowtest_redleaf.png"},
	paramtype = "light",
	light_source = 8,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{ items = {'glowtest:sredsapling'}, rarity = 20},
			{ items = {'glowtest:mredsapling'}, rarity = 40},
			{ items = {'glowtest:lredsapling'}, rarity = 60},
			{ items = {'glowtest:redleaf'} }
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("glowtest:blackleaf", {
	description = "Glowing Cursed Leaf",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"glowtest_blackleaf.png"},
	paramtype = "light",
	light_source = 8,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{ items = {'glowtest:sblacksapling'}, rarity = 20},
			{ items = {'glowtest:mblacksapling'}, rarity = 40},
			{ items = {'glowtest:lblacksapling'}, rarity = 60},
			{ items = {'glowtest:blackleaf'} }
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("glowtest:pinkleaf", {
	description = "Glowing Pink Leaf",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"glowtest_pinkleaf.png"},
	paramtype = "light",
	light_source = 8,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{ items = {'glowtest:spinksapling'}, rarity = 20},
			{ items = {'glowtest:mpinksapling'}, rarity = 40},
			{ items = {'glowtest:lpinksapling'}, rarity = 60},
			{ items = {'glowtest:pinkleaf'} }
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("glowtest:yellowleaf", {
	description = "Glowing Yellow Leaf",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"glowtest_yellowleaf.png"},
	paramtype = "light",
	light_source = 8,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{ items = {'glowtest:syellowsapling'}, rarity = 20},
			{ items = {'glowtest:myellowsapling'}, rarity = 40},
			{ items = {'glowtest:lyellowsapling'}, rarity = 60},
			{ items = {'glowtest:yellowleaf'} }
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("glowtest:greenleaf", {
	description = "Glowing Green Leaf",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"glowtest_greenleaf.png"},
	paramtype = "light",
	light_source = 8,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{ items = {'glowtest:sgreensapling'}, rarity = 20},
			{ items = {'glowtest:mgreensapling'}, rarity = 40},
			{ items = {'glowtest:lgreensapling'}, rarity = 60},
			{ items = {'glowtest:greenleaf'} }
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("glowtest:whiteleaf", {
	description = "Glowing White Leaf",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"glowtest_whiteleaf.png"},
	paramtype = "light",
	light_source = 8,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{ items = {'glowtest:swhitesapling'}, rarity = 20},
			{ items = {'glowtest:mwhitesapling'}, rarity = 40},
			{ items = {'glowtest:lwhitesapling'}, rarity = 60},
			{ items = {'glowtest:whiteleaf'} }
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("glowtest:glow_ore", {
	description = "Limestone Ore",
	tiles = {"default_dirt.png^glowtest_glow_ore.png"},
	is_ground_content = true,
    light_source = 4,
	groups = {cracky=3},
	drop = {
		max_items = 2,
		items = {
			{ items = {'glowtest:sgreensapling'}, rarity = 20},
			{ items = {'glowtest:mgreensapling'}, rarity = 40},
			{ items = {'glowtest:lgreensapling'}, rarity = 60},
			{ items = {'glowtest:sbluesapling'}, rarity = 20},
			{ items = {'glowtest:mbluesapling'}, rarity = 40},
			{ items = {'glowtest:lbluesapling'}, rarity = 60},
			{ items = {'glowtest:spinksapling'}, rarity = 20},
			{ items = {'glowtest:mpinksapling'}, rarity = 40},
			{ items = {'glowtest:lpinksapling'}, rarity = 60},
			{ items = {'glowtest:syellowsapling'}, rarity = 20},
			{ items = {'glowtest:myellowsapling'}, rarity = 40},
			{ items = {'glowtest:lyellowsapling'}, rarity = 60},
			{ items = {'glowtest:swhitesapling'}, rarity = 20},
			{ items = {'glowtest:mwhitesapling'}, rarity = 40},
			{ items = {'glowtest:lwhitesapling'}, rarity = 60},
			{ items = {'glowtest:glowlump'} }
		}
	},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("glowtest:glow_ore_cursed", {
	description = "Limestone Ore",
	tiles = {"default_desert_stone.png^glowtest_cursed_glow_ore.png"},
	is_ground_content = true,
    light_source = 4,
	groups = {cracky=3},
	drop = {
		max_items = 2,
		items = {
			{ items = {'glowtest:sblacksapling'}, rarity = 20},
			{ items = {'glowtest:mblacksapling'}, rarity = 40},
			{ items = {'glowtest:lblacksapling'}, rarity = 60},
			{ items = {'glowtest:sredsapling'}, rarity = 20},
			{ items = {'glowtest:mredsapling'}, rarity = 40},
			{ items = {'glowtest:lredsapling'}, rarity = 60},
			{ items = {'glowtest:glowlump_cursed'} }
		}
	},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("glowtest:sgreensapling", {
	description = "Small Green Sapling",
	drawtype = "plantlike",
	visual_scale = 0.7,
	tiles = {"glowtest_greensapling.png"},
	inventory_image = "glowtest_greensapling.png",
	wield_image = "glowtest_greensapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
     selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("glowtest:mgreensapling", {
	description = "Medium Green Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"glowtest_greensapling.png"},
	inventory_image = "glowtest_greensapling.png",
	wield_image = "glowtest_greensapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:lgreensapling", {
	description = "Large Green Sapling",
	drawtype = "plantlike",
	visual_scale = 2.0,
	tiles = {"glowtest_greensapling.png"},
	inventory_image = "glowtest_greensapling.png",
	wield_image = "glowtest_greensapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:sbluesapling", {
	description = "Small Blue Sapling",
	drawtype = "plantlike",
	visual_scale = 0.7,
	tiles = {"glowtest_bluesapling.png"},
	inventory_image = "glowtest_bluesapling.png",
	wield_image = "glowtest_bluesapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
     selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("glowtest:mbluesapling", {
	description = "Medium Blue Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"glowtest_bluesapling.png"},
	inventory_image = "glowtest_bluesapling.png",
	wield_image = "glowtest_bluesapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:lbluesapling", {
	description = "Large Blue Sapling",
	drawtype = "plantlike",
	visual_scale = 2.0,
	tiles = {"glowtest_bluesapling.png"},
	inventory_image = "glowtest_bluesapling.png",
	wield_image = "glowtest_bluesapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:spinksapling", {
	description = "Small Pink Sapling",
	drawtype = "plantlike",
	visual_scale = 0.7,
	tiles = {"glowtest_pinksapling.png"},
	inventory_image = "glowtest_pinksapling.png",
	wield_image = "glowtest_pinksapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
     selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("glowtest:mpinksapling", {
	description = "Medium Pink Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"glowtest_pinksapling.png"},
	inventory_image = "glowtest_pinksapling.png",
	wield_image = "glowtest_pinksapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:lpinksapling", {
	description = "Large Pink Sapling",
	drawtype = "plantlike",
	visual_scale = 2.0,
	tiles = {"glowtest_pinksapling.png"},
	inventory_image = "glowtest_pinksapling.png",
	wield_image = "glowtest_pinksapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:syellowsapling", {
	description = "Small Yellow Sapling",
	drawtype = "plantlike",
	visual_scale = 0.7,
	tiles = {"glowtest_yellowsapling.png"},
	inventory_image = "glowtest_yellowsapling.png",
	wield_image = "glowtest_yellowsapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
     selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("glowtest:myellowsapling", {
	description = "Medium Yellow Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"glowtest_yellowsapling.png"},
	inventory_image = "glowtest_yellowsapling.png",
	wield_image = "glowtest_yellowsapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:lyellowsapling", {
	description = "Large Yellow Sapling",
	drawtype = "plantlike",
	visual_scale = 2.0,
	tiles = {"glowtest_yellowsapling.png"},
	inventory_image = "glowtest_yellowsapling.png",
	wield_image = "glowtest_yellowsapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:sredsapling", {
	description = "Small Blood Sapling",
	drawtype = "plantlike",
	visual_scale = 0.7,
	tiles = {"glowtest_redsapling.png"},
	inventory_image = "glowtest_redsapling.png",
	wield_image = "glowtest_redsapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
     selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("glowtest:mredsapling", {
	description = "Medium Blood Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"glowtest_redsapling.png"},
	inventory_image = "glowtest_redsapling.png",
	wield_image = "glowtest_redsapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:lredsapling", {
	description = "Large Blood Sapling",
	drawtype = "plantlike",
	visual_scale = 2.0,
	tiles = {"glowtest_redsapling.png"},
	inventory_image = "glowtest_redsapling.png",
	wield_image = "glowtest_redsapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:swhitesapling", {
	description = "Small White Sapling",
	drawtype = "plantlike",
	visual_scale = 0.7,
	tiles = {"glowtest_whitesapling.png"},
	inventory_image = "glowtest_whitesapling.png",
	wield_image = "glowtest_whitesapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
     selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("glowtest:mwhitesapling", {
	description = "Medium White Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"glowtest_whitesapling.png"},
	inventory_image = "glowtest_whitesapling.png",
	wield_image = "glowtest_whitesapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:lwhitesapling", {
	description = "Large White Sapling",
	drawtype = "plantlike",
	visual_scale = 2.0,
	tiles = {"glowtest_whitesapling.png"},
	inventory_image = "glowtest_whitesapling.png",
	wield_image = "glowtest_whitesapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:rune_1", {
	description = "Wyvern's Soul Rune",
	tiles = {"default_stone.png^glowtest_rune_1.png"},
	is_ground_content = true,
    light_source = 14,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("glowtest:rune_2", {
	description = "Eye Rune",
	tiles = {"default_stone.png^glowtest_rune_2.png"},
	is_ground_content = true,
    light_source = 14,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("glowtest:sblacksapling", {
	description = "Small Cursed Sapling",
	drawtype = "plantlike",
	visual_scale = 0.7,
	tiles = {"glowtest_blacksapling.png"},
	inventory_image = "glowtest_blacksapling.png",
	wield_image = "glowtest_blacksapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:mblacksapling", {
	description = "Medium Cursed Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"glowtest_blacksapling.png"},
	inventory_image = "glowtest_blacksapling.png",
	wield_image = "glowtest_blacksapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("glowtest:lblacksapling", {
	description = "Large Cursed Sapling",
	drawtype = "plantlike",
	visual_scale = 2.0,
	tiles = {"glowtest_blacksapling.png"},
	inventory_image = "glowtest_blacksapling.png",
	wield_image = "glowtest_blacksapling.png",
	paramtype = "light",
	walkable = false,
    light_source = 8,
	groups = {snappy=2,dig_immediate=3,flammable=2},
	sounds = default.node_sound_defaults(),
})

-- TREE FUNCTIONS

-- Green

function glowtest_sgreentree(pos)
	local t = 3 + math.random(2) -- trunk height
	for j = -2, t do
		if j == t or j == t - 2 then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:greenleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function glowtest_mgreentree(pos)
	local t = 6 + math.random(4) -- trunk height
	for j = -3, t do
		if j == math.floor(t * 0.7) or j == t then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:greenleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function add_tree_branch_green(pos)
	minetest.env:add_node(pos, {name="glowtest:tree"})
	for i = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
		for k = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
			local p = {x=pos.x+i, y=pos.y, z=pos.z+k}
			local n = minetest.env:get_node(p)
			if (n.name=="air") then
				minetest.env:add_node(p, {name="glowtest:greenleaf"})
			end
			local chance = math.abs(i+k)
			if (chance < 1) then
				p = {x=pos.x+i, y=pos.y+1, z=pos.z+k}
				n = minetest.env:get_node(p)
				if (n.name=="air") then
					minetest.env:add_node(p, {name="glowtest:greenleaf"})
				end
			end
		end
	end
end

function glowtest_lgreentree(pos)
    local height = 10 + math.random(5)
		if height < 10 then
			for i = height, -2, -1 do
				local p = {x=pos.x, y=pos.y+i, z=pos.z}
				minetest.env:add_node(p, {name="glowtest:tree"})
				if i == height then
					add_tree_branch_green({x=pos.x, y=pos.y+height+math.random(0, 1), z=pos.z})
					add_tree_branch_green({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_green({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_green({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1})
					add_tree_branch_green({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1})
				end
				if i < 0 then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1}, {name="glowtest:tree"})
				end
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_green(branch_pos)
				end
			end
		else
			for i = height, -5, -1 do
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_green(branch_pos)
				end
				if i < math.random(0,1) then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+2, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-2}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
				if i == height then
					add_tree_branch_green({x=pos.x+1, y=pos.y+i, z=pos.z+1})
					add_tree_branch_green({x=pos.x+2, y=pos.y+i, z=pos.z-1})
					add_tree_branch_green({x=pos.x, y=pos.y+i, z=pos.z-2})
					add_tree_branch_green({x=pos.x-1, y=pos.y+i, z=pos.z})
					add_tree_branch_green({x=pos.x+1, y=pos.y+i, z=pos.z+2})
					add_tree_branch_green({x=pos.x+3, y=pos.y+i, z=pos.z-1})
					add_tree_branch_green({x=pos.x, y=pos.y+i, z=pos.z-3})
					add_tree_branch_green({x=pos.x-2, y=pos.y+i, z=pos.z})
					add_tree_branch_green({x=pos.x+1, y=pos.y+i, z=pos.z})
					add_tree_branch_green({x=pos.x+1, y=pos.y+i, z=pos.z-1})
					add_tree_branch_green({x=pos.x, y=pos.y+i, z=pos.z-1})
					add_tree_branch_green({x=pos.x, y=pos.y+i, z=pos.z})
				else
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
			end
		end
end

-- Blue

function glowtest_sbluetree(pos)
	local t = 3 + math.random(2) -- trunk height
	for j = -2, t do
		if j == t or j == t - 2 then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:blueleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function glowtest_mbluetree(pos)
	local t = 6 + math.random(4) -- trunk height
	for j = -3, t do
		if j == math.floor(t * 0.7) or j == t then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:blueleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function add_tree_branch_blue(pos)
	minetest.env:add_node(pos, {name="glowtest:tree"})
	for i = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
		for k = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
			local p = {x=pos.x+i, y=pos.y, z=pos.z+k}
			local n = minetest.env:get_node(p)
			if (n.name=="air") then
				minetest.env:add_node(p, {name="glowtest:blueleaf"})
			end
			local chance = math.abs(i+k)
			if (chance < 1) then
				p = {x=pos.x+i, y=pos.y+1, z=pos.z+k}
				n = minetest.env:get_node(p)
				if (n.name=="air") then
					minetest.env:add_node(p, {name="glowtest:blueleaf"})
				end
			end
		end
	end
end

function glowtest_lbluetree(pos)
    local height = 10 + math.random(5)
		if height < 10 then
			for i = height, -2, -1 do
				local p = {x=pos.x, y=pos.y+i, z=pos.z}
				minetest.env:add_node(p, {name="glowtest:tree"})
				if i == height then
					add_tree_branch_blue({x=pos.x, y=pos.y+height+math.random(0, 1), z=pos.z})
					add_tree_branch_blue({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_blue({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_blue({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1})
					add_tree_branch_blue({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1})
				end
				if i < 0 then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1}, {name="glowtest:tree"})
				end
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_blue(branch_pos)
				end
			end
		else
			for i = height, -5, -1 do
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_blue(branch_pos)
				end
				if i < math.random(0,1) then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+2, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-2}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
				if i == height then
					add_tree_branch_blue({x=pos.x+1, y=pos.y+i, z=pos.z+1})
					add_tree_branch_blue({x=pos.x+2, y=pos.y+i, z=pos.z-1})
					add_tree_branch_blue({x=pos.x, y=pos.y+i, z=pos.z-2})
					add_tree_branch_blue({x=pos.x-1, y=pos.y+i, z=pos.z})
					add_tree_branch_blue({x=pos.x+1, y=pos.y+i, z=pos.z+2})
					add_tree_branch_blue({x=pos.x+3, y=pos.y+i, z=pos.z-1})
					add_tree_branch_blue({x=pos.x, y=pos.y+i, z=pos.z-3})
					add_tree_branch_blue({x=pos.x-2, y=pos.y+i, z=pos.z})
					add_tree_branch_blue({x=pos.x+1, y=pos.y+i, z=pos.z})
					add_tree_branch_blue({x=pos.x+1, y=pos.y+i, z=pos.z-1})
					add_tree_branch_blue({x=pos.x, y=pos.y+i, z=pos.z-1})
					add_tree_branch_blue({x=pos.x, y=pos.y+i, z=pos.z})
				else
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
			end
		end
end

-- Pink

function glowtest_spinktree(pos)
	local t = 3 + math.random(2) -- trunk height
	for j = -2, t do
		if j == t or j == t - 2 then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:pinkleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function glowtest_mpinktree(pos)
	local t = 6 + math.random(4) -- trunk height
	for j = -3, t do
		if j == math.floor(t * 0.7) or j == t then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:pinkleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function add_tree_branch_pink(pos)
	minetest.env:add_node(pos, {name="glowtest:tree"})
	for i = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
		for k = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
			local p = {x=pos.x+i, y=pos.y, z=pos.z+k}
			local n = minetest.env:get_node(p)
			if (n.name=="air") then
				minetest.env:add_node(p, {name="glowtest:pinkleaf"})
			end
			local chance = math.abs(i+k)
			if (chance < 1) then
				p = {x=pos.x+i, y=pos.y+1, z=pos.z+k}
				n = minetest.env:get_node(p)
				if (n.name=="air") then
					minetest.env:add_node(p, {name="glowtest:pinkleaf"})
				end
			end
		end
	end
end

function glowtest_lpinktree(pos)
    local height = 10 + math.random(5)
		if height < 10 then
			for i = height, -2, -1 do
				local p = {x=pos.x, y=pos.y+i, z=pos.z}
				minetest.env:add_node(p, {name="glowtest:tree"})
				if i == height then
					add_tree_branch_pink({x=pos.x, y=pos.y+height+math.random(0, 1), z=pos.z})
					add_tree_branch_pink({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_pink({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_pink({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1})
					add_tree_branch_pink({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1})
				end
				if i < 0 then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1}, {name="glowtest:tree"})
				end
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_pink(branch_pos)
				end
			end
		else
			for i = height, -5, -1 do
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_pink(branch_pos)
				end
				if i < math.random(0,1) then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+2, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-2}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
				if i == height then
					add_tree_branch_pink({x=pos.x+1, y=pos.y+i, z=pos.z+1})
					add_tree_branch_pink({x=pos.x+2, y=pos.y+i, z=pos.z-1})
					add_tree_branch_pink({x=pos.x, y=pos.y+i, z=pos.z-2})
					add_tree_branch_pink({x=pos.x-1, y=pos.y+i, z=pos.z})
					add_tree_branch_pink({x=pos.x+1, y=pos.y+i, z=pos.z+2})
					add_tree_branch_pink({x=pos.x+3, y=pos.y+i, z=pos.z-1})
					add_tree_branch_pink({x=pos.x, y=pos.y+i, z=pos.z-3})
					add_tree_branch_pink({x=pos.x-2, y=pos.y+i, z=pos.z})
					add_tree_branch_pink({x=pos.x+1, y=pos.y+i, z=pos.z})
					add_tree_branch_pink({x=pos.x+1, y=pos.y+i, z=pos.z-1})
					add_tree_branch_pink({x=pos.x, y=pos.y+i, z=pos.z-1})
					add_tree_branch_pink({x=pos.x, y=pos.y+i, z=pos.z})
				else
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
			end
		end
end

-- Yellow

function glowtest_syellowtree(pos)
	local t = 3 + math.random(2) -- trunk height
	for j = -2, t do
		if j == t or j == t - 2 then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:yellowleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function glowtest_myellowtree(pos)
	local t = 6 + math.random(4) -- trunk height
	for j = -3, t do
		if j == math.floor(t * 0.7) or j == t then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:yellowleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function add_tree_branch_yellow(pos)
	minetest.env:add_node(pos, {name="glowtest:tree"})
	for i = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
		for k = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
			local p = {x=pos.x+i, y=pos.y, z=pos.z+k}
			local n = minetest.env:get_node(p)
			if (n.name=="air") then
				minetest.env:add_node(p, {name="glowtest:yellowleaf"})
			end
			local chance = math.abs(i+k)
			if (chance < 1) then
				p = {x=pos.x+i, y=pos.y+1, z=pos.z+k}
				n = minetest.env:get_node(p)
				if (n.name=="air") then
					minetest.env:add_node(p, {name="glowtest:yellowleaf"})
				end
			end
		end
	end
end

function glowtest_lyellowtree(pos)
    local height = 10 + math.random(5)
		if height < 10 then
			for i = height, -2, -1 do
				local p = {x=pos.x, y=pos.y+i, z=pos.z}
				minetest.env:add_node(p, {name="glowtest:tree"})
				if i == height then
					add_tree_branch_yellow({x=pos.x, y=pos.y+height+math.random(0, 1), z=pos.z})
					add_tree_branch_yellow({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_yellow({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_yellow({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1})
					add_tree_branch_yellow({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1})
				end
				if i < 0 then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1}, {name="glowtest:tree"})
				end
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_yellow(branch_pos)
				end
			end
		else
			for i = height, -5, -1 do
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_yellow(branch_pos)
				end
				if i < math.random(0,1) then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+2, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-2}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
				if i == height then
					add_tree_branch_yellow({x=pos.x+1, y=pos.y+i, z=pos.z+1})
					add_tree_branch_yellow({x=pos.x+2, y=pos.y+i, z=pos.z-1})
					add_tree_branch_yellow({x=pos.x, y=pos.y+i, z=pos.z-2})
					add_tree_branch_yellow({x=pos.x-1, y=pos.y+i, z=pos.z})
					add_tree_branch_yellow({x=pos.x+1, y=pos.y+i, z=pos.z+2})
					add_tree_branch_yellow({x=pos.x+3, y=pos.y+i, z=pos.z-1})
					add_tree_branch_yellow({x=pos.x, y=pos.y+i, z=pos.z-3})
					add_tree_branch_yellow({x=pos.x-2, y=pos.y+i, z=pos.z})
					add_tree_branch_yellow({x=pos.x+1, y=pos.y+i, z=pos.z})
					add_tree_branch_yellow({x=pos.x+1, y=pos.y+i, z=pos.z-1})
					add_tree_branch_yellow({x=pos.x, y=pos.y+i, z=pos.z-1})
					add_tree_branch_yellow({x=pos.x, y=pos.y+i, z=pos.z})
				else
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
			end
		end
end

-- White

function glowtest_swhitetree(pos)
	local t = 3 + math.random(2) -- trunk height
	for j = -2, t do
		if j == t or j == t - 2 then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:whiteleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function glowtest_mwhitetree(pos)
	local t = 6 + math.random(4) -- trunk height
	for j = -3, t do
		if j == math.floor(t * 0.7) or j == t then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:whiteleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:tree"})
	end
end

function add_tree_branch_white(pos)
	minetest.env:add_node(pos, {name="glowtest:tree"})
	for i = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
		for k = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
			local p = {x=pos.x+i, y=pos.y, z=pos.z+k}
			local n = minetest.env:get_node(p)
			if (n.name=="air") then
				minetest.env:add_node(p, {name="glowtest:whiteleaf"})
			end
			local chance = math.abs(i+k)
			if (chance < 1) then
				p = {x=pos.x+i, y=pos.y+1, z=pos.z+k}
				n = minetest.env:get_node(p)
				if (n.name=="air") then
					minetest.env:add_node(p, {name="glowtest:whiteleaf"})
				end
			end
		end
	end
end

function glowtest_lwhitetree(pos)
    local height = 10 + math.random(5)
		if height < 10 then
			for i = height, -2, -1 do
				local p = {x=pos.x, y=pos.y+i, z=pos.z}
				minetest.env:add_node(p, {name="glowtest:tree"})
				if i == height then
					add_tree_branch_white({x=pos.x, y=pos.y+height+math.random(0, 1), z=pos.z})
					add_tree_branch_white({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_white({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_white({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1})
					add_tree_branch_white({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1})
				end
				if i < 0 then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1}, {name="glowtest:tree"})
				end
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_white(branch_pos)
				end
			end
		else
			for i = height, -5, -1 do
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_white(branch_pos)
				end
				if i < math.random(0,1) then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z+1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+2, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-2}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
				if i == height then
					add_tree_branch_white({x=pos.x+1, y=pos.y+i, z=pos.z+1})
					add_tree_branch_white({x=pos.x+2, y=pos.y+i, z=pos.z-1})
					add_tree_branch_white({x=pos.x, y=pos.y+i, z=pos.z-2})
					add_tree_branch_white({x=pos.x-1, y=pos.y+i, z=pos.z})
					add_tree_branch_white({x=pos.x+1, y=pos.y+i, z=pos.z+2})
					add_tree_branch_white({x=pos.x+3, y=pos.y+i, z=pos.z-1})
					add_tree_branch_white({x=pos.x, y=pos.y+i, z=pos.z-3})
					add_tree_branch_white({x=pos.x-2, y=pos.y+i, z=pos.z})
					add_tree_branch_white({x=pos.x+1, y=pos.y+i, z=pos.z})
					add_tree_branch_white({x=pos.x+1, y=pos.y+i, z=pos.z-1})
					add_tree_branch_white({x=pos.x, y=pos.y+i, z=pos.z-1})
					add_tree_branch_white({x=pos.x, y=pos.y+i, z=pos.z})
				else
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-1}, {name="glowtest:tree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="glowtest:tree"})
				end
			end
		end
end

-- Red

function glowtest_sredtree(pos)
	local t = 3 + math.random(2) -- trunk height
	for j = -2, t do
		if j == t or j == t - 2 then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:redleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:stonetree"})
	end
end

function glowtest_mredtree(pos)
	local t = 6 + math.random(4) -- trunk height
	for j = -3, t do
		if j == math.floor(t * 0.7) or j == t then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:redleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:stonetree"})
	end
end

function add_tree_branch_red(pos)
	minetest.env:add_node(pos, {name="glowtest:stonetree"})
	for i = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
		for k = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
			local p = {x=pos.x+i, y=pos.y, z=pos.z+k}
			local n = minetest.env:get_node(p)
			if (n.name=="air") then
				minetest.env:add_node(p, {name="glowtest:redleaf"})
			end
			local chance = math.abs(i+k)
			if (chance < 1) then
				p = {x=pos.x+i, y=pos.y+1, z=pos.z+k}
				n = minetest.env:get_node(p)
				if (n.name=="air") then
					minetest.env:add_node(p, {name="glowtest:redleaf"})
				end
			end
		end
	end
end

function glowtest_lredtree(pos)
    local height = 10 + math.random(5)
		if height < 10 then
			for i = height, -2, -1 do
				local p = {x=pos.x, y=pos.y+i, z=pos.z}
				minetest.env:add_node(p, {name="glowtest:stonetree"})
				if i == height then
					add_tree_branch_red({x=pos.x, y=pos.y+height+math.random(0, 1), z=pos.z})
					add_tree_branch_red({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_red({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_red({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1})
					add_tree_branch_red({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1})
				end
				if i < 0 then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1}, {name="glowtest:stonetree"})
				end
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_red(branch_pos)
				end
			end
		else
			for i = height, -5, -1 do
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_red(branch_pos)
				end
				if i < math.random(0,1) then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z+1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x+2, y=pos.y+i, z=pos.z-1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-2}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i, z=pos.z}, {name="glowtest:stonetree"})
				end
				if i == height then
					add_tree_branch_red({x=pos.x+1, y=pos.y+i, z=pos.z+1})
					add_tree_branch_red({x=pos.x+2, y=pos.y+i, z=pos.z-1})
					add_tree_branch_red({x=pos.x, y=pos.y+i, z=pos.z-2})
					add_tree_branch_red({x=pos.x-1, y=pos.y+i, z=pos.z})
					add_tree_branch_red({x=pos.x+1, y=pos.y+i, z=pos.z+2})
					add_tree_branch_red({x=pos.x+3, y=pos.y+i, z=pos.z-1})
					add_tree_branch_red({x=pos.x, y=pos.y+i, z=pos.z-3})
					add_tree_branch_red({x=pos.x-2, y=pos.y+i, z=pos.z})
					add_tree_branch_red({x=pos.x+1, y=pos.y+i, z=pos.z})
					add_tree_branch_red({x=pos.x+1, y=pos.y+i, z=pos.z-1})
					add_tree_branch_red({x=pos.x, y=pos.y+i, z=pos.z-1})
					add_tree_branch_red({x=pos.x, y=pos.y+i, z=pos.z})
				else
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z-1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="glowtest:stonetree"})
				end
			end
		end
end

--Black

function glowtest_sblacktree(pos)
	local t = 3 + math.random(2) -- trunk height
	for j = -2, t do
		if j == t or j == t - 2 then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:blackleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:stonetree"})
	end
end

function glowtest_mblacktree(pos)
	local t = 6 + math.random(4) -- trunk height
	for j = -3, t do
		if j == math.floor(t * 0.7) or j == t then
			for i = -2, 2 do
			for k = -2, 2 do
				local absi = math.abs(i)
				local absk = math.abs(k)
				if math.random() > (absi + absk) / 24 then
					minetest.add_node({x=pos.x+i,y=pos.y+j+math.random(0, 1),z=pos.z+k},{name="glowtest:blackleaf"})
				end
			end
			end
		end
		minetest.add_node({x=pos.x,y=pos.y+j,z=pos.z},{name="glowtest:stonetree"})
	end
end

function add_tree_branch_black(pos)
	minetest.env:add_node(pos, {name="glowtest:stonetree"})
	for i = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
		for k = math.floor(math.random(2)), -math.floor(math.random(2)), -1 do
			local p = {x=pos.x+i, y=pos.y, z=pos.z+k}
			local n = minetest.env:get_node(p)
			if (n.name=="air") then
				minetest.env:add_node(p, {name="glowtest:blackleaf"})
			end
			local chance = math.abs(i+k)
			if (chance < 1) then
				p = {x=pos.x+i, y=pos.y+1, z=pos.z+k}
				n = minetest.env:get_node(p)
				if (n.name=="air") then
					minetest.env:add_node(p, {name="glowtest:blackleaf"})
				end
			end
		end
	end
end

function glowtest_lblacktree(pos)
    local height = 10 + math.random(5)
		if height < 10 then
			for i = height, -2, -1 do
				local p = {x=pos.x, y=pos.y+i, z=pos.z}
				minetest.env:add_node(p, {name="glowtest:stonetree"})
				if i == height then
					add_tree_branch_black({x=pos.x, y=pos.y+height+math.random(0, 1), z=pos.z})
					add_tree_branch_black({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_black({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z})
					add_tree_branch_black({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1})
					add_tree_branch_black({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1})
				end
				if i < 0 then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z+1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i-math.random(2), z=pos.z}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i-math.random(2), z=pos.z-1}, {name="glowtest:stonetree"})
				end
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_black(branch_pos)
				end
			end
		else
			for i = height, -5, -1 do
				if (math.sin(i/height*i) < 0.2 and i > 3 and math.random(0,2) < 1.5) then
					branch_pos = {x=pos.x+math.random(0,1), y=pos.y+i, z=pos.z-math.random(0,1)}
					add_tree_branch_black(branch_pos)
				end
				if i < math.random(0,1) then
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z+1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x+2, y=pos.y+i, z=pos.z-1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-2}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x-1, y=pos.y+i, z=pos.z}, {name="glowtest:stonetree"})
				end
				if i == height then
					add_tree_branch_black({x=pos.x+1, y=pos.y+i, z=pos.z+1})
					add_tree_branch_black({x=pos.x+2, y=pos.y+i, z=pos.z-1})
					add_tree_branch_black({x=pos.x, y=pos.y+i, z=pos.z-2})
					add_tree_branch_black({x=pos.x-1, y=pos.y+i, z=pos.z})
					add_tree_branch_black({x=pos.x+1, y=pos.y+i, z=pos.z+2})
					add_tree_branch_black({x=pos.x+3, y=pos.y+i, z=pos.z-1})
					add_tree_branch_black({x=pos.x, y=pos.y+i, z=pos.z-3})
					add_tree_branch_black({x=pos.x-2, y=pos.y+i, z=pos.z})
					add_tree_branch_black({x=pos.x+1, y=pos.y+i, z=pos.z})
					add_tree_branch_black({x=pos.x+1, y=pos.y+i, z=pos.z-1})
					add_tree_branch_black({x=pos.x, y=pos.y+i, z=pos.z-1})
					add_tree_branch_black({x=pos.x, y=pos.y+i, z=pos.z})
				else
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x+1, y=pos.y+i, z=pos.z-1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z-1}, {name="glowtest:stonetree"})
					minetest.env:add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="glowtest:stonetree"})
				end
			end
		end
end

-- SAPLINGS

-- Green Sapling

minetest.register_abm({
    nodenames = {"glowtest:sgreensapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_sgreentree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:mgreensapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_mgreentree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:lgreensapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_lgreentree(pos)
    end,
})

--Blue Sapling

minetest.register_abm({
    nodenames = {"glowtest:sbluesapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_sbluetree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:mbluesapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_mbluetree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:lbluesapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_lbluetree(pos)
    end,
})

--Pink Sapling

minetest.register_abm({
    nodenames = {"glowtest:spinksapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_spinktree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:mpinksapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_mpinktree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:lpinksapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_lpinktree(pos)
    end,
})

--Yellow Sapling

minetest.register_abm({
    nodenames = {"glowtest:syellowsapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_syellowtree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:myellowsapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_myellowtree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:lyellowsapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_lyellowtree(pos)
    end,
})

--White Sapling

minetest.register_abm({
    nodenames = {"glowtest:swhitesapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_swhitetree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:mwhitesapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_mwhitetree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:lwhitesapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_lwhitetree(pos)
    end,
})

--Red Sapling

minetest.register_abm({
    nodenames = {"glowtest:sredsapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_sredtree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:mredsapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_mredtree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:lredsapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_lredtree(pos)
    end,
})

--Black Sapling

minetest.register_abm({
    nodenames = {"glowtest:sblacksapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_sblacktree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:mblacksapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_mblacktree(pos)
    end,
})

minetest.register_abm({
    nodenames = {"glowtest:lblacksapling"},
    interval = GREINT,
    chance = GRECHA,
    action = function(pos, node, active_object_count, active_object_count_wider)
		glowtest_lblacktree(pos)
    end,
})

--Ores

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "glowtest:glow_ore_cursed",
	wherein        = "default:desert_stone",
	clust_scarcity = 12*12*12,
	clust_num_ores = 5,
	clust_size     = 3,
	height_min     = -100,
	height_max     = 10,
	flags          = "absheight",
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "glowtest:glow_ore",
	wherein        = "default:dirt",
	clust_scarcity = 12*12*12,
	clust_num_ores = 5,
	clust_size     = 3,
	height_min     = -100,
	height_max     = 10,
	flags          = "absheight",
})
