defmodule AcariServer.Zabbix.Import do
  def template() do
    ~S"""
    {
      "zabbix_export": {
          "version": "5.2",
          "date": "2021-09-28T14:38:14Z",
          "groups": [
              {
                  "name": "Bogatka_all"
              }
          ],
          "templates": [
              {
                  "template": "Bogatka_client",
                  "name": "Bogatka_client",
                  "groups": [
                      {
                          "name": "Bogatka_all"
                      }
                  ],
                  "applications": [
                      {
                          "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                      }
                  ],
                  "items": [
                      {
                          "name": "\u0414\u043e\u0441\u0442\u0443\u043f\u043d\u043e\u0441\u0442\u044c \u043a\u043b\u0438\u0435\u043d\u0442\u0430",
                          "type": "TRAP",
                          "key": "alive",
                          "delay": "0",
                          "value_type": "FLOAT",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ],
                          "triggers": [
                              {
                                  "expression": "{last()}=0",
                                  "name": "\u041a\u043b\u0438\u0435\u043d\u0442 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d",
                                  "opdata": "xxxxx",
                                  "priority": "HIGH"
                              }
                          ]
                      },
                      {
                          "name": "\u0421\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435 \u043f\u043e\u0440\u0442\u0430 m1",
                          "type": "TRAP",
                          "key": "alive[m1]",
                          "delay": "0",
                          "value_type": "FLOAT",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ]
                      },
                      {
                          "name": "\u0421\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435 \u043f\u043e\u0440\u0442\u0430 m2",
                          "type": "TRAP",
                          "key": "alive[m2]",
                          "delay": "0",
                          "value_type": "FLOAT",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ]
                      },
                      {
                          "name": "m1 CSQ",
                          "type": "TRAP",
                          "key": "csq[m1]",
                          "delay": "0",
                          "value_type": "FLOAT",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ]
                      },
                      {
                          "name": "m2 CSQ",
                          "type": "TRAP",
                          "key": "csq[m2]",
                          "delay": "0",
                          "value_type": "FLOAT",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ]
                      },
                      {
                          "name": "\u0410\u043f\u043f\u0430\u0440\u0430\u0442\u043d\u0430\u044f \u043a\u043e\u043d\u0444\u0438\u0433\u0443\u0440\u0430\u0446\u0438\u044f",
                          "type": "TRAP",
                          "key": "hw.info",
                          "delay": "0",
                          "trends": "0",
                          "value_type": "TEXT",
                          "inventory_link": "HARDWARE_FULL"
                      },
                      {
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
                          "name": "m1 Oper",
                          "type": "TRAP",
                          "key": "oper[m1]",
                          "delay": "0",
                          "trends": "0",
                          "value_type": "TEXT",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ]
                      },
                      {
                          "name": "m2 Oper",
                          "type": "TRAP",
                          "key": "oper[m2]",
                          "delay": "0",
                          "trends": "0",
                          "value_type": "TEXT",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ]
                      },
                      {
                          "name": "\u0412\u0435\u0440\u0441\u0438\u044f \u041f\u041e",
                          "type": "TRAP",
                          "key": "sw.version",
                          "delay": "0",
                          "trends": "0",
                          "value_type": "TEXT",
                          "inventory_link": "SOFTWARE",
                          "applications": [
                              {
                                  "name": "\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435"
                              }
                          ]
                      }
                  ],
                  "dashboards": [
                      {
                          "name": "\u0421\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435",
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
          ],
          "triggers": [
              {
                  "expression": "{Bogatka_client:csq[m1].avg(30d)}<12 and\n{Bogatka_client:oper[m1].strlen()}>=0",
                  "name": "\u041d\u0438\u0437\u043a\u0438\u0439 \u0443\u0440\u043e\u0432\u0435\u043d\u044c \u0441\u0438\u0433\u043d\u0430\u043b\u0430 m1  ({ITEM.VALUE2})",
                  "priority": "WARNING"
              },
              {
                  "expression": "{Bogatka_client:csq[m2].avg(30d)}<12 and\n{Bogatka_client:oper[m2].strlen()}>=0",
                  "name": "\u041d\u0438\u0437\u043a\u0438\u0439 \u0443\u0440\u043e\u0432\u0435\u043d\u044c \u0441\u0438\u0433\u043d\u0430\u043b\u0430 m2  ({ITEM.VALUE2})",
                  "priority": "WARNING"
              },
              {
                  "expression": "{Bogatka_client:alive[m1].last()}=0 and\n{Bogatka_client:oper[m1].strlen()}>=0",
                  "name": "\u041f\u043e\u0440\u0442 m1 \u043d\u0435 \u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d ({ITEM.VALUE2})",
                  "priority": "WARNING"
              },
              {
                  "expression": "{Bogatka_client:alive[m2].last()}=0 and\n{Bogatka_client:oper[m2].strlen()}>0",
                  "name": "\u041f\u043e\u0440\u0442 m2 \u043d\u0435 \u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d ({ITEM.VALUE2})",
                  "priority": "WARNING"
              }
          ],
          "graphs": [
              {
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
