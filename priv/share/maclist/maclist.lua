-- #!/usr/bin/lua
local cjson = require"cjson"
local mac_table = {}

local function add_param(mac, param, value)
  if value then
    if not mac_table[mac] then mac_table[mac] = {} end
    mac_table[mac][param] = value
  end
end

local function add_ip(mac, ip_addr)
  if ip_addr then
    if not mac_table[mac] then mac_table[mac] = {} end
    if not mac_table[mac].ip then mac_table[mac].ip = {} end
    mac_table[mac].ip[ip_addr] = true
  end
end

-- ARP
--local f = assert(io.popen("arp -n"))
local f = assert(io.popen("cat arp"))
for line in f:lines() do
  local mac = string.match(line, ".*(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x)")
  if mac ~= nil then
    add_param(mac, "iface", string.match(line, "%s+([^%s]+)%s*$"))
    add_ip(mac, string.match(line, ".*%((%d+%.%d+%.%d+%.%d+)%)"))
  end
end
f:close()

-- DHCP
-- local f = assert(io.popen('nsgsh -qr "services.dhcp.br1.show.leases"'))
local f = assert(io.popen("cat dhcp"))
for line in f:lines() do
  local mac, ip_addr = string.match(line, "(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x)%s+(%d+%.%d+%.%d+%.%d+)")
  if mac then add_ip(mac, ip) end
end
f:close()

-- BRIDGE
-- get id-name mapping
--local f = assert(io.popen("grep . /sys/class/net/br1/brif/*/port_no"))
local f = assert(io.popen("cat brports"))
local id_name = {}
for line in f:lines() do
  local port_name, id = string.match(line, "/sys/class/net/br1/brif/(.+)/port_no:(.+)")
  id = tonumber(id)
  if id and port_name then
    id_name[id] = port_name
  end
end
f:close()

--local f = assert(io.popen("brctl showmacs br1"))
local f = assert(io.popen("cat showmacs"))
for line in f:lines() do
  local id, mac, is_local = string.match(line, "(%d+)%s+(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x)%s+([yesno]+)")
  id = tonumber(id)
  if is_local == "no" and id and mac then
    add_param(mac, "port", id_name[id])
  end
end
f:close()

-- convert table to list
local mac_list = {}
for mac, params in pairs(mac_table) do
  ip_list = {}
  for ip_addr, _ in pairs(params.ip) do
    ip_list[#ip_list + 1] = ip_addr
  end
  params.mac = mac
  params.ip = ip_list
  mac_list[#mac_list + 1] = params
end

print(cjson.encode(mac_list))
