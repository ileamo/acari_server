#!/usr/bin/env lua


local nsg = require"nsg"
local socket = require"socket"
local ser = nsg.serialize
local json = require("cjson")
require"zabbix_api"

local optsDescr = {
  ("%s [OPTION ...]"):format(debug.getinfo(1).short_src),
  "",
  help = {0, "display this help and exit"},
  h = 'help',
  ["zabbix-server"] = {1, "Zabbix server URL", "URL/"},
  z = "zabbix-server",
  ["zabbix-sender"] = {1, "Address for zabbix sender", "ADDR"},
  s = "zabbix-sender",
  username = {1, "Username"},
  u = 'username',
  password = {1, "Password"},
  p = 'password',
  group = {1, "Host group to add the host to"},
  g = 'group',
  agroup = {1, "auxiliary host group to add the host to"},
  a = 'agroup',
  template = {1, "Template to be linked to the host"},
  t = 'template',
  debug = {0, "Output debug messages"},
  d = "debug",
  ["master-host"] = {1, "Name of master host", "NAME"},
  m = "master-host",
  ignore = {1, "List of ignored hosts"},
  i = "ignore",
}

local arg = nsg.getopt({...}, optsDescr)

local function usageAndExit(s)
  print(s)
  print(nsg.usage(optsDescr))
  os.exit(1)
end

if arg.help then
  print(nsg.usage(optsDescr))
  return
end

local ignore = {}
for val in (arg.ignore or ""):gmatch"[^,]+" do
  ignore[val] = true
end

local dbg = arg.debug
local logFile = "/var/log/acari_zbx.log"
local function LOG(mes)
  print(mes)
end

os.execute("stty -echo")

local HOST = {}

--
-- ██ ████████ ███████ ███    ███         ██████   █████  ██████   █████  ███    ███ ███████
-- ██    ██    ██      ████  ████         ██   ██ ██   ██ ██   ██ ██   ██ ████  ████ ██
-- ██    ██    █████   ██ ████ ██         ██████  ███████ ██████  ███████ ██ ████ ██ ███████
-- ██    ██    ██      ██  ██  ██         ██      ██   ██ ██   ██ ██   ██ ██  ██  ██      ██
-- ██    ██    ███████ ██      ██ ███████ ██      ██   ██ ██   ██ ██   ██ ██      ██ ███████
--


local ITEM_PARAMS = {
  ["uitcp.clients.number"] = {
    name = "Clients number on $1",
    value_type = 3, -- numeric unsigned
  },

  csq = {
    name = "$1 CSQ",
    value_type = 0, -- numeric float
  },

  ["net.if.out"] = {
    name = "$1 outgoing traffic",
    value_type = 3, -- numeric unsigned
    data_type = 0,  -- decimal
    units = "bps",
    multiplier = 1,
    formula = 8,
    delta = 1,      -- speed for second
  },

  ["net.if.in"] = {
    name = "$1 incoming traffic",
    value_type = 3, -- numeric unsigned
    data_type = 0,  -- decimal
    units = "bps",
    multiplier = 1,
    formula = 8,
    delta = 1,      -- speed for second
  },

  ["net.if.state"] = {
    name = "$1 oper state",
  },

  ["net.if.lowerstate"] = {
    name = "$1 carrier",
  },


}

local DEFAULT_ITEM_PARAMS = {
  value_type = 4 -- text
}

--
-- ██ ███    ██ ██ ████████
-- ██ ████   ██ ██    ██
-- ██ ██ ██  ██ ██    ██
-- ██ ██  ██ ██ ██    ██
-- ██ ██   ████ ██    ██
--


local zabbixServerUrl = arg["zabbix-server"]
if not zabbixServerUrl then
  LOG"zabbix server URL not defined"
  return
end

local username = arg.username
local pass = arg.password
if not username or not pass then
  LOG"No username or password"
  return
end

local hostgroup = arg.group
if not hostgroup then
  LOG"No host group defined"
  return
end

local zbx = zbxapi.create(zabbixServerUrl, username, pass)
if not zbx:Authorize() then
  LOG(zbx)
  return
end
LOG(zbx)

local zabbixServerAddr = arg["zabbix-sender"] or zabbixServerUrl:match"[^/]*//([^/:]+)[/:].*"
local zabbixServerAddr, zabbixServerPort = zabbixServerAddr:match"([^:]*):?(%d*)"
zabbixServerPort = tonumber(zabbixServerPort) or 10051

local request = {
  output = "extend",
  filter = {
    name = {hostgroup},
  }
}
local hostgroupID = zbx:Request("hostgroup.get", request)
if hostgroupID.error then
  LOG("Error receiving host group ID: "..hostgroupID.error.message)
  LOG(hostgroupID.error.data)
  return
end
if hostgroupID.result[1] and hostgroupID.result[1].name == hostgroup then
  hostgroupID = hostgroupID.result[1].groupid
else
  LOG(("Can't find host group %q"):format(hostgroup))
  return
end

LOG(("Hosts will be added to host group %q"):format(hostgroup))


local ahostgroupID
local ahostgroup = arg.agroup
if not ahostgroup then
  LOG"No auxiliary host group"
else
  local request = {
    output = "extend",
    filter = {
      name = {ahostgroup},
    }
  }
  ahostgroupID = zbx:Request("hostgroup.get", request)
  if ahostgroupID.error then
    LOG("Error receiving host group ID: "..ahostgroupID.error.message)
    LOG(ahostgroupID.error.data)
    return
  end
  if ahostgroupID.result[1] and ahostgroupID.result[1].name == ahostgroup then
    ahostgroupID = ahostgroupID.result[1].groupid
  else
    LOG(("Can't find host group %q"):format(ahostgroup))
    return
  end

  LOG(("Hosts will be added to host group %q (auxiliary)"):format(ahostgroup))
end



local templateID
local template = arg.template
if not template then
  LOG"No template will be linked to the hosts"
else
  local request = {
    output = "extend",
    filter = {
      host = {template},
    }
  }
  local res = zbx:Request("template.get", request)
  if res.error then
    LOG("Error receiving template ID: "..res.error.message)
    LOG(res.error.data)
    return
  end
  if res.result[1] and res.result[1].host == template then
    templateID = res.result[1].templateid
  else
    LOG(("Can't find template %q"):format(template))
    return
  end

  LOG(("Template %q will be linked to the hosts"):format(template))

end

local masterHostID
local masterHost = arg["master-host"]
if masterHost then
  LOG("Master Host is "..masterHost)

  local request = {
    output = {"host"},
    filter = {
      host = {
        masterHost
      }
    }
  }
  local res = zbx:Request("host.get", request)

  if res.error then
    LOG("Error receiving masterHost ID:\n"..res.error.message)
    return
  end

  if res.result[1] and res.result[1].host == masterHost then
    masterHostID = res.result[1].hostid
  else
    LOG(("Can't find host %q"):format(masterHost))
    return
  end
end

if arg.ignore then
  LOG("Ignored host: "..arg.ignore)
end


--
-- ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██ ███████
-- ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██ ██
-- █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██ ███████
-- ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██      ██
-- ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████ ███████
--

local SEND_HOST_INFO_INTERVAL = 5*60

local createItem, zbxSend


local function getHostslist(groupID)
  local request = {
    output = {"host"},
    groupids = {groupID}
  }
  local res = zbx:Request("host.get", request)
  if res.error then
    LOG("Can't get list of hosts: "..res.error.message)
    LOG(res.error.data)
    os.exit(1)
    return
  end
  return res.result
end

local function sendNumberOfHosts(hostsList)
  if hostsList and #hostsList > 0 then
    zbxSend(masterHost, "uitcp.clients.number", #hostsList)
  end
end

local function sendNumberOfClientsForServer()
  local clientNum = {}
  for _, host in pairs(HOST) do
    local item = host.item["uitcp.server"]
    if item then
      local request = {
        output = 'extend',
        itemids = item.itemid,
        limit = 1,
        history = item.value_type,
        sortfield = "clock",
        sortorder = "DESC",
      }
      local res = zbx:Request("history.get", request)
      local value = res.result and res.result[1] and res.result[1].value
      if value then
        if clientNum[value] then
          clientNum[value] = clientNum[value] + 1
        else
          clientNum[value] = 1
        end
      end
    end
  end
  for server, num in pairs(clientNum) do
    local sensor = "uitcp.clients.number"
    local key = sensor.."["..server.."]"
    createItem(masterHost, key, sensor)
    zbxSend(masterHost, key, num)
  end
end

local sendHostInfoTimestamp = 0
local function sendHostInfo()
  for hostname, host in pairs(HOST) do
    local info = {}
    for _, itm in ipairs{
      {"Модель:         ", "system.hw.chassis[model]"},
      {"Серийный номер: ", "system.hw.chassis[serial]"},
      --{"Сервер:         ", "uitcp.server"},
      --{"Канал:          ", "uitcp.link"},
      {"-- Радиомодуль m1 --\n", "system.hw.radio.moduleinfo[m1]"},
      {"-- Радиомодуль m2 --\n", "system.hw.radio.moduleinfo[m2]"},
    } do
      local item = host.item[itm[2]]
      if item then
        local request = {
          output = 'extend',
          itemids = item.itemid,
          limit = 1,
          history = item.value_type,
          sortfield = "clock",
          sortorder = "DESC",

        }
        local res = zbx:Request("history.get", request)
        local value = res.result and res.result[1] and res.result[1].value
        if value then
          info[#info + 1] = itm[1]..value:match("^(.-)\n*$")
        end
      end
    end

    if #info > 0 then
      info = table.concat(info, '\n')
    else
      info = "No data"
    end
    zbxSend(hostname, "system.info", info)
  end
  sendHostInfoTimestamp = os.time()
end


local function zbxAddHostIfNotExist(host)
  if HOST[host] then return true end

  local request = {
    filter = {
      host = {host},
    }
  }
  local res = zbx:Request("host.get", request)
  if res.result and res.result[1] and res.result[1].host == host then
    HOST[host] = {hostid = res.result[1].hostid, item = {}}
    return true
  end


  local request = {
    host = host,
    interfaces = {
      {
        type = 1,
        main = 1,
        useip = 1,
        ip = "127.0.0.1",
        dns = "",
        port = "10050"
      }
    },
    groups = {
      {
        groupid = hostgroupID
      }
    },
    templates = {
      {
        templateid = templateID,
      }
    },
    inventory_mode = 1,
  }
  if ahostgroupID then
    request.groups[#request.groups + 1] = {groupid = ahostgroupID}
  end

  local res = zbx:Request("host.create", request)
  if res.error then
    LOG("Error creating host "..host..": "..res.error.message)
    LOG(res.error.data)
    os.exit(1)
    return false
  end
  local hostID = res.result and res.result.hostids and res.result.hostids[1]
  if hostID then
    HOST[host] = {hostid = hostID, item = {}}
    LOG(("Host %q created"):format(host))
    if masterHost then
      sendNumberOfHosts(getHostslist(hostgroupID))
    end
    return true
  else
    LOG("Can't create host "..host..'\n'..ser(res, 0))
  end

  return false
end

local function getHostItems(hostid)
  local request = {
    hostids = hostid,
    output = {
      "key_",
      "value_type",
    },
  }
  local res = zbx:Request("item.get", request)
  return res.result
end


function createItem(host, key, sensor)
  if HOST[host].item[key] then
    return
  end

  local request = {
    hostids = HOST[host].hostid,
    filter = {
      key_ = key,
    }
  }
  local res = zbx:Request("item.get", request)
  if res.result and res.result[1] and res.result[1].key_ == key then
    HOST[host].item[key] = {itemid = res.result[1].itemid}
    return true
  end


  local ip = ITEM_PARAMS[sensor] or DEFAULT_ITEM_PARAMS
  local request = {
    key_ = key,
    hostid = HOST[host].hostid,
    type = 2, -- zabbix trapper
    delay = 60,
  }
  for k, v in pairs(ip) do
    request[k] = v
  end
  if not request.name then request.name = key end
  if not request.value_type then request.value_type = 4 end


  local res = zbx:Request("item.create", request)

  if res.error then
    LOG("Error creating item "..host..':'..key..": "..res.error.message)
    LOG(res.error.data)
    os.exit(1)
    return false
  end

  local itemID = res.result and res.result.itemids and res.result.itemids[1]
  if itemID then
    HOST[host].item[key] = {itemid = itemID}
    LOG(("Item %q created(key = %q)"):format(request.name, request.key_))
    return true
  else
    LOG("Can't create item "..host..':'..key..'\n'..ser(res, 0))
  end

  return false
end

local zbxHeader = "ZBXD\001"
function zbxSend(host, key, value)

  local sendrequest = {
    request = "sender data",
    data = {
      {
        host = host,
        key = key,
        value = value,
        --        clock = os.time() -- TODO
      }
    }
  }
  if dbg then LOG(("%s:%s=%s"):format(host, key, value)) end

  local data = json.encode(sendrequest)
  local len = #data
  if len > 65535 then
    LOG"Too long JSON message"
    return
  end
  local dataLen = string.char(len%256, math.floor(len / 256), 0, 0, 0, 0, 0, 0)


  local zbxSender = assert(socket.connect(zabbixServerAddr, zabbixServerPort))
  zbxSender:settimeout(10)
  local res = assert(zbxSender:send(zbxHeader..dataLen..data))

  --socket.sleep(0.5)
  local line, err, p = zbxSender:receive()
  local res = line or p
  res = json.decode(res:sub(14, - 1))
  if dbg then LOG(ser(res, 0)) end
  zbxSender:close()
end

--
-- ███    ███  █████  ██ ███    ██
-- ████  ████ ██   ██ ██ ████   ██
-- ██ ████ ██ ███████ ██ ██ ██  ██
-- ██  ██  ██ ██   ██ ██ ██  ██ ██
-- ██      ██ ██   ██ ██ ██   ████
--

local hostsList = getHostslist(hostgroupID)
if masterHost and masterHostID then
  sendNumberOfHosts(hostsList)
  hostsList[#hostsList+1] = {
    host = masterHost,
    hostid = masterHostID
  }
end
for _, v in ipairs(hostsList) do
  local items = getHostItems(v.hostid)
  local itemTable = {}
  for _, itm in ipairs(items) do
    itemTable[itm.key_] = itm
  end
  HOST[v.host] = {hostid = v.hostid, item = itemTable}
end

--LOG(ser(HOST,0))

sendHostInfo()


local sensorPattern = "([^%[%],%s]+)%[?"
while true do
  local event = io.read'*l'
  event = json.decode(event)
  local host = event.host
  local key = event.key
  local value = event.value
  if host and not ignore[host] and key and value then
    if zbxAddHostIfNotExist(host) then
      createItem(host, key, key:match(sensorPattern))
      zbxSend(host, key, value)
    end
  end
  if dbg and host and ignore[host] then
    LOG("Host '"..host.."' ignored")
  end
  if os.time() - sendHostInfoTimestamp > SEND_HOST_INFO_INTERVAL then
    local timestamp = os.time()
    sendHostInfo()
    sendNumberOfHosts(getHostslist(hostgroupID))
    --sendNumberOfClientsForServer()
    LOG("Host info updated in "..os.time() - timestamp.." sec.")
  end
end
