defmodule AcariServer.Zabbix.Import do
  def template() do
    ~S"""
    {
        "zabbix_export": {
            "version": "5.4",
            "date": "2021-09-29T07:21:26Z",
            "groups": [
                {
                    "uuid": "a85ff5b0bace4973872f05a1e0e542e8",
                    "name": "Bogatka_all"
                }
            ],
            "templates": [
                {
                    "uuid": "fbcc9b046b6f4570be62514d6de93572",
                    "template": "Bogatka_client",
                    "name": "Bogatka_client",
                    "groups": [
                        {
                            "name": "Bogatka_all"
                        }
                    ],
                    "items": [
                        {
                            "uuid": "b4e4d5f828514cc4bc051d8c04e84370",
                            "name": "\u0414\u043e\u0441\u0442\u0443\u043f\u043d\u043e\u0441\u0442\u044c \u043a\u043b\u0438\u0435\u043d\u0442\u0430",
                            "type": "TRAP",
                            "key": "alive",
                            "delay": "0",
                            "value_type": "FLOAT",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ],
                            "triggers": [
                                {
                                    "uuid": "de92c7cfac2445cb95e8712c161a3a6b",
                                    "expression": "last(/Bogatka_client/alive)=0",
                                    "name": "\u041a\u043b\u0438\u0435\u043d\u0442 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d",
                                    "opdata": "xxxxx",
                                    "priority": "HIGH"
                                }
                            ]
                        },
                        {
                            "uuid": "ad67756734b44217ae47d7c31a41872a",
                            "name": "\u0421\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435 \u043f\u043e\u0440\u0442\u0430 m1",
                            "type": "TRAP",
                            "key": "alive[m1]",
                            "delay": "0",
                            "value_type": "FLOAT",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ]
                        },
                        {
                            "uuid": "21165758859144939220f0fd3a2b2af6",
                            "name": "\u0421\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435 \u043f\u043e\u0440\u0442\u0430 m2",
                            "type": "TRAP",
                            "key": "alive[m2]",
                            "delay": "0",
                            "value_type": "FLOAT",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ]
                        },
                        {
                            "uuid": "9d147840ec1c4946879987e1801c49a0",
                            "name": "m1 CSQ",
                            "type": "TRAP",
                            "key": "csq[m1]",
                            "delay": "0",
                            "value_type": "FLOAT",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ]
                        },
                        {
                            "uuid": "a059046dafd04a45b8c68c0267f25472",
                            "name": "m2 CSQ",
                            "type": "TRAP",
                            "key": "csq[m2]",
                            "delay": "0",
                            "value_type": "FLOAT",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ]
                        },
                        {
                            "uuid": "839f46a4715e4aca969588860c444d10",
                            "name": "\u0410\u043f\u043f\u0430\u0440\u0430\u0442\u043d\u0430\u044f \u043a\u043e\u043d\u0444\u0438\u0433\u0443\u0440\u0430\u0446\u0438\u044f",
                            "type": "TRAP",
                            "key": "hw.info",
                            "delay": "0",
                            "trends": "0",
                            "value_type": "TEXT",
                            "inventory_link": "HARDWARE_FULL"
                        },
                        {
                            "uuid": "77682db8623c4e99a5996ecb7b39c171",
                            "name": "Incoming network traffic on acari0",
                            "type": "TRAP",
                            "key": "net.if.in[acari0]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "17de838915854991ad8023244911c706",
                            "name": "Incoming network traffic on eth0",
                            "type": "TRAP",
                            "key": "net.if.in[eth0]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "c249bbeaf94c48ed836a3670e2879a47",
                            "name": "Incoming network traffic on m1",
                            "type": "TRAP",
                            "key": "net.if.in[m1]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "5049317ff4ef40abb94a773c72d519c1",
                            "name": "Incoming network traffic on m2",
                            "type": "TRAP",
                            "key": "net.if.in[m2]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "0b981a1c1cf14c59b03aa928f0bdd1b6",
                            "name": "Outgoing network traffic on acari0",
                            "type": "TRAP",
                            "key": "net.if.out[acari0]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "747439d1e2e64e829a3ce81e8b7dddac",
                            "name": "Outgoing network traffic on eth0",
                            "type": "TRAP",
                            "key": "net.if.out[eth0]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "eb01d5f42fad4637a8238f7740b1ee9d",
                            "name": "Outgoing network traffic on m1",
                            "type": "TRAP",
                            "key": "net.if.out[m1]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "23123064873f4214b2f3dcd702f032ac",
                            "name": "Outgoing network traffic on m2",
                            "type": "TRAP",
                            "key": "net.if.out[m2]",
                            "delay": "0",
                            "units": "bps",
                            "preprocessing": [
                                {
                                    "type": "CHANGE_PER_SECOND",
                                    "parameters": [
                                        ""
                                    ]
                                }
                            ]
                        },
                        {
                            "uuid": "4bec1008951e46c9b458e3f9922c7a35",
                            "name": "m1 Oper",
                            "type": "TRAP",
                            "key": "oper[m1]",
                            "delay": "0",
                            "trends": "0",
                            "value_type": "TEXT",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ]
                        },
                        {
                            "uuid": "ccfeeed76aa145c0bfea5283fd2c48f2",
                            "name": "m2 Oper",
                            "type": "TRAP",
                            "key": "oper[m2]",
                            "delay": "0",
                            "trends": "0",
                            "value_type": "TEXT",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ]
                        },
                        {
                            "uuid": "407a5d4a705a4782a24d125a00378693",
                            "name": "\u0412\u0435\u0440\u0441\u0438\u044f \u041f\u041e",
                            "type": "TRAP",
                            "key": "sw.version",
                            "delay": "0",
                            "trends": "0",
                            "value_type": "TEXT",
                            "inventory_link": "SOFTWARE",
                            "tags": [
                                {
                                    "tag": "Application",
                                    "value": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                                }
                            ]
                        }
                    ],
                    "dashboards": [
                        {
                            "uuid": "be46ef1d55f34943bc3ac4ce08dda105",
                            "name": "\u0421\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435",
                            "pages": [
                                {
                                    "widgets": [
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "INTEGER",
                                                    "name": "source_type",
                                                    "value": "1"
                                                },
                                                {
                                                    "type": "ITEM",
                                                    "name": "itemid",
                                                    "value": {
                                                        "key": "alive",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        },
                                        {
                                            "type": "CLOCK",
                                            "x": "16",
                                            "width": "8",
                                            "height": "5"
                                        },
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "x": "8",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "GRAPH",
                                                    "name": "graphid",
                                                    "value": {
                                                        "name": "Traffic acari0",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        },
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "y": "5",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "INTEGER",
                                                    "name": "source_type",
                                                    "value": "1"
                                                },
                                                {
                                                    "type": "ITEM",
                                                    "name": "itemid",
                                                    "value": {
                                                        "key": "alive[m1]",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        },
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "y": "10",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "INTEGER",
                                                    "name": "source_type",
                                                    "value": "1"
                                                },
                                                {
                                                    "type": "ITEM",
                                                    "name": "itemid",
                                                    "value": {
                                                        "key": "alive[m2]",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        },
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "x": "16",
                                            "y": "5",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "INTEGER",
                                                    "name": "source_type",
                                                    "value": "1"
                                                },
                                                {
                                                    "type": "ITEM",
                                                    "name": "itemid",
                                                    "value": {
                                                        "key": "csq[m1]",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        },
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "x": "16",
                                            "y": "10",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "INTEGER",
                                                    "name": "source_type",
                                                    "value": "1"
                                                },
                                                {
                                                    "type": "ITEM",
                                                    "name": "itemid",
                                                    "value": {
                                                        "key": "csq[m2]",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        },
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "x": "8",
                                            "y": "5",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "GRAPH",
                                                    "name": "graphid",
                                                    "value": {
                                                        "name": "Traffic m1",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        },
                                        {
                                            "type": "GRAPH_CLASSIC",
                                            "x": "8",
                                            "y": "10",
                                            "width": "8",
                                            "height": "5",
                                            "fields": [
                                                {
                                                    "type": "GRAPH",
                                                    "name": "graphid",
                                                    "value": {
                                                        "name": "Traffic m2",
                                                        "host": "Bogatka_client"
                                                    }
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ],
            "triggers": [
                {
                    "uuid": "a869378752cf42889d84c168657d4b0a",
                    "expression": "avg(/Bogatka_client/csq[m1],30d)<12 and\nlength(last(/Bogatka_client/oper[m1]))>=0",
                    "name": "\u041d\u0438\u0437\u043a\u0438\u0439 \u0443\u0440\u043e\u0432\u0435\u043d\u044c \u0441\u0438\u0433\u043d\u0430\u043b\u0430 m1  ({ITEM.VALUE2})",
                    "priority": "WARNING"
                },
                {
                    "uuid": "bd9747273c364b54b55342c7be93d897",
                    "expression": "avg(/Bogatka_client/csq[m2],30d)<12 and\nlength(last(/Bogatka_client/oper[m2]))>=0",
                    "name": "\u041d\u0438\u0437\u043a\u0438\u0439 \u0443\u0440\u043e\u0432\u0435\u043d\u044c \u0441\u0438\u0433\u043d\u0430\u043b\u0430 m2  ({ITEM.VALUE2})",
                    "priority": "WARNING"
                },
                {
                    "uuid": "61e01903d7c44ac5af687ed5f71427e5",
                    "expression": "last(/Bogatka_client/alive[m1])=0 and\nlength(last(/Bogatka_client/oper[m1]))>=0",
                    "name": "\u041f\u043e\u0440\u0442 m1 \u043d\u0435 \u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d ({ITEM.VALUE2})",
                    "priority": "WARNING"
                },
                {
                    "uuid": "8d793b9045e942bcbd9e50ea701d2823",
                    "expression": "last(/Bogatka_client/alive[m2])=0 and\nlength(last(/Bogatka_client/oper[m2]))>0",
                    "name": "\u041f\u043e\u0440\u0442 m2 \u043d\u0435 \u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d ({ITEM.VALUE2})",
                    "priority": "WARNING"
                }
            ],
            "graphs": [
                {
                    "uuid": "05276c42b9d94d75b2df40823b617ee2",
                    "name": "Traffic acari0",
                    "type": "STACKED",
                    "graph_items": [
                        {
                            "color": "20C997",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.in[acari0]"
                            }
                        },
                        {
                            "sortorder": "1",
                            "color": "FD7E14",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.out[acari0]"
                            }
                        }
                    ]
                },
                {
                    "uuid": "92195d0314764226bea5d0f53e30c4b1",
                    "name": "Traffic eth0",
                    "type": "STACKED",
                    "graph_items": [
                        {
                            "color": "20C997",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.in[eth0]"
                            }
                        },
                        {
                            "sortorder": "1",
                            "color": "FD7E14",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.out[eth0]"
                            }
                        }
                    ]
                },
                {
                    "uuid": "47407ee1545c462a826d7f4e8f2bbd0e",
                    "name": "Traffic m1",
                    "type": "STACKED",
                    "graph_items": [
                        {
                            "color": "20C997",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.in[m1]"
                            }
                        },
                        {
                            "sortorder": "1",
                            "color": "FD7E14",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.out[m1]"
                            }
                        }
                    ]
                },
                {
                    "uuid": "2ae5f3841433480b98cfd2dbf08a45d1",
                    "name": "Traffic m2",
                    "type": "STACKED",
                    "graph_items": [
                        {
                            "color": "20C997",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.in[m2]"
                            }
                        },
                        {
                            "sortorder": "1",
                            "color": "FD7914",
                            "item": {
                                "host": "Bogatka_client",
                                "key": "net.if.out[m2]"
                            }
                        }
                    ]
                }
            ]
        }
    }
    """
  end
end
