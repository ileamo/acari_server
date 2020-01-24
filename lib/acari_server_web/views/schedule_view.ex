defmodule AcariServerWeb.ScheduleView do
  use AcariServerWeb, :view

  def template_name(sched) do
    case sched.template do
      nil -> "Не задано"
      tpl -> tpl.name
    end
  end

  def class_name(sched) do
    case sched.script do
      nil -> "Все"
      scr -> scr.name
    end
  end

  def group_name(sched) do
    case sched.group do
      nil -> "Все"
      grp -> grp.name
    end
  end


end
