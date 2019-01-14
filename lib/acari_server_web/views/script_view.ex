defmodule AcariServerWeb.ScriptView do
  use AcariServerWeb, :view

  def dfn_placeholder() do
    """
    {   "var": {},
        "const": {},
        "test": {}
    }
    """
  end
end
