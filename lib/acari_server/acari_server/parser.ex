defmodule AcariServer.Parser do
  import NimbleParsec

  ws = ascii_char([?\s, ?\t, ?\v, ?\f])
  nl = ascii_char([?\n, ?\r])

  digit = ascii_char([?0..?9])
  letter = ascii_char([?a..?z, ?A..?Z])

  key =
    choice([letter, ascii_char([?_])])
    |> repeat(choice([digit, letter, ascii_char([?_, ?-])]))
    |> wrap()

  value =
    times(
      ascii_char(
        not: ?,,
        not: ?;,
        not: ?=,
        not: ?\n,
        not: ?\r,
        not: ?\s,
        not: ?\t,
        not: ?\v,
        not: ?\f
      ),
      min: 1
    )
    |> wrap()

  kv =
    ignore(repeat(ws))
    |> times(key, 1)
    |> ignore(repeat(ws))
    |> ignore(ascii_char([?=]))
    |> ignore(repeat(ws))
    |> times(value, 1)
    |> ignore(repeat(ws))
    |> wrap()

  line =
    choice([
      times(kv, 1)
      |> repeat(
        ignore(ascii_char([?,, ?;]))
        |> times(kv, 1)
      )
      |> wrap(),
      ignore(repeat(ws))
    ])

  list =
    times(line, 1)
    |> repeat(
      ignore(times(nl, 1))
      |> times(line, 1)
    )

  defparsec(:client_list, list |> eos())
end
