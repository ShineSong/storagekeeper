name = "Storage Keeper"
description = "A reliable Storage Keeper who manage your items in chests and iceboxes which are adjacent."
author = "Shine Song"
version = "1.0.0"

forumthread = ""
api_version = 10
icon_atlas = "modicon.xml"
icon = "modicon.tex"
restart_required = false
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible             = true
server_filter_tags         = { "storage keeper" }

client_only_mod         = false
all_clients_require_mod = true

configuration_options = {
	{
		default = 107,  -- ASCII code for "k"
		label   = "Press to sort storage group:",
		name    = "keybind",
		options = (function()
			local KEY_A  = 97  -- ASCII code for "a"
			local values = {}
			local chars  = {
				"A","B","C","D","E","F","G","H","I","J","K","L","M",
				"N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
			}

			for i = 1, #chars do
				values[#values + 1] = { description = chars[i], data = i + KEY_A - 1 }
			end

			return values
		end)()
	},
	{
		default = 10,
		label   = "search radius for cluster storage",
		name    = "radius",
		options = (function()
			local values = {}
			for i = 1, 20 do
				values[#values + 1] = { description = i, data = i }
			end

			return values
		end)()
	},
}
